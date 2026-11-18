-- =====================================================================
-- 02_dim_date.sql : fill dim_date with every calendar day 2021–2027
-- Safe to re-run: ON CONFLICT DO NOTHING skips dates that already exist.
-- =====================================================================

INSERT INTO dim_date (trade_date, year, quarter, month, month_name,
                      week_of_year, day_of_week, day_name, is_weekend)
SELECT
    d::date,
    EXTRACT(YEAR    FROM d),
    EXTRACT(QUARTER FROM d),
    EXTRACT(MONTH   FROM d),
    TRIM(TO_CHAR(d, 'Month')),
    EXTRACT(WEEK    FROM d),
    EXTRACT(ISODOW  FROM d),
    TRIM(TO_CHAR(d, 'Day')),
    EXTRACT(ISODOW  FROM d) IN (6, 7)
FROM generate_series('2021-01-01'::date, '2027-12-31'::date, interval '1 day') AS d
ON CONFLICT (trade_date) DO NOTHING;