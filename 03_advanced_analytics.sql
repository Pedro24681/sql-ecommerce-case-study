-- ============================================================================
-- Advanced Analytics Queries – E-Commerce SQL Case Study
-- ============================================================================
-- File: 03_advanced_analytics.sql
--
-- This file is a “playbook” of more advanced analytics patterns you’ll see in
-- real analyst work: window functions, CTE pipelines, growth calculations,
-- cohort retention, and a few deeper cuts like basket analysis.
--
-- Dialect note:
-- Some queries use SQL Server date functions (DATEDIFF/DATEADD/DATEPART/GETDATE),
-- while other parts follow patterns commonly used in PostgreSQL.
-- The ideas are portable; the date/time syntax is the main thing you’d swap
-- when moving between database engines.
--
-- What’s in here:
-- - Product and customer ranking (RANK/DENSE_RANK/ROW_NUMBER)
-- - Running totals and distribution checks (cumulative/percentiles/tiles)
-- - Product performance summaries and trend comparisons
-- - RFM-style customer segmentation + CLV-style value banding
-- - Order-to-order progression and growth trajectories
-- - Monthly/Yoy/MoM growth patterns
-- - Cohort retention and repeat behavior by cohort
-- - Seasonality patterns and weekday vs weekend behavior
-- - Simple basket analysis (“frequently bought together”)
-- - KPI / scorecard style outputs for quick executive views
-- ============================================================================


-- ============================================================================
-- 1) WINDOW FUNCTIONS – RANKING + CUMULATIVE ANALYSIS
-- ============================================================================
-- Why this section exists:
-- Window functions are one of the biggest “step-ups” in SQL because they let you
-- do ranking, comparisons, and running totals without awkward subqueries.
-- The examples below are intentionally practical: product ranks, customer order
-- sequences, and distribution slices.

-- Query 1.1: Product Sales Ranking + Running Total
-- What this answers:
-- - Which products drive the most revenue?
-- - How concentrated are sales (Pareto / 80-20 style)?
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    SUM(oi.quantity * oi.unit_price) AS total_sales,
    RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS sales_rank_in_category,
    DENSE_RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS overall_sales_rank,
    SUM(SUM(oi.quantity * oi.unit_price)) OVER (ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS cumulative_sales,
    ROW_NUMBER() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS row_num
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
INNER JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, c.category_id, c.category_name
ORDER BY overall_sales_rank;


-- Query 1.2: Customer Purchase Timing + Frequency (Window-based)
-- What this answers:
-- - How quickly do customers come back for a second/third order?
-- - Who is ordering frequently vs drifting away?
SELECT 
    customer_id,
    order_id,
    order_date,
    order_total,
    LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
    DATEDIFF(DAY, LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date), order_date) AS days_since_last_order,
    COUNT(*) OVER (PARTITION BY customer_id) AS total_customer_orders,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_sequence,
    LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS next_order_date
FROM orders
ORDER BY customer_id, order_date;


-- Query 1.3: Order Value Distribution (Percentiles / Quartiles / Deciles)
-- What this answers:
-- Where does each order sit relative to the rest (e.g., top 10%, top 25%)?
SELECT 
    order_id,
    order_total,
    PERCENT_RANK() OVER (ORDER BY order_total) * 100 AS percentile_rank,
    NTILE(4) OVER (ORDER BY order_total) AS quartile,
    NTILE(10) OVER (ORDER BY order_total) AS decile,
    ROUND(AVG(order_total) OVER (), 2) AS avg_order_value,
    order_total - ROUND(AVG(order_total) OVER (), 2) AS deviation_from_avg
FROM orders
WHERE order_date >= DATEADD(YEAR, -1, GETDATE())
ORDER BY order_total DESC;


-- ============================================================================
-- 2) CTE PIPELINES – PRODUCT PERFORMANCE SUMMARIES
-- ============================================================================
-- These are structured like “mini data pipelines”:
-- step 1 = build the base table, step 2 = enrich/rank it, step 3 = output.

