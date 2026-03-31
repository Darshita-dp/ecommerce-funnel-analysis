-- =====================================================
-- 05_time_analysis.sql
-- Purpose: analyze user behavior across time (hour & day)
-- Database: PostgreSQL
-- =====================================================


-- 1. Hourly event distribution (all events)
SELECT
    EXTRACT(HOUR FROM event_time) AS event_hour,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY event_hour
ORDER BY event_hour;


-- 2. Hourly event distribution by event type
SELECT
    EXTRACT(HOUR FROM event_time) AS event_hour,
    event_type,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY event_hour, event_type
ORDER BY event_hour, event_type;


-- 3. Hourly purchase activity (focus on conversion)
SELECT
    EXTRACT(HOUR FROM event_time) AS event_hour,
    COUNT(*) AS purchase_events
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY event_hour
ORDER BY event_hour;


-- 4. Day-of-week distribution (all events)
SELECT
    EXTRACT(DOW FROM event_time) AS day_num,
    TO_CHAR(event_time, 'Day') AS day_name,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY day_num, day_name
ORDER BY day_num;


-- 5. Day-of-week distribution by event type
SELECT
    EXTRACT(DOW FROM event_time) AS day_num,
    TO_CHAR(event_time, 'Day') AS day_name,
    event_type,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY day_num, day_name, event_type
ORDER BY day_num, event_type;


-- 6. Purchase distribution by day of week
SELECT
    EXTRACT(DOW FROM event_time) AS day_num,
    TO_CHAR(event_time, 'Day') AS day_name,
    COUNT(*) AS purchase_events
FROM ecommerce_events
WHERE event_type = 'purchase'
GROUP BY day_num, day_name
ORDER BY day_num;


-- 7. Hourly conversion ratio (purchase vs total events)
WITH hourly_events AS (
    SELECT
        EXTRACT(HOUR FROM event_time) AS event_hour,
        COUNT(*) AS total_events,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchase_events
    FROM ecommerce_events
    GROUP BY event_hour
)
SELECT
    event_hour,
    total_events,
    purchase_events,
    ROUND((purchase_events * 100.0 / NULLIF(total_events, 0))::numeric, 2) AS purchase_ratio_pct
FROM hourly_events
ORDER BY event_hour;


-- 8. Weekday conversion ratio
WITH weekday_events AS (
    SELECT
        EXTRACT(DOW FROM event_time) AS day_num,
        TO_CHAR(event_time, 'Day') AS day_name,
        COUNT(*) AS total_events,
        COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchase_events
    FROM ecommerce_events
    GROUP BY day_num, day_name
)
SELECT
    day_num,
    day_name,
    total_events,
    purchase_events,
    ROUND((purchase_events * 100.0 / NULLIF(total_events, 0))::numeric, 2) AS purchase_ratio_pct
FROM weekday_events
ORDER BY day_num;


-- =====================================================
-- 📊 Time-Based Behavior Analysis Summary
-- =====================================================

-- Key Insights:

-- 1. User activity peaks during afternoon hours (2 PM – 5 PM),
--    but purchase activity is stronger in the morning (9 AM – 11 AM)

-- 2. Conversion efficiency is highest in the morning (~2%),
--    indicating that users are more intentional earlier in the day

-- 3. Afternoon and evening periods show high activity but lower
--    conversion rates, suggesting browsing-dominant behavior

-- 4. Weekend activity is highest, especially on Friday and Saturday,
--    but conversion peaks on Sunday

-- 5. Sunday shows the highest purchase conversion (~2.2%),
--    indicating stronger buying intent compared to weekdays

-- 6. Friday has high engagement but relatively low conversion,
--    suggesting exploratory behavior rather than purchase intent

-- Conclusion:
-- User behavior differs significantly across time, with clear
-- separation between browsing-heavy periods and conversion-driven periods

-- Business Implication:
-- Marketing efforts and promotions should be aligned with high-intent
-- time windows (morning hours and Sundays) to maximize conversion