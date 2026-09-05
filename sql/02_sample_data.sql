-- ============================================================================
-- BookMyShow Case Study - Sample data
-- Mirrors the reference screenshot: PVR: Nexus theatre, Wed 25 Jan (today +2),
-- 4 movies each with one or more language/format shows.
-- ============================================================================

USE bookmyshow;

-- 1. city
INSERT INTO city (city_name, state_name) VALUES
    ('Hyderabad', 'Telangana'),
    ('Bengaluru', 'Karnataka');

-- 2. theatre
INSERT INTO theatre (theatre_name, city_id, address) VALUES
    ('PVR: Nexus', 1, 'Nexus Mall, Punjagutta, Hyderabad'),
    ('INOX: GVK One', 1, 'GVK One Mall, Banjara Hills, Hyderabad');

-- 3. screen
INSERT INTO screen (theatre_id, screen_name, total_seats) VALUES
    (1, 'Audi 1', 120),
    (1, 'Audi 2 (4K Dolby)', 90),
    (1, 'Audi 3', 100);

-- 4. seat_category
INSERT INTO seat_category (category_name) VALUES
    ('Normal'), ('Premium'), ('Recliner');

-- 5. seat (small sample for Audi 1 only, enough to demo booking_seat)
INSERT INTO seat (screen_id, seat_row, seat_number, category_id) VALUES
    (1, 'A', 1, 1), (1, 'A', 2, 1), (1, 'A', 3, 1),
    (1, 'F', 1, 2), (1, 'F', 2, 2),
    (1, 'J', 1, 3), (1, 'J', 2, 3);

-- 6. language
INSERT INTO language (language_name) VALUES
    ('Telugu'), ('Hindi'), ('English');

-- 7. movie_format
INSERT INTO movie_format (format_name) VALUES
    ('2D'), ('3D'), ('4K Dolby Atmos');

-- 8. movie
INSERT INTO movie (title, certificate, duration_minutes, genre, release_date) VALUES
    ('Dasara',                      'UA', 156, 'Drama',   '2023-03-30'),
    ('Kisi Ka Bhai Kisi Ki Jaan',   'UA', 155, 'Action',  '2023-04-21'),
    ('Tu Jhoothi Main Makkaar',     'UA', 164, 'Romance', '2023-03-08'),
    ('Avatar: The Way of Water',    'UA', 192, 'Sci-Fi',  '2022-12-16');

-- 9. show  (all on 2026-01-25 at PVR: Nexus -> theatre_id 1)
-- Dasara (Telugu, 2D, Audi 3)
INSERT INTO `show` (movie_id, screen_id, language_id, format_id, show_date, start_time, end_time) VALUES
    (1, 3, 1, 1, '2026-01-25', '12:15:00', '14:55:00');

-- Kisi Ka Bhai Kisi Ki Jaan (Hindi, 2D, Audi 1) -- 4 shows (1:00 PM, 4:10 PM, 7:20 PM, 10:30 PM)
INSERT INTO `show` (movie_id, screen_id, language_id, format_id, show_date, start_time, end_time) VALUES
    (2, 1, 2, 1, '2026-01-25', '13:00:00', '15:35:00'),
    (2, 1, 2, 1, '2026-01-25', '16:10:00', '18:45:00'),
    (2, 1, 2, 1, '2026-01-25', '19:20:00', '21:55:00'),
    (2, 1, 2, 1, '2026-01-25', '22:30:00', '23:59:00');

-- Tu Jhoothi Main Makkaar (Hindi, 2D, Audi 2 Dolby) -- 1:15 PM
INSERT INTO `show` (movie_id, screen_id, language_id, format_id, show_date, start_time, end_time) VALUES
    (3, 2, 2, 3, '2026-01-25', '13:15:00', '16:00:00');

-- Avatar: The Way of Water (English, 3D, Audi 2 Dolby) -- 1:20 PM
INSERT INTO `show` (movie_id, screen_id, language_id, format_id, show_date, start_time, end_time) VALUES
    (4, 2, 3, 2, '2026-01-25', '13:20:00', '16:35:00');

-- 10. show_price (only for the first Dasara show, as an example)
INSERT INTO show_price (show_id, category_id, price) VALUES
    (1, 1, 180.00),
    (1, 2, 260.00),
    (1, 3, 450.00);

-- 11. app_user
INSERT INTO app_user (full_name, email, phone) VALUES
    ('Vikash Sharma', 'vikash@example.com', '9000000001'),
    ('Anita Rao',      'anita@example.com', '9000000002');

-- 12. booking (Vikash books 2 Normal seats for the 12:15 Dasara show)
INSERT INTO booking (user_id, show_id, total_amount, booking_status) VALUES
    (1, 1, 360.00, 'CONFIRMED');

-- 13. booking_seat
INSERT INTO booking_seat (booking_id, seat_id, show_id, price_paid) VALUES
    (1, 1, 1, 180.00),
    (1, 2, 1, 180.00);