-- Query 2.1: Product Performance Report (Revenue, Units, Orders, Time Range)
WITH product_sales AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS number_of_orders,
        AVG(oi.quantity * oi.unit_price) AS avg_order_value,
        MAX(o.order_date) AS last_sale_date,
        MIN(o.order_date) AS first_sale_date
    FROM products p
    INNER JOIN categories c ON p.category_id = c.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id, p.product_name, c.category_name
),
product_rankings AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY category_name ORDER BY total_revenue DESC) AS revenue_rank_in_category,
        RANK() OVER (ORDER BY total_revenue DESC) AS overall_revenue_rank,
        ROUND(total_revenue / SUM(total_revenue) OVER (PARTITION BY category_name) * 100, 2) AS pct_of_category_revenue
    FROM product_sales
)
SELECT 
    product_id,
    product_name,
    category_name,
    total_units_sold,
    total_revenue,
    number_of_orders,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND(DATEDIFF(DAY, first_sale_date, last_sale_date), 0) AS days_in_catalog,
    revenue_rank_in_category,
    overall_revenue_rank,
    pct_of_category_revenue
FROM product_rankings
ORDER BY overall_revenue_rank;


-- Query 2.2: Trend Check – Current Month vs Previous Month
-- Helpful for spotting products that are accelerating or slowing down.
WITH current_period AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS current_units,
        SUM(oi.quantity * oi.unit_price) AS current_revenue,
        COUNT(DISTINCT oi.order_id) AS current_orders
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(MONTH, -1, GETDATE())
    GROUP BY p.product_id, p.product_name
),
previous_period AS (
    SELECT 
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS previous_units,
        SUM(oi.quantity * oi.unit_price) AS previous_revenue,
        COUNT(DISTINCT oi.order_id) AS previous_orders
    FROM products p
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date >= DATEADD(MONTH, -2, GETDATE())
        AND o.order_date < DATEADD(MONTH, -1, GETDATE())
    GROUP BY p.product_id, p.product_name
)
SELECT 
    cp.product_id,
    cp.product_name,
    COALESCE(cp.current_units, 0) AS current_units,
    COALESCE(pp.previous_units, 0) AS previous_units,
    COALESCE(cp.current_units, 0) - COALESCE(pp.previous_units, 0) AS unit_change,
    CASE 
        WHEN COALESCE(pp.previous_units, 0) = 0 THEN NULL
        ELSE ROUND((CAST(COALESCE(cp.current_units, 0) - COALESCE(pp.previous_units, 0) AS FLOAT) / COALESCE(pp.previous_units, 0)) * 100, 2)
    END AS unit_growth_pct,
    COALESCE(cp.current_revenue, 0) AS current_revenue,
    COALESCE(pp.previous_revenue, 0) AS previous_revenue,
    COALESCE(cp.current_revenue, 0) - COALESCE(pp.previous_revenue, 0) AS revenue_change,
    CASE 
        WHEN COALESCE(pp.previous_revenue, 0) = 0 THEN NULL
        ELSE ROUND((COALESCE(cp.current_revenue, 0) - COALESCE(pp.previous_revenue, 0)) / COALESCE(pp.previous_revenue, 0) * 100, 2)
    END AS revenue_growth_pct
FROM current_period cp
FULL OUTER JOIN previous_period pp ON cp.product_id = pp.product_id
ORDER BY revenue_change DESC;


-- ============================================================================
-- 3) CUSTOMER SEGMENTATION (RFM + CLV STYLE)
-- ============================================================================
-- This is a common real-world pattern: turn raw transactions into customer-level
-- metrics, score them into bands, and use those bands to guide marketing/retention.

-- Query 3.1: RFM Segmentation
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS recency_days,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.order_total) AS monetary_value,
        AVG(o.order_total) AS avg_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.email
),
rfm_scoring AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY recency_days DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary_value) AS monetary_score
    FROM customer_metrics
)
SELECT 
    customer_id,
    customer_name,
    email,
    recency_days,
    frequency,
    ROUND(monetary_value, 2) AS monetary_value,
    ROUND(avg_order_value, 2) AS avg_order_value,
    recency_score,
    frequency_score,
    monetary_score,
    CASE 
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 3 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Loyal Customers'
        WHEN recency_score >= 3 AND frequency_score <= 2 THEN 'At Risk'
        WHEN recency_score <= 2 AND frequency_score >= 3 THEN 'Cant Lose Them'
        WHEN recency_score >= 3 THEN 'Potential Loyalists'
        ELSE 'New/Lost'
    END AS customer_segment
