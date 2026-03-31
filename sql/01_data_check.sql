-- =====================================================
-- 01_data_check.sql
-- Purpose: deeper data validation before funnel analysis
-- Database: PostgreSQL
-- Table: ecommerce_events
-- =====================================================


-- 1. Count unique users and unique sessions
SELECT 
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(DISTINCT user_session) AS unique_sessions
FROM ecommerce_events;


-- 2. Check distinct event types
SELECT DISTINCT event_type
FROM ecommerce_events
ORDER BY event_type;


-- 3. Count records with missing key fields
SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL) AS missing_user_id,
    COUNT(*) FILTER (WHERE user_session IS NULL) AS missing_user_session,
    COUNT(*) FILTER (WHERE event_time IS NULL) AS missing_event_time,
    COUNT(*) FILTER (WHERE event_type IS NULL) AS missing_event_type,
    COUNT(*) FILTER (WHERE price IS NULL) AS missing_price
FROM ecommerce_events;


-- 4. Check missing values in descriptive fields
SELECT
    COUNT(*) FILTER (WHERE category_code IS NULL) AS missing_category_code,
    COUNT(*) FILTER (WHERE brand IS NULL) AS missing_brand
FROM ecommerce_events;


-- 5. Check price distribution basics
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ecommerce_events;


-- 6. Check for invalid or suspicious price values
SELECT
    COUNT(*) AS zero_or_negative_price_rows
FROM ecommerce_events
WHERE price <= 0;


-- 7. Count events per user (top active users)
SELECT
    user_id,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY user_id
ORDER BY total_events DESC
LIMIT 10;


-- 8. Count events per session (top active sessions)
SELECT
    user_session,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY user_session
ORDER BY total_events DESC
LIMIT 10;


-- 9. Check whether same user has multiple sessions
SELECT
    user_id,
    COUNT(DISTINCT user_session) AS session_count
FROM ecommerce_events
GROUP BY user_id
ORDER BY session_count DESC
LIMIT 10;


-- 10. Exact duplicate row check
SELECT COUNT(*) AS duplicate_rows
FROM (
    SELECT
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session,
        COUNT(*) AS row_count
    FROM ecommerce_events
    GROUP BY
        event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_id,
        user_session
    HAVING COUNT(*) > 1
) dup;


-- 11. Event distribution by event type
SELECT
    event_type,
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS unique_users,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS event_pct
FROM ecommerce_events
GROUP BY event_type
ORDER BY total_events DESC;


/*
📊 Findings from 01_data_check.sql
Total dataset contains ~66M+ events, 3.69M unique users, and 13.7M sessions, indicating a large-scale behavioral dataset suitable for funnel analysis
Event types are clean and limited to view, cart, and purchase, confirming no preprocessing is required for funnel stages
Missing values in critical fields (user_id, event_time, event_type, price) are negligible, ensuring reliability of core analysis
However, user_session has 10 missing records, which is minimal and unlikely to impact overall results
Significant missing values observed in descriptive attributes:
category_code → ~21.9M missing
brand → ~9.2M missing
→ This limits the reliability of category-level and brand-level analysis
Price distribution shows:
Average price ≈ 292
Maximum price ≈ 2574
Presence of 188K zero-priced records, indicating potential non-purchase events or tracking inconsistencies
User activity is highly skewed:
Top users generate 20K+ events
Top users have 20K+ sessions
→ Suggests presence of heavy users or abnormal activity (possibly bots or repeated interactions)
Session activity is also skewed, with some sessions containing 4000+ events, indicating non-uniform user behavior
Dataset contains 57,553 duplicate records, which is relatively small compared to total volume and acceptable for analysis
Event distribution shows strong funnel drop-off:
View: 63.5M events
Cart: 3.0M events
Purchase: 916K events
→ Indicates significant user drop-off across funnel stages
*/