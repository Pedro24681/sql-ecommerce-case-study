# SQL Queries

This file lists the SQL queries I wrote for this project, with runnable examples and brief comments. The corresponding plain language descriptions are in `QUERY_DESCRIPTIONS.md`.


# Total Revenue by Customer

```sql
-- Sum of all line totals per customer
SELECT
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  SUM(od.line_total) AS total_revenue
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Order_Details od ON od.order_id = o.order_id
GROUP BY c.customer_id, customer_name
ORDER BY total_revenue DESC;