FROM rfm_scoring
ORDER BY monetary_value DESC;


-- Query 3.2: CLV-Style Value Bands (3-year proxy)
WITH customer_purchases AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(o.order_total) AS total_spent,
        AVG(o.order_total) AS avg_order_value,
        DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS customer_lifespan_days,
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) AS days_since_last_purchase
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
),
clv_calculation AS (
    SELECT 
        *,
        CASE 
            WHEN customer_lifespan_days = 0 THEN avg_order_value * 12
            ELSE (total_spent / NULLIF(customer_lifespan_days, 0)) * 365
        END AS annual_value,
        ROUND((total_spent / NULLIF(customer_lifespan_days, 0)) * 365 * 3, 2) AS predicted_3yr_value
    FROM customer_purchases
)
SELECT 
    customer_id,
    customer_name,
    total_orders,
    ROUND(total_spent, 2) AS total_spent,
    ROUND(avg_order_value, 2) AS avg_order_value,
    customer_lifespan_days,
    days_since_last_purchase,
    ROUND(annual_value, 2) AS annual_value,
    predicted_3yr_value,
    NTILE(5) OVER (ORDER BY predicted_3yr_value) AS clv_quintile,
    CASE 
        WHEN NTILE(5) OVER (ORDER BY predicted_3yr_value) = 5 THEN 'VIP'
        WHEN NTILE(5) OVER (ORDER BY predicted_3yr_value) >= 4 THEN 'High Value'
        WHEN NTILE(5) OVER (ORDER BY predicted_3yr_value) >= 3 THEN 'Medium Value'
        ELSE 'Standard'
    END AS clv_segment
FROM clv_calculation
ORDER BY predicted_3yr_value DESC;


-- ============================================================================
-- 4) ORDER-TO-ORDER GROWTH (CUSTOMER TRAJECTORIES)
-- ============================================================================
-- Useful when you want to see how customer behavior changes from order #1 to #2,
-- or whether spending grows over time.

-- Query 4.1: Customer Order Sequence + Growth vs Previous Order
WITH customer_order_sequence AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.order_id,
        o.order_date,
        o.order_total,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS order_number,
        LAG(o.order_total) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS previous_order_total,
        LEAD(o.order_total) OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS next_order_total,
        DATEDIFF(DAY, LAG(o.order_date) OVER (PARTITION BY c.customer_id ORDER BY o.order_date), o.order_date) AS days_to_next_order
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    customer_id,
    customer_name,
    order_number,
    order_id,
    order_date,
    ROUND(order_total, 2) AS order_total,
    ROUND(previous_order_total, 2) AS previous_order_total,
    CASE 
        WHEN previous_order_total IS NULL THEN NULL
        ELSE ROUND(((order_total - previous_order_total) / previous_order_total) * 100, 2)
    END AS growth_vs_previous_pct,
    days_to_next_order,
    ROUND(next_order_total, 2) AS next_order_total
FROM customer_order_sequence
WHERE order_number <= 10
ORDER BY customer_id, order_number;


-- Query 4.2: Average Order Value Progression by Sequence #
WITH order_sequence_analysis AS (
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) AS order_sequence,
        ROUND(o.order_total, 2) AS order_total,
        c.customer_id
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT 
    order_sequence,
    COUNT(DISTINCT customer_id) AS customer_count,
    ROUND(AVG(order_total), 2) AS avg_order_value,
    ROUND(MIN(order_total), 2) AS min_order_value,
    ROUND(MAX(order_total), 2) AS max_order_value,
    ROUND(STDEV(order_total), 2) AS std_dev_order_value,
    LAG(ROUND(AVG(order_total), 2)) OVER (ORDER BY order_sequence) AS prev_avg_order_value,
    ROUND(ROUND(AVG(order_total), 2) - LAG(ROUND(AVG(order_total), 2)) OVER (ORDER BY order_sequence), 2) AS avg_growth
FROM order_sequence_analysis
GROUP BY order_sequence
HAVING order_sequence <= 8
ORDER BY order_sequence;


