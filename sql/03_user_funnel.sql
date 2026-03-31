-- =====================================================
-- 03_user_funnel.sql
-- Purpose: sequence-based funnel analysis at user level
-- Database: PostgreSQL
-- Table: ecommerce_events
-- =====================================================


-- 1. First event timestamp per user for each funnel stage
WITH user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT *
FROM user_event_times
LIMIT 20;


-- 2. User-level sequence flags
WITH user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    user_id,
    CASE 
        WHEN first_view_time IS NOT NULL THEN 1 ELSE 0 
    END AS viewed,
    CASE 
        WHEN first_view_time IS NOT NULL
         AND first_cart_time IS NOT NULL
         AND first_view_time < first_cart_time
        THEN 1 ELSE 0 
    END AS valid_cart_after_view,
    CASE
        WHEN first_view_time IS NOT NULL
         AND first_cart_time IS NOT NULL
         AND first_purchase_time IS NOT NULL
         AND first_view_time < first_cart_time
         AND first_cart_time < first_purchase_time
        THEN 1 ELSE 0
    END AS valid_purchase_after_cart
FROM user_event_times
LIMIT 20;


-- 3. Sequence-based funnel counts
WITH user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    COUNT(CASE WHEN first_view_time IS NOT NULL THEN 1 END) AS view_users,
    COUNT(CASE 
        WHEN first_view_time IS NOT NULL
         AND first_cart_time IS NOT NULL
         AND first_view_time < first_cart_time
        THEN 1 END) AS view_to_cart_users,
    COUNT(CASE
        WHEN first_view_time IS NOT NULL
         AND first_cart_time IS NOT NULL
         AND first_purchase_time IS NOT NULL
         AND first_view_time < first_cart_time
         AND first_cart_time < first_purchase_time
        THEN 1 END) AS full_funnel_users
FROM user_event_times;


-- 4. Sequence-based funnel conversion percentages
WITH user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
),
sequence_counts AS (
    SELECT
        COUNT(CASE WHEN first_view_time IS NOT NULL THEN 1 END) AS view_users,
        COUNT(CASE 
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_view_time < first_cart_time
            THEN 1 END) AS view_to_cart_users,
        COUNT(CASE
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_purchase_time IS NOT NULL
             AND first_view_time < first_cart_time
             AND first_cart_time < first_purchase_time
            THEN 1 END) AS full_funnel_users
    FROM user_event_times
)
SELECT
    view_users,
    view_to_cart_users,
    full_funnel_users,
    ROUND((view_to_cart_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((full_funnel_users * 100.0 / NULLIF(view_to_cart_users, 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((full_funnel_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS overall_conversion_pct
FROM sequence_counts;


-- 5. Compare loose funnel vs strict sequence funnel
WITH loose_funnel AS (
    SELECT
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS loose_view_users,
        COUNT(DISTINCT CASE WHEN event_type = 'cart' THEN user_id END) AS loose_cart_users,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS loose_purchase_users
    FROM ecommerce_events
),
user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
),
strict_funnel AS (
    SELECT
        COUNT(CASE WHEN first_view_time IS NOT NULL THEN 1 END) AS strict_view_users,
        COUNT(CASE 
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_view_time < first_cart_time
            THEN 1 END) AS strict_cart_users,
        COUNT(CASE
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_purchase_time IS NOT NULL
             AND first_view_time < first_cart_time
             AND first_cart_time < first_purchase_time
            THEN 1 END) AS strict_purchase_users
    FROM user_event_times
)
SELECT
    loose_view_users,
    loose_cart_users,
    loose_purchase_users,
    strict_view_users,
    strict_cart_users,
    strict_purchase_users
FROM loose_funnel, strict_funnel;


-- 6. Final summary query with drop-off counts
WITH user_event_times AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
),
sequence_counts AS (
    SELECT
        COUNT(CASE WHEN first_view_time IS NOT NULL THEN 1 END) AS view_users,
        COUNT(CASE 
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_view_time < first_cart_time
            THEN 1 END) AS cart_users,
        COUNT(CASE
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_purchase_time IS NOT NULL
             AND first_view_time < first_cart_time
             AND first_cart_time < first_purchase_time
            THEN 1 END) AS purchase_users
    FROM user_event_times
)
SELECT
    view_users,
    cart_users,
    purchase_users,
    (view_users - cart_users) AS dropped_before_cart,
    (cart_users - purchase_users) AS dropped_before_purchase,
    ROUND((cart_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((purchase_users * 100.0 / NULLIF(cart_users, 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((purchase_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS overall_conversion_pct
FROM sequence_counts;



-- =====================================================
-- 📊 Sequence-Based Funnel Analysis Summary
-- =====================================================

-- Strict Funnel Counts:
-- View Users              : 3.69M
-- Valid View → Cart Users : 823K
-- Full Funnel Users       : 361K

-- Strict Conversion Rates:
-- View → Cart             : 22.28%
-- Cart → Purchase         : 43.86%
-- Overall Conversion      : 9.77%

-- Drop-Off Counts:
-- Dropped Before Cart     : 2.87M
-- Dropped Before Purchase : 462K

-- Comparison with Loose Funnel:
-- Loose Purchase Users    : 441,638
-- Strict Purchase Users   : 361,107
-- Difference              : 80,531 users

-- Insights:
-- 1. Enforcing event sequence reduces purchase-stage users noticeably,
--    showing that the loose funnel overstates true conversion

-- 2. The largest drop-off still occurs before cart, confirming that
--    early-stage user intent is the main bottleneck in the funnel

-- 3. Cart-to-purchase conversion declines from the loose funnel to the
--    strict funnel, indicating that event order matters significantly
--    for accurate conversion measurement

-- 4. Sequence-based analysis provides a more reliable view of actual
--    user progression and should be preferred for funnel evaluation

-- Next Step:
-- Segment funnel behavior by price band to understand whether low,
-- medium, or high-priced users convert differently