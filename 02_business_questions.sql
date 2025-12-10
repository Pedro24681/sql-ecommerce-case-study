-- =====================================================
-- E-COMMERCE CASE STUDY: BUSINESS QUESTIONS ANALYSIS
-- =====================================================
-- File: 02_business_questions.sql
-- Purpose: Answer 6 core business questions using advanced SQL techniques
-- Created: 2025-12-10
-- Author: Pedro24681
-- =====================================================


-- =====================================================
-- QUESTION 1: TOP-SELLING PRODUCT CATEGORY
-- =====================================================
-- Identify the best-performing product categories by total revenue
-- and their contribution to overall sales

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
-- Identify high-value customers and their purchasing patterns
-- Including purchase frequency and average transaction value

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
            (MAX(o.order_date)::DATE - MIN(o.order_date)::DATE) / NULLIF(COUNT(DISTINCT o.order_id) - 1, 0),
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
-- QUESTION 3: REPEAT PURCHASE RATE
-- =====================================================
-- Calculate repeat purchase rate and identify customer segments
-- Based on purchase frequency and recency

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
            WHEN ROUND(COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END)::NUMERIC / 
                       MAX(purchase_count)::NUMERIC * 100, 2) >= 80 THEN 'Highly Loyal'
            WHEN ROUND(COUNT(CASE WHEN purchase_sequence > 1 THEN 1 END)::NUMERIC / 
                       MAX(purchase_count)::NUMERIC * 100, 2) >= 50 THEN 'Repeat Customer'
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
-- Identify peak sales days and trends
-- Including day-of-week analysis and sales concentration

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
        WHEN daily_revenue >= (SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY daily_revenue) FROM daily_sales) 
            THEN 'Peak Day'
        WHEN daily_revenue >= (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY daily_revenue) FROM daily_sales) 
            THEN 'High Activity'
        WHEN daily_revenue >= (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY daily_revenue) FROM daily_sales) 
            THEN 'Normal'
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
-- Calculate comprehensive Customer Lifetime Value metrics
-- Including purchase frequency, spending patterns, and predictive segments

WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(o.total_amount)::NUMERIC, 2) AS total_spent,
        MIN(o.order_date) AS first_purchase_date,
        MAX(o.order_date) AS most_recent_purchase_date,
        ROUND(
            (CURRENT_DATE - MAX(o.order_date)::DATE)::NUMERIC,
            0
        ) AS days_since_last_purchase,
        ROUND(
            (CURRENT_DATE - MIN(o.order_date)::DATE)::NUMERIC,
            0
        ) AS customer_lifetime_days,
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
                THEN ROUND((total_spent / total_orders::NUMERIC) * (total_orders / (customer_lifetime_days / 365.0)::NUMERIC), 2)
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
        WHEN calculated_clv >= 10000 THEN 'Tier 1 - Premium'
        WHEN calculated_clv >= 5000 THEN 'Tier 2 - High Value'
        WHEN calculated_clv >= 1000 THEN 'Tier 3 - Medium Value'
        WHEN calculated_clv > 0 THEN 'Tier 4 - Low Value'
        ELSE 'Inactive'
    END AS clv_tier
FROM 
    clv_calculation
WHERE 
    total_orders > 0
ORDER BY 
    calculated_clv DESC;


-- =====================================================
-- QUESTION 6: CHURN RISK ANALYSIS
-- =====================================================
-- Identify at-risk customers and predict churn probability
-- Based on recency, frequency, and monetary value

WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        c.country,
        MAX(o.order_date) AS last_purchase_date,
        ROUND(
            (CURRENT_DATE - MAX(o.order_date)::DATE)::NUMERIC,
            0
        ) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency_orders,
        ROUND(SUM(o.total_amount)::NUMERIC, 2) AS monetary_value,
        ROUND(
            (CURRENT_DATE - MIN(o.order_date)::DATE)::NUMERIC / 365.0,
            2
        ) AS customer_tenure_years
    FROM 
        customers c
        INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY 
        c.customer_id,
        c.customer_name,
        c.email,
        c.country
),
churn_scoring AS (
    SELECT 
        customer_id,
        customer_name,
        email,
        country,
        last_purchase_date,
        recency_days,
        frequency_orders,
        monetary_value,
        customer_tenure_years,
        -- Calculate percentile scores for RFM
        PERCENT_RANK() OVER (ORDER BY recency_days) AS recency_percentile,
        PERCENT_RANK() OVER (ORDER BY frequency_orders) AS frequency_percentile,
        PERCENT_RANK() OVER (ORDER BY monetary_value) AS monetary_percentile,
        -- Recency score (lower is better)
        CASE 
            WHEN recency_days <= 30 THEN 5
            WHEN recency_days <= 60 THEN 4
            WHEN recency_days <= 90 THEN 3
            WHEN recency_days <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        -- Frequency score (higher is better)
        CASE 
            WHEN frequency_orders >= 10 THEN 5
            WHEN frequency_orders >= 5 THEN 4
            WHEN frequency_orders >= 3 THEN 3
            WHEN frequency_orders >= 2 THEN 2
            ELSE 1
        END AS frequency_score,
        -- Monetary score (higher is better)
        CASE 
            WHEN monetary_value >= 5000 THEN 5
            WHEN monetary_value >= 2000 THEN 4
            WHEN monetary_value >= 500 THEN 3
            WHEN monetary_value >= 100 THEN 2
            ELSE 1
        END AS monetary_score
    FROM 
        customer_rfm
)
SELECT 
    customer_id,
    customer_name,
    email,
    country,
    last_purchase_date,
    recency_days,
    frequency_orders,
    monetary_value,
    customer_tenure_years,
    recency_score,
    frequency_score,
    monetary_score,
    ROUND(
        (recency_score + frequency_score + monetary_score) / 3.0,
        2
    ) AS overall_rfm_score,
    ROUND(
        ((5 - recency_score) / 5.0 * 100 - (frequency_score / 5.0 * 50) - (monetary_score / 5.0 * 30)),
        2
    ) AS churn_risk_score,
    CASE 
        WHEN recency_days > 180 AND frequency_orders < 2 THEN 'Critical Risk'
        WHEN recency_days > 120 AND frequency_orders < 3 THEN 'High Risk'
        WHEN recency_days > 90 OR frequency_orders < 2 THEN 'Medium Risk'
        WHEN recency_days > 60 THEN 'Low Risk'
        ELSE 'Stable Customer'
    END AS churn_status,
    CASE 
        WHEN recency_days > 180 THEN 'Inactive'
        WHEN recency_days > 90 THEN 'At Risk'
        WHEN recency_days > 60 THEN 'Dormant'
        ELSE 'Active'
    END AS customer_status,
    RANK() OVER (ORDER BY 
        CASE 
            WHEN recency_days > 180 AND frequency_orders < 2 THEN 1
            WHEN recency_days > 120 AND frequency_orders < 3 THEN 2
            WHEN recency_days > 90 OR frequency_orders < 2 THEN 3
            WHEN recency_days > 60 THEN 4
            ELSE 5
        END,
        recency_days DESC
    ) AS churn_risk_rank
FROM 
    churn_scoring
ORDER BY 
    churn_risk_score DESC,
    recency_days DESC
LIMIT 100;


-- =====================================================
-- END OF BUSINESS QUESTIONS ANALYSIS
-- =====================================================