-- ============================================================================
-- 5) TOP PRODUCTS WITHIN CATEGORIES
-- ============================================================================
-- This is a common reporting need: "show me top N items per category".

-- Query 5.1: Top 3 Products per Category by Revenue
WITH category_product_ranking AS (
    SELECT 
        c.category_id,
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_units,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        COUNT(DISTINCT oi.order_id) AS order_count,
        RANK() OVER (PARTITION BY c.category_id ORDER BY SUM(oi.quantity * oi.unit_price) DESC) AS revenue_rank
    FROM categories c
    INNER JOIN products p ON c.category_id = p.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
)
SELECT 
    category_id,
    category_name,
    product_id,
    product_name,
    total_units,
    ROUND(total_revenue, 2) AS total_revenue,
    order_count,
    revenue_rank,
    ROUND(total_revenue / SUM(total_revenue) OVER (PARTITION BY category_id) * 100, 2) AS pct_of_category
FROM category_product_ranking
WHERE revenue_rank <= 3
ORDER BY category_id, revenue_rank;


-- Query 5.2: Product vs Category Average (Quick Benchmarking)
WITH category_stats AS (
    SELECT 
        c.category_id,
        c.category_name,
        ROUND(AVG(SUM(oi.quantity * oi.unit_price)), 2) AS avg_category_revenue,
        ROUND(AVG(SUM(oi.quantity)), 2) AS avg_category_units,
        ROUND(AVG(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT oi.order_id)), 2) AS avg_transaction_value
    FROM categories c
    INNER JOIN products p ON c.category_id = p.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_id, c.category_name
),
product_stats AS (
    SELECT 
        c.category_id,
        c.category_name,
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS product_revenue,
        ROUND(SUM(oi.quantity), 2) AS product_units,
        COUNT(DISTINCT oi.order_id) AS transaction_count
    FROM categories c
    INNER JOIN products p ON c.category_id = p.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
)
SELECT 
    ps.category_id,
    ps.category_name,
    ps.product_id,
    ps.product_name,
    ps.product_revenue,
    cs.avg_category_revenue,
    ROUND(ps.product_revenue - cs.avg_category_revenue, 2) AS revenue_vs_avg,
    ROUND((ps.product_revenue / cs.avg_category_revenue - 1) * 100, 2) AS performance_index,
    ps.product_units,
    ROUND(ps.product_revenue / ps.transaction_count, 2) AS avg_transaction_value,
    cs.avg_transaction_value AS category_avg_transaction
FROM product_stats ps
INNER JOIN category_stats cs ON ps.category_id = cs.category_id
ORDER BY ps.category_id, ps.product_revenue DESC;


-- ============================================================================
-- 6) MONTH-OVER-MONTH / YEAR-OVER-YEAR GROWTH
-- ============================================================================
-- The two outputs below are useful for “how are we trending?” questions.

-- Query 6.1: Monthly Totals + YoY Comparison
WITH monthly_sales AS (
    SELECT 
        DATEPART(YEAR, o.order_date) AS year,
        DATEPART(MONTH, o.order_date) AS month,
        FORMAT(o.order_date, 'YYYY-MM') AS year_month,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        SUM(o.order_total) AS total_revenue,
        AVG(o.order_total) AS avg_order_value
    FROM orders o
    GROUP BY DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), FORMAT(o.order_date, 'YYYY-MM')
),
monthly_with_lag AS (
    SELECT 
        *,
        LAG(total_revenue) OVER (PARTITION BY month ORDER BY year) AS prev_year_revenue,
        LAG(order_count) OVER (PARTITION BY month ORDER BY year) AS prev_year_orders,
        LAG(unique_customers) OVER (PARTITION BY month ORDER BY year) AS prev_year_customers
    FROM monthly_sales
)
SELECT 
    year,
    month,
    year_month,
    order_count,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    unique_customers,
    prev_year_revenue,
    CASE 
        WHEN prev_year_revenue IS NULL THEN NULL
        ELSE ROUND(((total_revenue - prev_year_revenue) / prev_year_revenue) * 100, 2)
    END AS yoy_revenue_growth_pct,
    CASE 
        WHEN prev_year_orders IS NULL THEN NULL
        ELSE ROUND(((order_count - prev_year_orders) / prev_year_orders) * 100, 2)
    END AS yoy_order_growth_pct
