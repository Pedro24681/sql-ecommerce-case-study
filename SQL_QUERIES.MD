# SQL Queries

Here's a collection of the SQL queries I put together for this project.  Each one has a quick runnable example and some notes on what it's doing.  If you want more explanation on what the queries are actually answering, check out `QUERY_DESCRIPTIONS.md`.
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
