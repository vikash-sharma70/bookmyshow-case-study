-- ============================================================================
-- BookMyShow Case Study - P2
-- List all shows on a given date, at a given theatre, with show timings.
-- (Grouped/ordered the way the app UI shows it: by movie, then by start time.)
-- ============================================================================

USE bookmyshow;

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
WHERE t.theatre_id = 1                 -- :theatre_id parameter, e.g. PVR: Nexus
  AND s.show_date  = '2026-01-25'      -- :show_date parameter
ORDER BY m.title, s.start_time;

-- Same query, parameterised for use from application code (prepared statement):
--
-- SELECT
--     m.title AS movie_title, m.certificate, l.language_name, f.format_name,
--     sc.screen_name, s.show_date, s.start_time, s.end_time
-- FROM `show` s
-- JOIN movie        m  ON m.movie_id  = s.movie_id
-- JOIN screen       sc ON sc.screen_id = s.screen_id
-- JOIN theatre      t  ON t.theatre_id = sc.theatre_id
-- JOIN language     l  ON l.language_id = s.language_id
-- JOIN movie_format f  ON f.format_id  = s.format_id
-- WHERE t.theatre_id = ?
--   AND s.show_date  = ?
-- ORDER BY m.title, s.start_time;