FROM monthly_with_lag
ORDER BY year DESC, month DESC;


-- Query 6.2: MoM Growth (Monthly rollup from daily)
WITH daily_sales AS (
    SELECT 
        CAST(o.order_date AS DATE) AS order_date,
        DATEPART(YEAR, o.order_date) AS year,
        DATEPART(MONTH, o.order_date) AS month,
        DATEPART(WEEK, o.order_date) AS week,
        COUNT(DISTINCT o.order_id) AS daily_orders,
        SUM(o.order_total) AS daily_revenue
    FROM orders o
    GROUP BY CAST(o.order_date AS DATE), DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), DATEPART(WEEK, o.order_date)
),
monthly_aggregated AS (
    SELECT 
        year,
        month,
        COUNT(*) AS days_in_month,
        SUM(daily_orders) AS monthly_orders,
        SUM(daily_revenue) AS monthly_revenue,
        ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
    FROM daily_sales
    GROUP BY year, month
),
growth_calculation AS (
    SELECT 
        *,
        LAG(monthly_revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
        LAG(monthly_orders) OVER (ORDER BY year, month) AS prev_month_orders
    FROM monthly_aggregated
)
SELECT 
    year,
    month,
    DATEFROMPARTS(year, month, 1) AS month_start,
    days_in_month,
    monthly_orders,
    ROUND(monthly_revenue, 2) AS monthly_revenue,
    avg_daily_revenue,
    prev_month_revenue,
    CASE 
        WHEN prev_month_revenue IS NULL THEN NULL
        ELSE ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2)
    END AS mom_revenue_growth_pct,
    CASE 
        WHEN prev_month_orders IS NULL THEN NULL
        ELSE ROUND(((monthly_orders - prev_month_orders) / prev_month_orders) * 100, 2)
    END AS mom_order_growth_pct
FROM growth_calculation
ORDER BY year DESC, month DESC;


-- ============================================================================
-- 7) COHORT RETENTION
-- ============================================================================
-- Cohorts answer: “When someone first buys in month X, how likely are they to
-- come back in month X+1, X+2, etc.?”

-- Query 7.1: Cohort Retention by First Purchase Month
WITH customer_first_purchase AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        MIN(o.order_date) AS first_purchase_date,
        DATEFROMPARTS(DATEPART(YEAR, MIN(o.order_date)), DATEPART(MONTH, MIN(o.order_date)), 1) AS cohort_month
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
),
customer_purchase_months AS (
    SELECT 
        cfp.customer_id,
        cfp.customer_name,
        cfp.cohort_month,
        DATEFROMPARTS(DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), 1) AS purchase_month,
        DATEDIFF(MONTH, cfp.cohort_month, DATEFROMPARTS(DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), 1)) AS months_since_cohort,
        SUM(o.order_total) AS monthly_revenue
    FROM customer_first_purchase cfp
    INNER JOIN orders o ON cfp.customer_id = o.customer_id
    GROUP BY cfp.customer_id, cfp.customer_name, cfp.cohort_month, DATEFROMPARTS(DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), 1)
),
cohort_summary AS (
    SELECT 
        cohort_month,
        months_since_cohort,
        COUNT(DISTINCT customer_id) AS customers_active,
        ROUND(SUM(monthly_revenue), 2) AS cohort_revenue,
        ROUND(AVG(monthly_revenue), 2) AS avg_monthly_revenue
    FROM customer_purchase_months
    GROUP BY cohort_month, months_since_cohort
),
cohort_size AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_first_purchase
    GROUP BY cohort_month
)
SELECT 
    cs.cohort_month,
    cs.cohort_size,
    co.months_since_cohort,
    COALESCE(co.customers_active, 0) AS customers_active,
    ROUND(COALESCE(co.customers_active, 0) * 100.0 / cs.cohort_size, 2) AS retention_rate_pct,
    COALESCE(co.cohort_revenue, 0) AS cohort_revenue,
    COALESCE(co.avg_monthly_revenue, 0) AS avg_monthly_revenue
FROM cohort_size cs
LEFT JOIN cohort_summary co ON cs.cohort_month = co.cohort_month
ORDER BY cs.cohort_month DESC, co.months_since_cohort;


