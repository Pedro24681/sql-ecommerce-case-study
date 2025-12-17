-- =====================================================
-- E-Commerce SQL Case Study – Business Questions
-- =====================================================
-- File: 02_business_questions.sql
--
-- This file I made answers a set of core business questions using SQL.
-- Each query is written to reflect how a data analyst would
-- approach real world e-commerce problems such as revenue analysis,
-- customer behavior, and churn risk.
--
-- Environment:
-- - PostgreSQL 12+
-- - Uses PostgreSQL-specific features (INTERVAL, ::NUMERIC casting)
--
-- Note on portability:
-- These queries can be adapted to other SQL engines (MySQL, SQL Server)
-- with minor syntax changes. The underlying logic and analytical
-- approach should remain the same :).
-- =====================================================


-- =====================================================
-- QUESTION 1: TOP-SELLING PRODUCT CATEGORIES
-- =====================================================
-- Goal:
-- Understand which product categories generate the most revenue
-- and how much each category contributes to total sales.
--
-- Why this matters:
-- This helps inform inventory planning, marketing focus, and
-- highlights categories that may need improvement or promotion.
--
-- Approach:
-- - Join categories → products → order items → orders
-- - Aggregate revenue and volume metrics by category
-- - Rank categories based on total revenue
-- - Calculate revenue contribution as a percentage of total sales
--
-- Time frame:
-- Last 12 months to reflect recent performance

SELECT 
    pc.category_id,
    pc.category_name,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    COUNT(oi.order_item_id) AS total_items_sold,
    ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2) AS total_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) / 
        SUM(SUM(oi.quantity * oi.unit_price)) OVER ()::NUMERIC * 100,
        2
    ) AS revenue_percentage,
    ROUND(AVG(oi.quantity * oi.unit_price)::NUMERIC, 2) AS avg_order_value,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS category_rank
FROM 
    product_categories pc
    INNER JOIN products p ON pc.category_id = p.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
WHERE 
    o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    pc.category_id,
    pc.category_name
ORDER BY 
    total_revenue DESC;


-- =====================================================
-- QUESTION 2: TOP CUSTOMERS BY REVENUE
-- =====================================================
-- Goal:
-- Identify the highest-value customers and understand how often
-- they purchase and how much they typically spend.
--
-- Why this matters:
-- High-value customers drive a large portion of revenue.
-- Understanding them supports retention strategies, loyalty programs,
-- and more accurate customer lifetime value estimates.
--
-- Approach:
-- - Use a CTE to calculate customer-level metrics
-- - Aggregate purchase counts, revenue, and timing
-- - Rank customers by lifetime revenue
-- - Segment customers into value tiers

WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        c.country,
        COUNT(DISTINCT o.order_id) AS total_purchases,
        COUNT(DISTINCT CAST(o.order_date AS DATE)) AS days_with_purchases,
        ROUND(SUM(o.total_amount)::NUMERIC, 2) AS lifetime_revenue,
        ROUND(AVG(o.total_amount)::NUMERIC, 2) AS avg_order_value,
        MIN(o.order_date) AS first_purchase_date,
        MAX(o.order_date) AS last_purchase_date,
        ROUND(
            (MAX(o.order_date)::DATE - MIN(o.order_date)::DATE) / 
            NULLIF(COUNT(DISTINCT o.order_id) - 1, 0),
            2
        ) AS avg_days_between_purchases
    FROM 
        customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id,
        c.customer_name,
        c.email,
        c.country
)
SELECT 
    customer_id,
    customer_name,
    email,
    country,
    total_purchases,
    lifetime_revenue,
    avg_order_value,
    days_with_purchases,
    first_purchase_date,
    last_purchase_date,
    avg_days_between_purchases,
    RANK() OVER (ORDER BY lifetime_revenue DESC) AS customer_rank,
    ROW_NUMBER() OVER (ORDER BY lifetime_revenue DESC) AS row_num,
    CASE 
        WHEN lifetime_revenue >= 5000 THEN 'VIP'
        WHEN lifetime_revenue >= 2000 THEN 'Premium'
        WHEN lifetime_revenue >= 500 THEN 'Regular'
        ELSE 'At-Risk'
    END AS customer_segment
FROM 
    customer_metrics
