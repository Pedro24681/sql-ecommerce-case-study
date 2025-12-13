-- =====================================================
-- E-COMMERCE CASE STUDY: BUSINESS QUESTIONS ANALYSIS
-- =====================================================
-- File: 02_business_questions.sql
-- Purpose: Answer 6 core business questions using advanced SQL techniques
-- Created: 2025-12-10
-- Author: Pedro24681
-- Database: PostgreSQL 12+ (uses PostgreSQL-specific syntax)
--
-- SYNTAX NOTE: This file uses PostgreSQL syntax (::NUMERIC casting, INTERVAL).
-- To run on MySQL, convert syntax as follows:
--   - ::NUMERIC → CAST(... AS DECIMAL(10,2))
--   - INTERVAL '12 months' → INTERVAL 12 MONTH
--   - CURRENT_DATE → CURDATE()
--   - Table/column names to match actual schema
--
-- The analytical patterns and business logic are universal and demonstrate
-- advanced SQL concepts applicable to any modern SQL database.
-- =====================================================


-- =====================================================
-- QUESTION 1: TOP-SELLING PRODUCT CATEGORY
-- =====================================================
-- BUSINESS CONTEXT:
-- Identify the best-performing product categories by total revenue
-- and their contribution to overall sales. This helps prioritize
-- inventory investment, marketing budget allocation, and identify
-- underperforming categories for optimization.
--
-- SQL TECHNIQUES USED:
-- - Multi-table INNER JOINs (4 tables)
-- - Window function: RANK() for performance ranking
-- - Window function: SUM() OVER () for percentage calculation
-- - Aggregate functions: COUNT(), SUM(), AVG()
-- - Date filtering with INTERVAL for rolling 12-month analysis
--
-- BUSINESS VALUE:
-- - Guide inventory purchasing decisions
-- - Allocate marketing spend to high-performing categories
-- - Identify growth opportunities in underperforming segments

SELECT 
    pc.category_id,
    pc.category_name,
    -- Count unique orders per category (measures market reach)
    COUNT(DISTINCT oi.order_id) AS total_orders,
    -- Total units sold (measures volume/velocity)
    COUNT(oi.order_item_id) AS total_items_sold,
    -- Total revenue generated (primary success metric)
    ROUND(SUM(oi.quantity * oi.unit_price)::NUMERIC, 2) AS total_revenue,
    -- Percentage contribution to overall revenue (identifies dominant categories)
    -- TECHNIQUE: Window function SUM() OVER () computes grand total without subquery
    ROUND(
        SUM(oi.quantity * oi.unit_price) / 
        SUM(SUM(oi.quantity * oi.unit_price)) OVER ()::NUMERIC * 100,
        2
    ) AS revenue_percentage,
    -- Average revenue per order item (measures transaction value)
    ROUND(AVG(oi.quantity * oi.unit_price)::NUMERIC, 2) AS avg_order_value,
    -- Performance ranking (1 = best performing category)
    -- TECHNIQUE: RANK() window function provides competitive ranking
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS category_rank
FROM 
    product_categories pc
    -- Join to products to get category-product mapping
    INNER JOIN products p ON pc.category_id = p.category_id
    -- Join to order_items to get transaction details
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    -- Join to orders to filter by date and get order context
    INNER JOIN orders o ON oi.order_id = o.order_id
WHERE 
    -- Only include last 12 months for current trend analysis
    -- TECHNIQUE: INTERVAL provides portable date arithmetic
    o.order_date >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY 
    -- Group by category to aggregate metrics per category
    pc.category_id,
    pc.category_name
ORDER BY 
    -- Sort by revenue descending to show best performers first
    total_revenue DESC;


-- =====================================================
-- QUESTION 2: TOP CUSTOMERS BY REVENUE
-- =====================================================
-- BUSINESS CONTEXT:
-- Identify high-value customers and analyze their purchasing patterns
-- including purchase frequency and average transaction value. This enables
-- targeted retention programs, VIP customer management, and calculation
-- of customer acquisition ROI.
--
-- SQL TECHNIQUES USED:
-- - Common Table Expression (CTE) for organizing complex logic
-- - Multiple aggregate functions: COUNT(), SUM(), AVG(), MIN(), MAX()
-- - Window functions: RANK(), ROW_NUMBER() for ranking customers
-- - CASE statement for customer segmentation (VIP, Premium, Regular, At-Risk)
-- - Date arithmetic for calculating purchase intervals
-- - LEFT JOIN to include customers who haven't ordered yet
-- - NULLIF() for division by zero protection
--
-- BUSINESS VALUE:
-- - Identify VIP customers for retention and loyalty programs
-- - Segment customers for personalized marketing campaigns
-- - Calculate acceptable customer acquisition cost (CAC) based on LTV
-- - Understand purchase frequency patterns for re-engagement timing

-- CTE: Calculate key metrics for each customer
-- TECHNIQUE: CTEs improve readability and allow referencing intermediate results
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
-- BUSINESS CONTEXT:
-- Identify customers at risk of churning and predict churn probability
-- using RFM (Recency, Frequency, Monetary) analysis. This enables
-- proactive retention campaigns, prioritizes at-risk customers, and
-- measures effectiveness of win-back programs.
--
-- SQL TECHNIQUES USED:
-- - Multiple CTEs: customer_rfm, churn_scoring (staged calculation approach)
-- - RFM Analysis methodology (industry-standard customer segmentation)
-- - Window function: PERCENT_RANK() for percentile scoring
-- - Complex CASE statements for 5-point scoring system
-- - Multiple classification dimensions (risk status, customer status)
-- - Custom ranking with multi-condition CASE in ORDER BY
--
-- BUSINESS VALUE:
-- - Proactive churn prevention (intervene before customer leaves)
-- - Prioritize retention efforts by risk level (optimize spend)
-- - Calculate potential revenue recovery from win-back campaigns
-- - Segment customers for tailored re-engagement strategies
--
-- RFM METHODOLOGY:
-- Recency (R): Days since last purchase (lower is better)
-- Frequency (F): Total number of orders (higher is better)
-- Monetary (M): Total amount spent (higher is better)
-- Each dimension scored 1-5, combined to assess customer value and churn risk

-- CTE 1: Calculate RFM metrics for each customer
-- TECHNIQUE: Aggregate customer order history into RFM dimensions
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
-- CTE 2: Apply RFM scoring methodology
-- TECHNIQUE: Convert continuous metrics to discrete 1-5 scores for segmentation
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
        -- Calculate percentile ranks for statistical context
        -- TECHNIQUE: PERCENT_RANK() returns 0-1 indicating relative position
        PERCENT_RANK() OVER (ORDER BY recency_days) AS recency_percentile,
        PERCENT_RANK() OVER (ORDER BY frequency_orders) AS frequency_percentile,
        PERCENT_RANK() OVER (ORDER BY monetary_value) AS monetary_percentile,
        -- Recency score: Lower days = higher score (5 = most recent)
        -- BUSINESS LOGIC: Recent customers are less likely to churn
        CASE 
            WHEN recency_days <= 30 THEN 5  -- Purchased within last month
            WHEN recency_days <= 60 THEN 4  -- Purchased 1-2 months ago
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