-- Query 7.2: Repeat Rate by Cohort
WITH customer_cohorts AS (
    SELECT 
        c.customer_id,
        DATEFROMPARTS(DATEPART(YEAR, MIN(o.order_date)), DATEPART(MONTH, MIN(o.order_date)), 1) AS cohort_month,
        COUNT(DISTINCT o.order_id) AS total_purchases
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
)
SELECT 
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_customers,
    SUM(CASE WHEN total_purchases = 1 THEN 1 ELSE 0 END) AS one_time_buyers,
    SUM(CASE WHEN total_purchases > 1 THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(SUM(CASE WHEN total_purchases > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT customer_id), 2) AS repeat_rate_pct,
    ROUND(AVG(CAST(total_purchases AS FLOAT)), 2) AS avg_purchases_per_customer,
    MAX(total_purchases) AS max_purchases,
    MIN(total_purchases) AS min_purchases
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month DESC;


-- ============================================================================
-- 8) SEASONALITY + DAY-OF-WEEK PATTERNS
-- ============================================================================
-- These are lightweight “behavior” views: which months/quarters are strong,
-- and whether weekends behave differently from weekdays.

-- Query 8.1: Seasonal Patterns by Quarter/Month
WITH quarterly_sales AS (
    SELECT 
        DATEPART(YEAR, o.order_date) AS year,
        DATEPART(QUARTER, o.order_date) AS quarter,
        DATEPART(MONTH, o.order_date) AS month,
        DATENAME(MONTH, o.order_date) AS month_name,
        COUNT(DISTINCT o.order_id) AS order_count,
        COUNT(DISTINCT o.customer_id) AS unique_customers,
        SUM(o.order_total) AS total_revenue,
        AVG(o.order_total) AS avg_order_value
    FROM orders o
    GROUP BY DATEPART(YEAR, o.order_date), DATEPART(QUARTER, o.order_date), DATEPART(MONTH, o.order_date), DATENAME(MONTH, o.order_date)
),
season_averages AS (
    SELECT 
        quarter,
        month,
        month_name,
        ROUND(AVG(total_revenue), 2) AS avg_quarterly_revenue,
        ROUND(AVG(order_count), 2) AS avg_orders_per_quarter
    FROM quarterly_sales
    GROUP BY quarter, month, month_name
)
SELECT 
    year,
    quarter,
    month,
    month_name,
    order_count,
    unique_customers,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_order_value, 2) AS avg_order_value,
    ROUND((total_revenue / NULLIF((SELECT SUM(order_total) FROM orders WHERE DATEPART(YEAR, order_date) = quarterly_sales.year), 0)) * 100, 2) AS pct_of_annual_revenue,
    sa.avg_quarterly_revenue,
    ROUND(total_revenue - sa.avg_quarterly_revenue, 2) AS variance_from_avg
FROM quarterly_sales qs
LEFT JOIN season_averages sa ON qs.quarter = sa.quarter AND qs.month = sa.month
ORDER BY year DESC, quarter DESC, month DESC;


-- Query 8.2: Weekday vs Weekend Patterns
WITH daily_patterns AS (
    SELECT 
        DATEPART(WEEKDAY, o.order_date) AS day_of_week,
        DATENAME(WEEKDAY, o.order_date) AS day_name,
        CASE 
            WHEN DATEPART(WEEKDAY, o.order_date) IN (1, 7) THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        CAST(o.order_date AS DATE) AS order_date,
        COUNT(DISTINCT o.order_id) AS daily_orders,
        COUNT(DISTINCT o.customer_id) AS daily_customers,
        SUM(o.order_total) AS daily_revenue
    FROM orders o
    GROUP BY DATEPART(WEEKDAY, o.order_date), DATENAME(WEEKDAY, o.order_date), CAST(o.order_date AS DATE)
),
day_aggregates AS (
    SELECT 
        day_of_week,
        day_name,
        day_type,
        COUNT(*) AS occurrences,
        ROUND(AVG(daily_orders), 2) AS avg_orders,
        ROUND(AVG(daily_customers), 2) AS avg_customers,
        ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue,
        ROUND(SUM(daily_revenue), 2) AS total_revenue,
        ROUND(MAX(daily_revenue), 2) AS peak_day_revenue,
        ROUND(MIN(daily_revenue), 2) AS low_day_revenue
    FROM daily_patterns
    GROUP BY day_of_week, day_name, day_type
)
SELECT 
    day_of_week,
    day_name,
    day_type,
    occurrences,
    avg_orders,
    avg_customers,
    avg_daily_revenue,
    total_revenue,
    peak_day_revenue,
    low_day_revenue,
    ROUND(avg_daily_revenue / (SELECT AVG(daily_avg) FROM (SELECT AVG(daily_revenue) AS daily_avg FROM daily_patterns GROUP BY CAST(order_date AS DATE)) AS t), 2) AS index_to_avg