WHERE 
    total_purchases > 0
ORDER BY 
    lifetime_revenue DESC
LIMIT 50;


-- =====================================================
-- QUESTION 3: REPEAT PURCHASE BEHAVIOR
-- =====================================================
-- Goal:
-- Measure how often customers return and classify loyalty levels.
--
-- Why this matters:
-- Repeat customers are typically more profitable and cheaper
-- to retain than acquiring new ones.
--
-- Approach:
-- - Track purchase sequence for each customer
-- - Calculate time between purchases
-- - Classify customers based on repeat behavior

WITH customer_purchase_history AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS purchase_count,
        LAG(o.order_date) OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date
        ) AS previous_purchase_date,
        o.order_date AS current_purchase_date,
        ROUND(
            (o.order_date::DATE - LAG(o.order_date) OVER (
                PARTITION BY c.customer_id 
                ORDER BY o.order_date
            )::DATE)::NUMERIC,
            2
        ) AS days_since_last_purchase,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id 
            ORDER BY o.order_date
        ) AS purchase_sequence
    FROM 
        customers c
        INNER JOIN orders o ON c.customer_id = o.customer_id
),
repeat_metrics AS (
    SELECT 
        customer_id,
        customer_name,
        MAX(purchase_count) AS total_purchases,
        COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END) AS repeat_orders,
        ROUND(
            COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END)::NUMERIC / 
            MAX(purchase_count)::NUMERIC * 100,
            2
        ) AS repeat_purchase_rate,
        ROUND(AVG(days_since_last_purchase)::NUMERIC, 2) AS avg_days_between_purchases,
        CASE 
            WHEN MAX(purchase_count) = 1 THEN 'One-Time Buyer'
            WHEN ROUND(
                COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END)::NUMERIC / 
                MAX(purchase_count)::NUMERIC * 100, 2
            ) >= 80 THEN 'Highly Loyal'
            WHEN ROUND(
                COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END)::NUMERIC / 
                MAX(purchase_count)::NUMERIC * 100, 2
            ) >= 50 THEN 'Repeat Customer'
            ELSE 'Inconsistent Buyer'
        END AS loyalty_status
    FROM 
        customer_purchase_history
    GROUP BY 
        customer_id,
        customer_name
)
SELECT 
    customer_id,
    customer_name,
    total_purchases,
    repeat_orders,
    repeat_purchase_rate,
    avg_days_between_purchases,
    loyalty_status,
    RANK() OVER (ORDER BY repeat_purchase_rate DESC) AS loyalty_rank
FROM 
    repeat_metrics
ORDER BY 
    repeat_purchase_rate DESC, 
    total_purchases DESC;


-- =====================================================
-- QUESTION 4: HIGHEST SALES DAYS
-- =====================================================
-- Goal:
-- Identify days with unusually high sales and understand
-- day-of-week patterns.
--
-- Why this matters:
-- Helps with staffing, promotions, and campaign timing.
--
-- Approach:
-- - Aggregate daily revenue and order volume
-- - Rank days by revenue
-- - Compare each day to overall sales distribution

WITH daily_sales AS (
    SELECT 
        CAST(o.order_date AS DATE) AS sales_date,
        EXTRACT(DOW FROM o.order_date) AS day_of_week,
        TO_CHAR(o.order_date, 'Day') AS day_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        COUNT(oi.order_item_id) AS total_items,
        ROUND(SUM(o.total_amount)::NUMERIC, 2) AS daily_revenue,
        ROUND(AVG(o.total_amount)::NUMERIC, 2) AS avg_order_value
    FROM 
        orders o
        LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        CAST(o.order_date AS DATE),
        EXTRACT(DOW FROM o.order_date),
        TO_CHAR(o.order_date, 'Day')
)
SELECT 
    sales_date,
    day_name,
    total_orders,
    unique_customers,
    total_items,
    daily_revenue,
    avg_order_value,
    RANK() OVER (ORDER BY daily_revenue DESC) AS revenue_rank,
    ROW_NUMBER() OVER (ORDER BY daily_revenue DESC) AS row_num,
    ROUND(
        daily_revenue / SUM(daily_revenue) OVER ()::NUMERIC * 100,
        2
    ) AS revenue_contribution_pct,
    CASE 
        WHEN daily_revenue >= (
            SELECT PERCENTILE_CONT(0.9) 
            WITHIN GROUP (ORDER BY daily_revenue) 
            FROM daily_sales
        ) THEN 'Peak Day'
        WHEN daily_revenue >= (
            SELECT PERCENTILE_CONT(0.75) 
            WITHIN GROUP (ORDER BY daily_revenue) 
            FROM daily_sales
        ) THEN 'High Activity'
        WHEN daily_revenue >= (
            SELECT PERCENTILE_CONT(0.5) 
            WITHIN GROUP (ORDER BY daily_revenue) 
            FROM daily_sales
        ) THEN 'Normal'
        ELSE 'Low Activity'
    END AS activity_level,
    LAG(daily_revenue) OVER (ORDER BY sales_date) AS previous_day_revenue,
    ROUND(
        ((daily_revenue - LAG(daily_revenue) OVER (ORDER BY sales_date)) / 
         LAG(daily_revenue) OVER (ORDER BY sales_date)::NUMERIC) * 100,
        2
    ) AS revenue_change_pct
