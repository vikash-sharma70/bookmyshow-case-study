# BookMyShow Problem Solving Case

Scenario modeled: for a chosen theatre, the user picks one of the next 7
dates, and sees every show running that day at that theatre, grouped by
movie, along with each show's language/format and timing (see reference
screenshot).

All SQL is written for and verified against **MySQL 8.0** (`sql/` folder in
this repo). Runnable, unmodified, in order:

```
mysql -u root -p < sql/01_schema.sql
mysql -u root -p < sql/02_sample_data.sql
mysql -u root -p < sql/03_p2_query.sql
```

---

## P1 — Entities, attributes, table structures

### Entity list

| # | Entity | What it represents |
|---|--------|---------------------|
| 1 | `city` | A city that has theatres |
| 2 | `theatre` | A cinema chain's branch (e.g. "PVR: Nexus") in a city |
| 3 | `screen` | One auditorium inside a theatre (e.g. "Audi 2") |
| 4 | `seat_category` | A seating tier: Normal / Premium / Recliner |
| 5 | `seat` | A physical seat, belongs to one screen |
| 6 | `language` | Spoken language a show is presented in |
| 7 | `movie_format` | Presentation format: 2D / 3D / 4K Dolby Atmos ... |
| 8 | `movie` | A film, independent of where/when/how it is screened |
| 9 | `show` | One screening: a movie, on a screen, in a language+format, at a date+time |
| 10 | `show_price` | Ticket price per seat category, for a specific show |
| 11 | `app_user` | A customer of the platform |
| 12 | `booking` | One ticket purchase transaction |
| 13 | `booking_seat` | The specific seats covered by a booking |

### Why movie, language, format and screen are separate entities

