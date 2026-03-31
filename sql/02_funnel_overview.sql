-- =====================================================
-- 02_funnel_overview.sql
-- Purpose: analyze funnel stages at user level
-- =====================================================

-- Event distribution (context only)
SELECT
    event_type,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY event_type
ORDER BY total_events DESC;

-- Unique users at each funnel stage
SELECT
    event_type,
    COUNT(DISTINCT user_id) AS unique_users
FROM ecommerce_events
GROUP BY event_type
ORDER BY unique_users DESC;


-- Funnel stage counts (user-level)
WITH stage_counts AS (
    SELECT
        event_type,
        COUNT(DISTINCT user_id) AS users
    FROM ecommerce_events
    GROUP BY event_type
)
SELECT *
FROM stage_counts
ORDER BY users DESC;

-- Funnel conversion rates
WITH stage_counts AS (
    SELECT
        event_type,
        COUNT(DISTINCT user_id) AS users
    FROM ecommerce_events
    GROUP BY event_type
)
SELECT
    MAX(CASE WHEN event_type = 'view' THEN users END) AS view_users,
    MAX(CASE WHEN event_type = 'cart' THEN users END) AS cart_users,
    MAX(CASE WHEN event_type = 'purchase' THEN users END) AS purchase_users
FROM stage_counts;


-- Funnel conversion percentages
WITH stage_counts AS (
    SELECT
        event_type,
        COUNT(DISTINCT user_id) AS users
    FROM ecommerce_events
    GROUP BY event_type
),
funnel AS (
    SELECT
        MAX(CASE WHEN event_type = 'view' THEN users END) AS view_users,
        MAX(CASE WHEN event_type = 'cart' THEN users END) AS cart_users,
        MAX(CASE WHEN event_type = 'purchase' THEN users END) AS purchase_users
    FROM stage_counts
)
SELECT
    view_users,
    cart_users,
    purchase_users,
    ROUND((cart_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((purchase_users * 100.0 / NULLIF(cart_users, 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((purchase_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS overall_conversion_pct
FROM funnel;


-- =====================================================
-- 📊 Funnel Analysis Summary (User-Level)
-- =====================================================

-- Key Metrics:
-- View Users       : 3.69M
-- Cart Users       : 826K
-- Purchase Users   : 441K

-- Conversion Rates:
-- View → Cart      : 22.36%
-- Cart → Purchase  : 53.45%
-- Overall          : 11.95%

-- Insights:
-- 1. Significant drop-off occurs between the view and cart stages,
--    indicating that most users browse but do not show purchase intent

-- 2. Once users add items to cart, conversion is strong (>50%),
--    suggesting that users with intent are highly likely to complete purchase

-- 3. Overall conversion (~12%) is reasonable for an e-commerce funnel,
--    but improvement opportunities exist at the top of the funnel

-- 4. This funnel is based on user-level aggregation and does NOT enforce
--    event sequence, meaning users may appear in later stages without
--    strictly following view → cart → purchase order

-- Next Step:
-- Sequence-based funnel analysis will be performed to validate true
-- user progression across stages
