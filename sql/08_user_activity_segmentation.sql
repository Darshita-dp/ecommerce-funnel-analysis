-- =====================================================
-- 08_user_activity_segmentation.sql
-- Purpose: analyze conversion behavior by user activity level
-- =====================================================

-- 1. Count events per user
WITH user_activity AS (
    SELECT
        user_id,
        COUNT(*) AS total_events
    FROM ecommerce_events
    GROUP BY user_id
),

-- 2. Classify users into activity segments
user_segments AS (
    SELECT
        ua.user_id,
        ua.total_events,
        CASE
            WHEN ua.total_events < 5 THEN 'Low Activity'
            WHEN ua.total_events BETWEEN 5 AND 20 THEN 'Medium Activity'
            ELSE 'High Activity'
        END AS activity_segment
    FROM user_activity ua
),

-- 3. Join with funnel base
final AS (
    SELECT
        s.activity_segment,
        f.viewed,
        f.valid_cart,
        f.valid_purchase
    FROM user_segments s
    JOIN user_funnel_base_vw f
        ON s.user_id = f.user_id
)

-- 4. Aggregate results
SELECT
    activity_segment,
    COUNT(*) AS total_users,
    SUM(viewed) AS view_users,
    SUM(valid_cart) AS cart_users,
    SUM(valid_purchase) AS purchase_users,
    ROUND((SUM(valid_cart) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS view_to_cart_pct,
    ROUND((SUM(valid_purchase) * 100.0 / NULLIF(SUM(valid_cart), 0))::numeric, 2) AS cart_to_purchase_pct,
    ROUND((SUM(valid_purchase) * 100.0 / NULLIF(SUM(viewed), 0))::numeric, 2) AS overall_conversion_pct
FROM final
GROUP BY activity_segment
ORDER BY
    CASE
        WHEN activity_segment = 'Low Activity' THEN 1
        WHEN activity_segment = 'Medium Activity' THEN 2
        WHEN activity_segment = 'High Activity' THEN 3
    END;