FROM day_aggregates
ORDER BY day_of_week;


-- Query 8.3: Year-over-Year Seasonality by Month
WITH seasonal_data AS (
    SELECT 
        DATEPART(YEAR, o.order_date) AS year,
        DATEPART(MONTH, o.order_date) AS month,
        DATENAME(MONTH, o.order_date) AS month_name,
        SUM(o.order_total) AS monthly_revenue,
        COUNT(DISTINCT o.order_id) AS monthly_orders,
        COUNT(DISTINCT o.customer_id) AS monthly_customers
    FROM orders o
    GROUP BY DATEPART(YEAR, o.order_date), DATEPART(MONTH, o.order_date), DATENAME(MONTH, o.order_date)
),
pivot_prepared AS (
    SELECT 
        month,
        month_name,
        year,
        monthly_revenue,
        monthly_orders,
        monthly_customers
    FROM seasonal_data
)
SELECT 
    month,
    month_name,
    SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) THEN monthly_revenue ELSE 0 END) AS current_year_revenue,
    SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) - 1 THEN monthly_revenue ELSE 0 END) AS prior_year_revenue,
    SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) THEN monthly_orders ELSE 0 END) AS current_year_orders,
    SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) - 1 THEN monthly_orders ELSE 0 END) AS prior_year_orders,
    CASE 
        WHEN SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) - 1 THEN monthly_revenue ELSE 0 END) > 0
        THEN ROUND(((SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) THEN monthly_revenue ELSE 0 END) - SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) - 1 THEN monthly_revenue ELSE 0 END)) / SUM(CASE WHEN year = DATEPART(YEAR, GETDATE()) - 1 THEN monthly_revenue ELSE 0 END)) * 100, 2)
        ELSE NULL
    END AS yoy_growth_pct
FROM pivot_prepared
GROUP BY month, month_name
ORDER BY month;


-- ============================================================================
-- 9) CROSS-SELL / BUNDLE SIGNALS (BASIC MARKET BASKET)
-- ============================================================================
-- This is a simple “what gets bought together” pattern. It’s not a full
-- recommendation engine, but it’s a useful starting point.

-- Query 9.1: Frequently Purchased Together
WITH order_products AS (
    SELECT 
        o.order_id,
        p1.product_id AS product_1_id,
        p1.product_name AS product_1,
        p2.product_id AS product_2_id,
        p2.product_name AS product_2
    FROM orders o
    INNER JOIN order_items oi1 ON o.order_id = oi1.order_id
    INNER JOIN products p1 ON oi1.product_id = p1.product_id
    INNER JOIN order_items oi2 ON o.order_id = oi2.order_id
    INNER JOIN products p2 ON oi2.product_id = p2.product_id
    WHERE p1.product_id < p2.product_id
)
SELECT 
    product_1_id,
    product_1,
    product_2_id,
    product_2,
    COUNT(DISTINCT order_id) AS times_purchased_together,
    ROUND(COUNT(DISTINCT order_id) * 100.0 / (SELECT COUNT(DISTINCT order_id) FROM orders), 2) AS pct_of_all_orders
FROM order_products
GROUP BY product_1_id, product_1, product_2_id, product_2
HAVING COUNT(DISTINCT order_id) >= 3
ORDER BY times_purchased_together DESC;