Looking at the reference screenshot: **the same movie** ("Kisi Ka Bhai Kisi
Ki Jaan") appears once but runs **4 times** in a day, and different movies
run in different languages/formats on different screens. That means
language and format are properties of a *show* (a specific screening slot),
**not** of the movie itself — a movie can simultaneously have a Telugu 2D
show and a Hindi 4K Dolby show. Modeling language/format as columns on
`movie` would have made a movie's row lie about which version is actually
playing at 7:20 PM. This is exactly what 2NF/3NF is protecting against:
`language_id` and `format_id` depend on the whole show slot, not on
`movie_id` alone.

### Table structures (ER summary)

```
city (1) ──< theatre (1) ──< screen (1) ──< seat >── (1) seat_category
                                   │
                                   └──< show >── (1) movie
                                          │  │
                              language ──(1) └── (1) movie_format
                                          │
                                          └──< show_price >── (1) seat_category
                                          │
                                          └──< booking >── (1) app_user
                                                  │
                                                  └──< booking_seat >── (1) seat
```

Full `CREATE TABLE` statements: [`sql/01_schema.sql`](sql/01_schema.sql).
Sample rows for every table: [`sql/02_sample_data.sql`](sql/02_sample_data.sql).

### Attributes per table (with sample rows)

**`city`**
| city_id | city_name | state_name |
|---|---|---|
| 1 | Hyderabad | Telangana |
| 2 | Bengaluru | Karnataka |

**`theatre`**
| theatre_id | theatre_name | city_id | address |
|---|---|---|---|
| 1 | PVR: Nexus | 1 | Nexus Mall, Punjagutta, Hyderabad |
| 2 | INOX: GVK One | 1 | GVK One Mall, Banjara Hills, Hyderabad |

**`screen`**
| screen_id | theatre_id | screen_name | total_seats |
|---|---|---|---|
| 1 | 1 | Audi 1 | 120 |
| 2 | 1 | Audi 2 (4K Dolby) | 90 |
| 3 | 1 | Audi 3 | 100 |

**`seat_category`**
| category_id | category_name |
|---|---|
| 1 | Normal |
| 2 | Premium |
| 3 | Recliner |

**`seat`** (sample for Audi 1)
| seat_id | screen_id | seat_row | seat_number | category_id |
|---|---|---|---|---|
| 1 | 1 | A | 1 | 1 |
| 4 | 1 | F | 1 | 2 |
| 6 | 1 | J | 1 | 3 |

**`language`**
| language_id | language_name |
|---|---|
| 1 | Telugu |
| 2 | Hindi |
| 3 | English |

**`movie_format`**
| format_id | format_name |
|---|---|
| 1 | 2D |
| 2 | 3D |
| 3 | 4K Dolby Atmos |

**`movie`**
| movie_id | title | certificate | duration_minutes | genre | release_date |
|---|---|---|---|---|---|
| 1 | Dasara | UA | 156 | Drama | 2023-03-30 |
| 2 | Kisi Ka Bhai Kisi Ki Jaan | UA | 155 | Action | 2023-04-21 |
| 3 | Tu Jhoothi Main Makkaar | UA | 164 | Romance | 2023-03-08 |
| 4 | Avatar: The Way of Water | UA | 192 | Sci-Fi | 2022-12-16 |

**`show`**
| show_id | movie_id | screen_id | language_id | format_id | show_date | start_time | end_time |
|---|---|---|---|---|---|---|---|
| 1 | 1 | 3 | 1 | 1 | 2026-01-25 | 12:15:00 | 14:55:00 |
| 2 | 2 | 1 | 2 | 1 | 2026-01-25 | 13:00:00 | 15:35:00 |
| 3 | 2 | 1 | 2 | 1 | 2026-01-25 | 16:10:00 | 18:45:00 |
| 4 | 2 | 1 | 2 | 1 | 2026-01-25 | 19:20:00 | 21:55:00 |
| 5 | 2 | 1 | 2 | 1 | 2026-01-25 | 22:30:00 | 23:59:00 |
| 6 | 3 | 2 | 2 | 3 | 2026-01-25 | 13:15:00 | 16:00:00 |
| 7 | 4 | 2 | 3 | 2 | 2026-01-25 | 13:20:00 | 16:35:00 |

**`show_price`**
| show_id | category_id | price |
|---|---|---|
| 1 | 1 | 180.00 |
| 1 | 2 | 260.00 |
| 1 | 3 | 450.00 |

**`app_user`**
| user_id | full_name | email | phone |
|---|---|---|---|
| 1 | Vikash Sharma | vikash@example.com | 9000000001 |
| 2 | Anita Rao | anita@example.com | 9000000002 |

**`booking`**
| booking_id | user_id | show_id | booking_time | total_amount | booking_status |
|---|---|---|---|---|---|
| 1 | 1 | 1 | 2026-01-25 10:02:11 | 360.00 | CONFIRMED |

**`booking_seat`**
| booking_id | seat_id | show_id | price_paid |
|---|---|---|---|
| 1 | 1 | 1 | 180.00 |
| 1 | 2 | 1 | 180.00 |

---

### Normalization walkthrough (1NF → BCNF)

**1NF — every column holds a single atomic value, no repeating groups.**
No table stores a list/CSV in a cell (e.g. a movie's languages are *not*
stored as `"Telugu, Hindi, English"` in one column — each show gets its own
row referencing one `language_id`). Every table also has a primary key.
✅ All 13 tables satisfy 1NF.

**2NF — 1NF + every non-key attribute depends on the *whole* primary key
(only matters where the PK is composite).**
Composite-key tables here are `show_price` (`show_id, category_id`) and
`booking_seat` (`booking_id, seat_id`). In `show_price`, `price` needs both
`show_id` (different shows price differently) and `category_id` (different
tiers price differently) — it isn't determined by either half alone, so
there's no partial dependency. Same reasoning for `price_paid` in
`booking_seat`. ✅ 2NF holds.

**3NF — 2NF + no transitive dependency (non-key attribute depending on
another non-key attribute instead of the key).**
This is the one the naive/flat design would fail: if `screen_name`,
`theatre_name`, or `city_name` were stored directly on `show`, then e.g.
`city_name` would really depend on `theatre_id` (a non-key attribute of
`show`), not on `show_id` itself — a transitive dependency. Splitting into
`city → theatre → screen → show` removes this: every non-key attribute in
`show` (movie_id, screen_id, language_id, format_id, show_date, start_time,
end_time) depends directly on `show_id` only. ✅ 3NF holds.

**BCNF — for every functional dependency `X → Y`, `X` must be a candidate
key.**
Checked table by table:
- `show`: FD `show_id → {movie_id, screen_id, language_id, format_id,
  show_date, start_time, end_time}`; also `{screen_id, show_date,
  start_time} → show_id` (enforced by `uq_screen_slot`) — both determinants
  are candidate keys. ✅
- `show_price`: only FD is `{show_id, category_id} → price`, and that
  composite is the whole key — no smaller determinant exists. ✅
- `seat`: `{screen_id, seat_row, seat_number} → seat_id` and
  `seat_id → {screen_id, seat_row, seat_number, category_id}` — both are
  candidate keys. ✅
- Every lookup table (`city`, `language`, `movie_format`, `seat_category`)
  has a single non-key attribute functionally dependent only on its own
  surrogate key, trivially satisfying BCNF.

No table has an attribute that determines another attribute without also
being (part of) a candidate key, so the schema is in **BCNF**.

---

## P2 — Shows on a given date at a given theatre

```sql
SELECT
    m.title                                    AS movie_title,
    m.certificate,
    l.language_name,
    f.format_name,
    sc.screen_name,
    s.show_date,
    s.start_time,
    s.end_time
FROM `show` s
JOIN movie        m  ON m.movie_id  = s.movie_id
JOIN screen       sc ON sc.screen_id = s.screen_id
JOIN theatre      t  ON t.theatre_id = sc.theatre_id
JOIN language     l  ON l.language_id = s.language_id
JOIN movie_format f  ON f.format_id  = s.format_id
WHERE t.theatre_id = 1                 -- :theatre_id parameter
  AND s.show_date  = '2026-01-25'      -- :show_date parameter
ORDER BY m.title, s.start_time;
```

Full file: [`sql/03_p2_query.sql`](sql/03_p2_query.sql) (includes a `?`
placeholder version for use from application code as a prepared statement).

**Verified output** (run against a real MySQL 8.0 instance in Docker, using
the sample data above — matches the reference screenshot's listing):

| movie_title | certificate | language_name | format_name | screen_name | show_date | start_time | end_time |
|---|---|---|---|---|---|---|---|
| Avatar: The Way of Water | UA | English | 3D | Audi 2 (4K Dolby) | 2026-01-25 | 13:20:00 | 16:35:00 |
| Dasara | UA | Telugu | 2D | Audi 3 | 2026-01-25 | 12:15:00 | 14:55:00 |
| Kisi Ka Bhai Kisi Ki Jaan | UA | Hindi | 2D | Audi 1 | 2026-01-25 | 13:00:00 | 15:35:00 |
| Kisi Ka Bhai Kisi Ki Jaan | UA | Hindi | 2D | Audi 1 | 2026-01-25 | 16:10:00 | 18:45:00 |
| Kisi Ka Bhai Kisi Ki Jaan | UA | Hindi | 2D | Audi 1 | 2026-01-25 | 19:20:00 | 21:55:00 |
| Kisi Ka Bhai Kisi Ki Jaan | UA | Hindi | 2D | Audi 1 | 2026-01-25 | 22:30:00 | 23:59:00 |
| Tu Jhoothi Main Makkaar | UA | Hindi | 4K Dolby Atmos | Audi 2 (4K Dolby) | 2026-01-25 | 13:15:00 | 16:00:00 |

An index on `show(screen_id, show_date)` backs this query (see
`idx_show_lookup` in the schema) since production traffic filters on
theatre + date on every screen load.

---

## Business-rule constraints enforced by the schema (verified)

- `show.uq_screen_slot (screen_id, show_date, start_time)` — a screen
  cannot host two shows at the same instant. Tested: inserting a
  duplicate slot raises `ERROR 1062 Duplicate entry ... for key
  'show.uq_screen_slot'`.
- `booking_seat.uq_seat_per_show (show_id, seat_id)` — the same physical
  seat cannot be sold twice for the same show. Tested: a second booking for
  an already-booked seat raises `ERROR 1062 Duplicate entry ... for key
  'booking_seat.uq_seat_per_show'`.