FROM 
    daily_sales
ORDER BY 
    daily_revenue DESC
LIMIT 100;


-- =====================================================
-- QUESTION 5: CUSTOMER LIFETIME VALUE (CLV)
-- =====================================================
-- Goal:
-- Estimate customer lifetime value based on historical behavior.
--
-- Why this matters:
-- CLV helps decide how much to spend on acquisition and retention.
--
-- Approach:
-- - Calculate total spend and purchase frequency
-- - Estimate annual spending rate
-- - Project future value using simple multipliers

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(o.total_amount)::NUMERIC, 2) AS total_spent,
        MIN(o.order_date) AS first_purchase_date,
        MAX(o.order_date) AS most_recent_purchase_date,
        ROUND((CURRENT_DATE - MAX(o.order_date)::DATE)::NUMERIC, 0) AS days_since_last_purchase,
        ROUND((CURRENT_DATE - MIN(o.order_date)::DATE)::NUMERIC, 0) AS customer_lifetime_days,
        ROUND(
            SUM(o.total_amount) / 
            NULLIF((CURRENT_DATE - MIN(o.order_date)::DATE), 0)::NUMERIC * 365,
            2
        ) AS annual_spending_rate
    FROM 
        customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id,
        c.customer_name,
        c.email
),
clv_calculation AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        total_orders,
        total_spent,
        first_purchase_date,
        most_recent_purchase_date,
        days_since_last_purchase,
        customer_lifetime_days,
        annual_spending_rate,
        CASE 
            WHEN total_orders > 0 THEN ROUND(total_spent / total_orders::NUMERIC, 2)
            ELSE 0
        END AS avg_order_value,
        CASE 
            WHEN total_orders > 0 AND customer_lifetime_days > 0 
                THEN ROUND(
                    (total_spent / total_orders::NUMERIC) * 
                    (total_orders / (customer_lifetime_days / 365.0)::NUMERIC),
                    2
                )
            ELSE 0
        END AS calculated_clv,
        CASE 
            WHEN total_orders >= 5 THEN (total_spent * 3)
            WHEN total_orders >= 3 THEN (total_spent * 2.5)
            WHEN total_orders >= 1 THEN (total_spent * 2)
            ELSE 0
        END AS projected_clv_3years
    FROM 
        customer_spending
)
SELECT 
    customer_id,
    customer_name,
    email,
    total_orders,
    total_spent,
    avg_order_value,
    calculated_clv,
    projected_clv_3years,
    annual_spending_rate,
    days_since_last_purchase,
    customer_lifetime_days,
    RANK() OVER (ORDER BY calculated_clv DESC) AS clv_rank,
    ROUND(
        calculated_clv / SUM(calculated_clv) OVER ()::NUMERIC * 100,
        2
    ) AS clv_contribution_pct,
    CASE 
        WHEN calculated_clv >= 10000 THEN 'Tier 1 – Premium'
        WHEN calculated_clv >= 5000 THEN 'Tier 2 – High Value'
        WHEN calculated_clv >= 1000 THEN 'Tier 3 – Medium Value'
        WHEN calculated_clv > 0 THEN 'Tier 4 – Low Value'
        ELSE
