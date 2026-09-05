-- ============================================================================
-- BookMyShow Case Study - P1: Schema (MySQL 8.0+)
-- Scenario: theatre -> pick a date (next 7 days) -> list of shows running
--           that day at that theatre, with movie, language/format and timing.
-- ============================================================================

DROP DATABASE IF EXISTS bookmyshow;
CREATE DATABASE bookmyshow;
USE bookmyshow;

-- ----------------------------------------------------------------------------
-- 1. city
-- A theatre is located in exactly one city. Pulled into its own table instead
-- of a free-text column on theatre so city name/state isn't repeated per
-- theatre (removes a transitive dependency, keeps theatre in 3NF/BCNF).
-- ----------------------------------------------------------------------------
CREATE TABLE city (
    city_id     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city_name   VARCHAR(100) NOT NULL,
    state_name  VARCHAR(100) NOT NULL,
    UNIQUE KEY uq_city_state (city_name, state_name)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 2. theatre
-- ----------------------------------------------------------------------------
CREATE TABLE theatre (
    theatre_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    theatre_name  VARCHAR(150) NOT NULL,
    city_id       INT UNSIGNED NOT NULL,
    address       VARCHAR(255) NOT NULL,
    CONSTRAINT fk_theatre_city FOREIGN KEY (city_id) REFERENCES city(city_id),
    UNIQUE KEY uq_theatre_identity (theatre_name, city_id, address)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 3. screen (an "auditorium" inside a theatre; e.g. Audi 1, Screen 3)
-- ----------------------------------------------------------------------------
CREATE TABLE screen (
    screen_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    theatre_id   INT UNSIGNED NOT NULL,
    screen_name  VARCHAR(50) NOT NULL,
    total_seats  SMALLINT UNSIGNED NOT NULL,
    CONSTRAINT fk_screen_theatre FOREIGN KEY (theatre_id) REFERENCES theatre(theatre_id),
    UNIQUE KEY uq_screen_per_theatre (theatre_id, screen_name)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 4. seat_category (Normal / Premium / Recliner ... with no price here -
-- price is show-specific, see show_price, so it doesn't belong on this table)
-- ----------------------------------------------------------------------------
CREATE TABLE seat_category (
    category_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 5. seat (a physical seat that belongs to exactly one screen)
-- ----------------------------------------------------------------------------
CREATE TABLE seat (
    seat_id      INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    screen_id    INT UNSIGNED NOT NULL,
    seat_row     VARCHAR(2) NOT NULL,       -- 'A', 'B', 'AA' ...
    seat_number  SMALLINT UNSIGNED NOT NULL,
    category_id  INT UNSIGNED NOT NULL,
    CONSTRAINT fk_seat_screen FOREIGN KEY (screen_id) REFERENCES screen(screen_id),
    CONSTRAINT fk_seat_category FOREIGN KEY (category_id) REFERENCES seat_category(category_id),
    UNIQUE KEY uq_seat_position (screen_id, seat_row, seat_number)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 6. language
-- ----------------------------------------------------------------------------
CREATE TABLE language (
    language_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    language_name  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 7. movie_format (2D / 3D / 4K Dolby Atmos / IMAX 3D ...)
-- ----------------------------------------------------------------------------
CREATE TABLE movie_format (
    format_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    format_name  VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 8. movie
-- Note: certificate is a small, fixed, closed domain (U/UA/A/S) so it's kept
-- as an ENUM on movie rather than split into its own lookup table -- this is
-- still 3NF/BCNF, an ENUM column is a single atomic value, not a repeating
-- group, so it does not violate 1NF either.
-- ----------------------------------------------------------------------------
CREATE TABLE movie (
    movie_id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title             VARCHAR(200) NOT NULL,
    certificate       ENUM('U','UA','A','S') NOT NULL,
    duration_minutes  SMALLINT UNSIGNED NOT NULL,
    genre             VARCHAR(100) NOT NULL,
    release_date      DATE NOT NULL,
    UNIQUE KEY uq_movie_identity (title, release_date)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 9. show
-- One row = one "3:00 PM, 2D, Telugu, Screen 1" slot for a movie at a theatre.
-- end_time is stored (not derived purely from movie.duration_minutes) because
-- the real gap between start_time and end_time also depends on trailers/
-- cleaning buffer, which is a per-show operational decision, not something
-- solely determined by movie_id -- so storing it does not create a transitive
-- dependency back on the movie and does not break 3NF/BCNF.
-- ----------------------------------------------------------------------------
CREATE TABLE `show` (
    show_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    movie_id     INT UNSIGNED NOT NULL,
    screen_id    INT UNSIGNED NOT NULL,
    language_id  INT UNSIGNED NOT NULL,
    format_id    INT UNSIGNED NOT NULL,
    show_date    DATE NOT NULL,
    start_time   TIME NOT NULL,
    end_time     TIME NOT NULL,
    CONSTRAINT fk_show_movie    FOREIGN KEY (movie_id)    REFERENCES movie(movie_id),
    CONSTRAINT fk_show_screen   FOREIGN KEY (screen_id)   REFERENCES screen(screen_id),
    CONSTRAINT fk_show_language FOREIGN KEY (language_id) REFERENCES language(language_id),
    CONSTRAINT fk_show_format   FOREIGN KEY (format_id)   REFERENCES movie_format(format_id),
    -- a screen can only run one show at a time
    UNIQUE KEY uq_screen_slot (screen_id, show_date, start_time),
    KEY idx_show_lookup (screen_id, show_date)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 10. show_price
-- Price of a seat category is specific to a show (matinee vs prime-time
-- pricing differs), so it cannot live on seat_category or show alone --
-- it depends on the *combination* of show_id + category_id (composite key),
-- which is exactly what BCNF requires here: every non-key attribute (price)
-- depends on the whole key and nothing but the whole key.
-- ----------------------------------------------------------------------------
CREATE TABLE show_price (
    show_id      BIGINT UNSIGNED NOT NULL,
    category_id  INT UNSIGNED NOT NULL,
    price        DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (show_id, category_id),
    CONSTRAINT fk_price_show     FOREIGN KEY (show_id)     REFERENCES `show`(show_id),
    CONSTRAINT fk_price_category FOREIGN KEY (category_id) REFERENCES seat_category(category_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 11. app_user (named app_user, not `user`, to avoid the MySQL reserved word)
-- ----------------------------------------------------------------------------
CREATE TABLE app_user (
    user_id    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name  VARCHAR(150) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    phone      VARCHAR(15)  NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 12. booking
-- ----------------------------------------------------------------------------
CREATE TABLE booking (
    booking_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         INT UNSIGNED NOT NULL,
    show_id         BIGINT UNSIGNED NOT NULL,
    booking_time    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount    DECIMAL(10,2) NOT NULL,
    booking_status  ENUM('PENDING','CONFIRMED','CANCELLED') NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) REFERENCES app_user(user_id),
    CONSTRAINT fk_booking_show FOREIGN KEY (show_id) REFERENCES `show`(show_id)
) ENGINE=InnoDB;

-- ----------------------------------------------------------------------------
-- 13. booking_seat
-- show_id is duplicated here from booking (a deliberate, documented
-- denormalization) purely so the database itself can enforce the business
-- rule "the same physical seat cannot be sold twice for the same show" via
-- uq_seat_per_show. Without it, that constraint could only be checked in
-- application code because seat + show only becomes derivable by joining
-- through booking. This does not violate BCNF: show_id is still fully
-- determined by booking_id (booking_id -> show_id holds), it's stored
-- redundantly on purpose to back a UNIQUE constraint MySQL can enforce.
-- ----------------------------------------------------------------------------
CREATE TABLE booking_seat (
    booking_id  BIGINT UNSIGNED NOT NULL,
    seat_id     INT UNSIGNED NOT NULL,
    show_id     BIGINT UNSIGNED NOT NULL,
    price_paid  DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (booking_id, seat_id),
    CONSTRAINT fk_bs_booking FOREIGN KEY (booking_id) REFERENCES booking(booking_id),
    CONSTRAINT fk_bs_seat    FOREIGN KEY (seat_id)    REFERENCES seat(seat_id),
    CONSTRAINT fk_bs_show    FOREIGN KEY (show_id)    REFERENCES `show`(show_id),
    UNIQUE KEY uq_seat_per_show (show_id, seat_id)
) ENGINE=InnoDB;
