-- Check total number of rows
SELECT COUNT(*) AS total_rows
FROM ecommerce_events;

-- Preview sample records
SELECT * 
FROM ecommerce_events
LIMIT 5;

-- Check event type distribution
SELECT event_type, COUNT(*) AS event_count
FROM ecommerce_events
GROUP BY event_type
ORDER BY event_count DESC;

-- Check null values in key columns
SELECT
    COUNT(*) FILTER (WHERE event_time IS NULL) AS null_event_time,
    COUNT(*) FILTER (WHERE event_type IS NULL) AS null_event_type,
    COUNT(*) FILTER (WHERE product_id IS NULL) AS null_product_id,
    COUNT(*) FILTER (WHERE category_id IS NULL) AS null_category_id,
    COUNT(*) FILTER (WHERE category_code IS NULL) AS null_category_code,
    COUNT(*) FILTER (WHERE brand IS NULL) AS null_brand,
    COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
    COUNT(*) FILTER (WHERE user_id IS NULL) AS null_user_id,
    COUNT(*) FILTER (WHERE user_session IS NULL) AS null_user_session
FROM ecommerce_events;

-- Check date range of events
SELECT
    MIN(event_time) AS min_time,
    MAX(event_time) AS max_time
FROM ecommerce_events;

-- Check number of unique users
SELECT COUNT(DISTINCT user_id) AS unique_users
FROM ecommerce_events;