-- Query 9.2: Segment Performance Comparison
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        COUNT(DISTINCT o.order_id) AS purchase_count,
        SUM(o.order_total) AS total_spent,
        AVG(o.order_total) AS avg_order_value,
        DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS customer_age_days,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name
),
segment_assignment AS (
    SELECT 
        *,
        CASE 
            WHEN purchase_count = 0 THEN 'No Purchases'
            WHEN purchase_count = 1 THEN 'One-Time Buyer'
            WHEN purchase_count BETWEEN 2 AND 5 THEN 'Regular Buyer'
            ELSE 'Loyal Customer'
        END AS customer_segment,
        CASE 
            WHEN DATEDIFF(DAY, last_order_date, GETDATE()) <= 30 THEN 'Active'
            WHEN DATEDIFF(DAY, last_order_date, GETDATE()) <= 90 THEN 'Dormant'
            ELSE 'Inactive'
        END AS activity_status
    FROM customer_spending
)
SELECT 
    customer_segment,
    activity_status,
    COUNT(*) AS customer_count,
    ROUND(AVG(purchase_count), 2) AS avg_purchases,
    ROUND(AVG(total_spent), 2) AS avg_customer_value,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value,
    ROUND(AVG(CAST(customer_age_days AS FLOAT)), 0) AS avg_customer_age_days
FROM segment_assignment
GROUP BY customer_segment, activity_status
ORDER BY customer_count DESC;


-- ============================================================================
-- 10) KPI / SCORECARD OUTPUTS
-- ============================================================================
-- These are the kinds of “one query” outputs you might feed into a dashboard.

-- Query 10.1: High-Level KPIs
SELECT 
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(o.order_total), 2) AS total_revenue,
    ROUND(AVG(o.order_total), 2) AS avg_order_value,
    ROUND(SUM(o.order_total) / COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
    ROUND(COUNT(DISTINCT o.order_id) / CAST(COUNT(DISTINCT c.customer_id) AS FLOAT), 2) AS orders_per_customer,
    ROUND(COUNT(DISTINCT o.customer_id) * 100.0 / COUNT(DISTINCT c.customer_id), 2) AS customer_conversion_pct,
    COUNT(DISTINCT p.product_id) AS total_products,
    COUNT(DISTINCT cat.category_id) AS total_categories,
    DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS days_of_operation,
    ROUND(SUM(o.order_total) / NULLIF(DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)), 0), 2) AS avg_daily_revenue
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN categories cat ON p.category_id = cat.category_id;


-- Query 10.2: Category Scorecard (Multi-metric benchmarking)
WITH category_metrics AS (
    SELECT 
        c.category_id,
        c.category_name,
        COUNT(DISTINCT p.product_id) AS product_count,
        COUNT(DISTINCT oi.order_id) AS order_count,
        COUNT(DISTINCT o.customer_id) AS customer_count,
        SUM(oi.quantity) AS total_units_sold,
        SUM(oi.quantity * oi.unit_price) AS total_revenue,
        AVG(oi.quantity * oi.unit_price) AS avg_transaction_value,
        ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT p.product_id), 2) AS revenue_per_product,
        MAX(o.order_date) AS last_sale_date
    FROM categories c
    INNER JOIN products p ON c.category_id = p.category_id
    INNER JOIN order_items oi ON p.product_id = oi.product_id
    INNER JOIN orders o ON oi.order_id = o.order_id
    GROUP BY c.category_id, c.category_name
),
category_ranks AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY order_count DESC) AS volume_rank,
        RANK() OVER (ORDER BY customer_count DESC) AS customer_reach_rank,
        RANK() OVER (ORDER BY avg_transaction_value DESC) AS transaction_value_rank
    FROM category_metrics
)
SELECT 
    category_id,
    category_name,
    product_count,
    order_count,
    customer_count,
    total_units_sold,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(avg_transaction_value, 2) AS avg_transaction_value,
    revenue_per_product,
    DATEDIFF(DAY, last_sale_date, GETDATE()) AS days_since_last_sale,
    revenue_rank,
    volume_rank,
    customer_reach_rank,
    transaction_value_rank,
    (revenue_rank + volume_rank + customer_reach_rank + transaction_value_rank) AS overall_performance_score
FROM category_ranks
ORDER BY overall_performance_score ASC;


-- ============================================================================
-- End of advanced analytics queries
-- ============================================================================
