-- =====================================================
-- 07_data_model.sql
-- Purpose: create reusable analytical views for funnel analysis
-- Database: PostgreSQL
-- Table: ecommerce_events
-- =====================================================

-- -----------------------------------------------------
-- View 1: user_event_times_vw
-- One row per user with first funnel timestamps and avg price
-- -----------------------------------------------------

DROP VIEW IF EXISTS user_event_times_vw;

CREATE VIEW user_event_times_vw AS
SELECT
    user_id,
    MIN(CASE WHEN event_type = 'view' THEN event_time END) AS first_view_time,
    MIN(CASE WHEN event_type = 'cart' THEN event_time END) AS first_cart_time,
    MIN(CASE WHEN event_type = 'purchase' THEN event_time END) AS first_purchase_time,
    ROUND(AVG(price)::numeric, 2) AS avg_price
FROM ecommerce_events
GROUP BY user_id;


-- Preview the view
SELECT *
FROM user_event_times_vw
LIMIT 20;


-- -----------------------------------------------------
-- View 2: user_funnel_base_vw
-- Reusable funnel flags and price segment per user
-- -----------------------------------------------------

DROP VIEW IF EXISTS user_funnel_base_vw;

CREATE VIEW user_funnel_base_vw AS
SELECT
    user_id,
    first_view_time,
    first_cart_time,
    first_purchase_time,
    avg_price,

    CASE
        WHEN avg_price < 50 THEN 'Low'
        WHEN avg_price BETWEEN 50 AND 200 THEN 'Medium'
        ELSE 'High'
    END AS price_segment,

    CASE
        WHEN first_view_time IS NOT NULL THEN 1
        ELSE 0
    END AS viewed,

    CASE
        WHEN first_view_time IS NOT NULL
        AND first_cart_time IS NOT NULL
        AND first_view_time <= first_cart_time
        THEN 1
        ELSE 0
    END AS valid_cart,

    CASE
        WHEN first_view_time IS NOT NULL
        AND first_cart_time IS NOT NULL
        AND first_purchase_time IS NOT NULL
        AND first_view_time <= first_cart_time
        AND first_cart_time <= first_purchase_time
        THEN 1
        ELSE 0
    END AS valid_purchase

FROM user_event_times_vw;


-- Preview the reusable funnel base
SELECT *
FROM user_funnel_base_vw
LIMIT 20;


-- -----------------------------------------------------
-- Validation checks
-- -----------------------------------------------------

-- Check row count = unique users
SELECT COUNT(*) AS total_users_in_view
FROM user_funnel_base_vw;

-- Check price segment distribution
SELECT
    price_segment,
    COUNT(*) AS total_users
FROM user_funnel_base_vw
GROUP BY price_segment
ORDER BY
    CASE
        WHEN price_segment = 'Low' THEN 1
        WHEN price_segment = 'Medium' THEN 2
        WHEN price_segment = 'High' THEN 3
    END;

-- Check funnel flags summary
SELECT
    SUM(viewed) AS view_users,
    SUM(valid_cart) AS cart_users,
    SUM(valid_purchase) AS purchase_users
FROM user_funnel_base_vw;


-- =====================================================
-- 📊 Data Model Summary
-- =====================================================

-- This file creates reusable analytical views so that funnel logic
-- does not need to be rebuilt in every query.

-- user_event_times_vw:
-- Stores first view, cart, and purchase timestamps per user,
-- along with average observed user price.

-- user_funnel_base_vw:
-- Adds reusable funnel flags and price segmentation logic,
-- making downstream SQL files cleaner, more consistent, and
-- easier to maintain.

-- Business Value:
-- This approach improves consistency across analyses and reflects
-- a more scalable analytical workflow compared to repeating
-- the same transformation logic in multiple files.