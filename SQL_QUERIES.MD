# E-Commerce SQL Queries

This document contains a comprehensive collection of SQL queries used for analyzing and managing e-commerce data. Each query includes detailed explanations of its purpose and functionality.

## Table of Contents
1. [Customer Analysis Queries](#customer-analysis-queries)
2. [Sales and Revenue Queries](#sales-and-revenue-queries)
3. [Product Analysis Queries](#product-analysis-queries)
4. [Order Management Queries](#order-management-queries)
5. [Advanced Analytics Queries](#advanced-analytics-queries)

---

## Customer Analysis Queries

### 1. Find Top Customers by Purchase Value
**Purpose:** Identify the most valuable customers based on their total purchase amount.

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    COUNT(o.order_id) as total_orders,
    SUM(o.order_total) as lifetime_value,
    AVG(o.order_total) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email
ORDER BY lifetime_value DESC
LIMIT 20;
```

**Explanation:** This query joins the customers table with the orders table to calculate key metrics for each customer. It shows the total number of orders, lifetime value (sum of all orders), and average order value. The LEFT JOIN ensures that customers with no orders are still included. Results are sorted by lifetime value in descending order to show top customers first.

### 2. Identify Inactive Customers
**Purpose:** Find customers who haven't made a purchase in the last 90 days.

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    MAX(o.order_date) as last_order_date,
    DATEDIFF(DAY, MAX(o.order_date), GETDATE()) as days_inactive
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email
HAVING DATEDIFF(DAY, MAX(o.order_date), GETDATE()) > 90
    OR MAX(o.order_date) IS NULL
ORDER BY days_inactive DESC;
```

**Explanation:** This query identifies customers who haven't placed an order recently. It uses a LEFT JOIN to include customers without any orders and the HAVING clause to filter for those inactive beyond 90 days. The DATEDIFF function calculates the number of days since their last purchase, helping to prioritize re-engagement efforts.

### 3. Calculate Customer Segmentation by Purchase Frequency
**Purpose:** Segment customers into frequency tiers (frequent, regular, occasional).

```sql
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(o.order_id) as purchase_count,
    CASE 
        WHEN COUNT(o.order_id) >= 10 THEN 'VIP'
        WHEN COUNT(o.order_id) >= 5 THEN 'Regular'
        WHEN COUNT(o.order_id) >= 1 THEN 'Occasional'
        ELSE 'Never Purchased'
    END as customer_tier
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY purchase_count DESC;
```

**Explanation:** This query uses a CASE statement to categorize customers based on their purchase frequency. It creates meaningful segments that can be used for targeted marketing campaigns. VIP customers (10+ purchases) might receive special promotions, while occasional buyers could be targeted with reactivation campaigns.

---

## Sales and Revenue Queries

### 1. Monthly Revenue Analysis
**Purpose:** Track revenue trends across months to identify seasonal patterns.

```sql
SELECT 
    YEAR(o.order_date) as year,
    MONTH(o.order_date) as month,
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) as month_start,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.order_total) as monthly_revenue,
    AVG(o.order_total) as avg_order_value
FROM orders o
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year DESC, month DESC;
```

**Explanation:** This query aggregates sales data by month to reveal revenue trends and seasonality. It shows the number of orders, unique customers, total revenue, and average order value for each month. This information is crucial for forecasting, inventory planning, and identifying peak sales periods. The DATEFROMPARTS function makes the month clearer for reporting.

### 2. Daily Revenue with Running Total
**Purpose:** Monitor daily performance with a cumulative revenue view.

```sql
SELECT 
    CAST(o.order_date AS DATE) as order_date,
    COUNT(o.order_id) as daily_orders,
    SUM(o.order_total) as daily_revenue,
    SUM(SUM(o.order_total)) OVER (ORDER BY CAST(o.order_date AS DATE)) as running_total
FROM orders o
GROUP BY CAST(o.order_date AS DATE)
ORDER BY order_date DESC;
```

**Explanation:** This query uses window functions (OVER clause) to calculate a running total of revenue across days. The window function accumulates the daily revenue as we move through the dates, providing a cumulative view. This is useful for tracking progress toward targets and identifying acceleration or deceleration in sales.

### 3. Revenue by Product Category
**Purpose:** Analyze which product categories generate the most revenue.

```sql
SELECT 
    p.category,
    COUNT(DISTINCT oi.order_id) as orders_containing_category,
    COUNT(oi.order_item_id) as total_items_sold,
    SUM(oi.quantity) as total_quantity,
    SUM(oi.unit_price * oi.quantity) as category_revenue,
    AVG(oi.unit_price) as avg_item_price,
    ROUND(SUM(oi.unit_price * oi.quantity) / COUNT(DISTINCT oi.order_id), 2) as avg_revenue_per_order
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;
```

**Explanation:** This query combines order items with product information to reveal category performance. It calculates total revenue, number of items sold, and average item price per category. Understanding category profitability helps with inventory allocation and promotional strategy decisions.

---

## Product Analysis Queries

### 1. Find Top Performing Products
**Purpose:** Identify best-selling and highest-revenue generating products.

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    COUNT(DISTINCT oi.order_id) as orders_with_product,
    SUM(oi.quantity) as total_units_sold,
    SUM(oi.quantity * oi.unit_price) as product_revenue,
    ROUND(AVG(oi.quantity * oi.unit_price / oi.quantity), 2) as avg_price_paid,
    ROUND(RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity * oi.unit_price) DESC), 0) as rank_in_category
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_price
ORDER BY product_revenue DESC
LIMIT 50;
```

**Explanation:** This query identifies your best-performing products by revenue. The window function RANK() OVER partitions results by category, showing how each product ranks within its own category. This helps identify star products, potential bestsellers, and underperformers. The LIMIT clause focuses on the top 50 products.

### 2. Identify Slow-Moving Inventory
**Purpose:** Find products that rarely sell or haven't sold recently.

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    COUNT(oi.order_item_id) as times_ordered,
    SUM(oi.quantity) as total_units_sold,
    MAX(oi.order_date) as last_sale_date,
    DATEDIFF(DAY, MAX(oi.order_date), GETDATE()) as days_since_last_sale
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_price
HAVING COUNT(oi.order_item_id) < 5 OR MAX(oi.order_date) < DATEADD(MONTH, -3, GETDATE())
ORDER BY days_since_last_sale DESC;
```

**Explanation:** This query helps identify inventory management issues by finding products that sell slowly or haven't sold in months. The HAVING clause filters for products with fewer than 5 orders or no sales in the last 3 months. This information is valuable for clearance decisions and inventory optimization.

### 3. Product Performance with Price Elasticity
**Purpose:** Analyze how price changes might affect product demand.

```sql
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.unit_price,
    COUNT(oi.order_item_id) as times_ordered,
    SUM(oi.quantity) as total_quantity,
    ROUND(SUM(oi.quantity) / NULLIF(COUNT(oi.order_item_id), 0), 2) as avg_quantity_per_order,
    ROUND(SUM(oi.quantity * oi.unit_price) / SUM(oi.quantity), 2) as avg_revenue_per_unit
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.unit_price
ORDER BY total_quantity DESC;
```

**Explanation:** This query provides insights into product demand patterns. The average quantity per order indicates how many units customers typically buy. This metric can help identify whether a product would benefit from bundling, volume discounts, or price increases. Products with higher quantities per order may have greater price elasticity.

---

## Order Management Queries

### 1. Order Status Summary
**Purpose:** Get an overview of orders at each stage of the fulfillment process.

```sql
SELECT 
    o.order_status,
    COUNT(o.order_id) as order_count,
    COUNT(DISTINCT o.customer_id) as unique_customers,
    SUM(o.order_total) as status_total_value,
    MIN(o.order_date) as earliest_order,
    MAX(o.order_date) as latest_order,
    AVG(DATEDIFF(DAY, o.order_date, GETDATE())) as avg_age_in_days
FROM orders o
GROUP BY o.order_status
ORDER BY order_count DESC;
```

**Explanation:** This query provides an overview of your order pipeline, showing how many orders are in each status (pending, shipped, delivered, etc.). It reveals bottlenecks in the fulfillment process and the average age of orders in each status, helping identify orders that need attention or are delayed.

### 2. Orders with Items and Customer Details
**Purpose:** Get detailed order information including customer and product details.

```sql
SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_name,
    c.email,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) as item_total,
    o.order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_date DESC;
```

**Explanation:** This query joins four tables to provide a complete view of orders. It shows what customers ordered, what they paid, and current status. This is useful for customer service inquiries, order fulfillment, and understanding purchase patterns. The query can be filtered by date, customer, or status as needed.

### 3. Calculate Order Processing Time
**Purpose:** Measure how long orders take to process and ship.

```sql
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.shipped_date,
    o.delivered_date,
    DATEDIFF(DAY, o.order_date, o.shipped_date) as processing_days,
    DATEDIFF(DAY, o.shipped_date, o.delivered_date) as shipping_days,
    DATEDIFF(DAY, o.order_date, o.delivered_date) as total_fulfillment_days
FROM orders o
WHERE o.order_status = 'Delivered'
ORDER BY total_fulfillment_days DESC;
```

**Explanation:** This query measures operational efficiency by calculating how many days orders spend in processing and shipping stages. Long processing times might indicate bottlenecks in order fulfillment, while long shipping times could indicate carrier issues. These metrics are important for setting customer expectations and improving operations.

---

## Advanced Analytics Queries

### 1. Customer Lifetime Value (CLV) with Cohort Analysis
**Purpose:** Analyze customer value by cohort (acquisition group) and track retention.

```sql
SELECT 
    YEAR(MIN(o.order_date)) as cohort_year,
    MONTH(MIN(o.order_date)) as cohort_month,
    COUNT(DISTINCT o.customer_id) as cohort_size,
    SUM(o.order_total) as cohort_revenue,
    ROUND(AVG(o.order_total), 2) as avg_customer_value,
    ROUND(SUM(o.order_total) / COUNT(DISTINCT o.customer_id), 2) as ltv,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(COUNT(DISTINCT o.order_id) / CAST(COUNT(DISTINCT o.customer_id) AS FLOAT), 2) as avg_orders_per_customer
FROM orders o
GROUP BY YEAR(MIN(o.order_date)), MONTH(MIN(o.order_date))
ORDER BY cohort_year DESC, cohort_month DESC;
```

**Explanation:** This query segments customers by their first purchase date (cohort) and calculates value metrics for each cohort. This helps identify whether newer customers are as valuable as older ones and reveals trends in customer acquisition quality. The CLV (Lifetime Value) per customer shows the average total revenue from each cohort member.

### 2. RFM Segmentation (Recency, Frequency, Monetary)
**Purpose:** Create an RFM model to segment customers for targeted campaigns.

```sql
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.email,
        MAX(o.order_date) as last_purchase_date,
        DATEDIFF(DAY, MAX(o.order_date), GETDATE()) as recency_days,
        COUNT(o.order_id) as frequency,
        SUM(o.order_total) as monetary_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.email
)
SELECT 
    customer_id,
    customer_name,
    email,
    recency_days,
    frequency,
    monetary_value,
    NTILE(5) OVER (ORDER BY recency_days DESC) as recency_score,
    NTILE(5) OVER (ORDER BY frequency ASC) as frequency_score,
    NTILE(5) OVER (ORDER BY monetary_value ASC) as monetary_score
FROM customer_metrics
ORDER BY recency_score DESC, frequency_score DESC, monetary_score DESC;
```

**Explanation:** The RFM model is a powerful customer segmentation technique. Recency measures how recently a customer bought (lower is better), Frequency counts how often they buy, and Monetary value is their total spending. Each metric is scored 1-5, creating 125 possible segments. High scores (5,5,5) identify your best customers, while low scores indicate at-risk customers needing re-engagement.

### 3. Product Bundle Recommendations
**Purpose:** Find frequently co-purchased products to create bundle suggestions.

```sql
SELECT TOP 50
    oi1.product_id as product_a,
    p1.product_name as product_a_name,
    oi2.product_id as product_b,
    p2.product_name as product_b_name,
    COUNT(DISTINCT oi1.order_id) as times_co_purchased,
    ROUND(
        COUNT(DISTINCT oi1.order_id) * 100.0 / 
        (SELECT COUNT(DISTINCT order_id) FROM order_items WHERE product_id = oi1.product_id),
        2
    ) as co_purchase_percentage
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY oi1.product_id, p1.product_name, oi2.product_id, p2.product_name
ORDER BY times_co_purchased DESC;
```

**Explanation:** This query identifies products frequently purchased together by joining order items with themselves. The co-purchase percentage shows what percentage of buyers of Product A also buy Product B, revealing natural bundles. This information is invaluable for cross-selling, upselling, and promotional strategy.

### 4. Customer Churn Prediction - Repeat Purchase Likelihood
**Purpose:** Identify customers at risk of churning based on purchase patterns.

```sql
WITH purchase_intervals AS (
    SELECT 
        o.customer_id,
        LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date) as prev_order_date,
        o.order_date as current_order_date,
        DATEDIFF(DAY, LAG(o.order_date) OVER (PARTITION BY o.customer_id ORDER BY o.order_date), o.order_date) as days_since_last_purchase
    FROM orders o
)
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    COUNT(DISTINCT pi.current_order_date) as total_orders,
    ROUND(AVG(pi.days_since_last_purchase), 0) as avg_days_between_purchases,
    MAX(pi.current_order_date) as last_purchase_date,
    DATEDIFF(DAY, MAX(pi.current_order_date), GETDATE()) as days_since_last_purchase,
    CASE 
        WHEN DATEDIFF(DAY, MAX(pi.current_order_date), GETDATE()) > ROUND(AVG(pi.days_since_last_purchase), 0) * 1.5 THEN 'At Risk'
        WHEN DATEDIFF(DAY, MAX(pi.current_order_date), GETDATE()) > ROUND(AVG(pi.days_since_last_purchase), 0) THEN 'Warning'
        ELSE 'Active'
    END as churn_risk
FROM purchase_intervals pi
JOIN customers c ON pi.customer_id = c.customer_id
WHERE pi.days_since_last_purchase IS NOT NULL
GROUP BY c.customer_id, c.customer_name, c.email
HAVING MAX(pi.current_order_date) < DATEADD(MONTH, -1, GETDATE())
ORDER BY days_since_last_purchase DESC;
```

**Explanation:** This advanced query uses window functions (LAG) to calculate the time between purchases for each customer. It identifies those whose current gap since purchase is longer than their historical average, flagging them as "At Risk" or "Warning." This enables proactive retention campaigns before customers are truly lost.

---

## Usage Tips

- **Performance**: Add WHERE clauses and specific date ranges to queries to improve performance on large datasets
- **Customization**: Modify date thresholds (90 days, 3 months, etc.) based on your business cycle
- **Integration**: These queries can be wrapped in stored procedures or views for easier access
- **Monitoring**: Run these queries regularly and track results over time to identify trends
- **Testing**: Always test queries on a development environment before running on production data

---

*Last Updated: 2025-12-19*
*Repository: Pedro24681/sql-ecommerce-case-study*
