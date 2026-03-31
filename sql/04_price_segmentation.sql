-- =====================================================
-- 04_price_segmentation.sql
-- Purpose: analyze funnel behavior across price segments
-- Database: PostgreSQL
-- Table: ecommerce_events
-- =====================================================


-- 1. Event-level price segment distribution
SELECT
    CASE
        WHEN price < 50 THEN 'Low'
        WHEN price BETWEEN 50 AND 200 THEN 'Medium'
        ELSE 'High'
    END AS price_segment,
    COUNT(*) AS total_events
FROM ecommerce_events
GROUP BY price_segment
ORDER BY total_events DESC;


-- 2. Average price per user with assigned price segment
WITH user_avg_price AS (
    SELECT
        user_id,
        ROUND(AVG(price)::numeric, 2) AS avg_user_price,
        CASE
            WHEN AVG(price) < 50 THEN 'Low'
            WHEN AVG(price) BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END AS price_segment
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT *
FROM user_avg_price
LIMIT 20;


-- 3. User-level funnel flags by price segment (loose funnel)
WITH user_segments AS (
    SELECT
        user_id,
        CASE
            WHEN AVG(price) < 50 THEN 'Low'
            WHEN AVG(price) BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END AS price_segment,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    price_segment,
    COUNT(*) AS total_users,
    SUM(viewed) AS view_users,
    SUM(carted) AS cart_users,
    SUM(purchased) AS purchase_users
FROM user_segments
GROUP BY price_segment
ORDER BY price_segment;


-- 4. Conversion rates by price segment (loose funnel)
WITH user_segments AS (
    SELECT
        user_id,
        CASE
            WHEN AVG(price) < 50 THEN 'Low'
            WHEN AVG(price) BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END AS price_segment,
        MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS viewed,
        MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS carted,
        MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
    FROM ecommerce_events
    GROUP BY user_id
)
SELECT
    price_segment,
    COUNT(*) AS total_users,
    SUM(viewed) AS view_users,
    SUM(carted) AS cart_users,
    SUM(purchased) AS purchase_users,
    ROUND((SUM(carted) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((SUM(purchased) * 100.0 / NULLIF(SUM(carted), 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((SUM(purchased) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS overall_conversion_pct
FROM user_segments
GROUP BY price_segment
ORDER BY
    CASE
        WHEN price_segment = 'Low' THEN 1
        WHEN price_segment = 'Medium' THEN 2
        WHEN price_segment = 'High' THEN 3
    END;


-- 5. Sequence-based conversion by price segment
WITH user_event_times AS (
    SELECT
        user_id,
        AVG(price) AS avg_price,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
),
user_segments AS (
    SELECT
        user_id,
        CASE
            WHEN avg_price < 50 THEN 'Low'
            WHEN avg_price BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END AS price_segment,
        CASE
            WHEN first_view_time IS NOT NULL THEN 1 ELSE 0
        END AS viewed,
        CASE
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_view_time < first_cart_time
            THEN 1 ELSE 0
        END AS valid_cart,
        CASE
            WHEN first_view_time IS NOT NULL
             AND first_cart_time IS NOT NULL
             AND first_purchase_time IS NOT NULL
             AND first_view_time < first_cart_time
             AND first_cart_time < first_purchase_time
            THEN 1 ELSE 0
        END AS valid_purchase
    FROM user_event_times
)
SELECT
    price_segment,
    COUNT(*) AS total_users,
    SUM(viewed) AS view_users,
    SUM(valid_cart) AS cart_users,
    SUM(valid_purchase) AS purchase_users,
    ROUND((SUM(valid_cart) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((SUM(valid_purchase) * 100.0 / NULLIF(SUM(valid_cart), 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((SUM(valid_purchase) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS overall_conversion_pct
FROM user_segments
GROUP BY price_segment
ORDER BY
    CASE
        WHEN price_segment = 'Low' THEN 1
        WHEN price_segment = 'Medium' THEN 2
        WHEN price_segment = 'High' THEN 3
    END;


-- 6. Final comparison table for price segment performance
WITH user_event_times AS (
    SELECT
        user_id,
        AVG(price) AS avg_price,
        MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
        MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
        MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time
    FROM ecommerce_events
    GROUP BY user_id
),
segment_summary AS (
    SELECT
        CASE
            WHEN avg_price < 50 THEN 'Low'
            WHEN avg_price BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END AS price_segment,
        COUNT(*) AS total_users,
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
    GROUP BY
        CASE
            WHEN avg_price < 50 THEN 'Low'
            WHEN avg_price BETWEEN 50 AND 200 THEN 'Medium'
            ELSE 'High'
        END
)
SELECT
    price_segment,
    total_users,
    view_users,
    cart_users,
    purchase_users,
    (view_users - cart_users) AS dropped_before_cart,
    (cart_users - purchase_users) AS dropped_before_purchase,
    ROUND((cart_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((purchase_users * 100.0 / NULLIF(cart_users, 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((purchase_users * 100.0 / NULLIF(view_users, 0))::numeric, 2) AS overall_conversion_pct
FROM segment_summary
ORDER BY
    CASE
        WHEN price_segment = 'Low' THEN 1
        WHEN price_segment = 'Medium' THEN 2
        WHEN price_segment = 'High' THEN 3
    END;




-- =====================================================
-- 📊 Price Segmentation Funnel Analysis Summary
-- =====================================================

-- Key Findings:
-- 1. Low-price users show significantly lower conversion (~4.5%),
--    indicating low purchase intent despite lower price barriers

-- 2. Medium-price segment has the highest conversion (~10.6%),
--    suggesting an optimal balance between affordability and intent

-- 3. High-price users maintain strong conversion (~10.4%),
--    indicating that users engaging with higher-priced items are
--    more intentional and closer to purchase

-- 4. Conversion patterns suggest that user intent plays a stronger
--    role than price alone in determining funnel progression

-- 5. Drop-off before cart remains the largest loss point across all
--    segments, especially pronounced in low-price users

-- Important Note:
-- Price-based analysis is directional, as the dataset contains
-- zero-value price records which may affect segmentation accuracy

-- Next Step:
-- Analyze time-based patterns to understand when users are most
-- active and likely to convert
	