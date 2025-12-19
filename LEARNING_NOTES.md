# SQL Learning Journey - E-Commerce Case Study

**Date Created:** December 10, 2025  
**Author:** Pedro24681  
**Repository:** sql-ecommerce-case-study

# SQL Learning Journey - E-Commerce Case Study

**Date Created:** December 10, 2025  
**Author:** Pedro24681  
**Repository:** sql-ecommerce-case-study

---

## Overview

This is basically my personal log of learning SQL through building this project. I started out pretty rough with SQL—doing a lot of trial and error—and over time I got more comfortable with the advanced stuff like window functions and CTEs. I'm documenting the concepts I picked up, the stuff that tripped me up along the way, and some of the queries I'm actually proud of. 
---

##  Concepts Mastered

### 1. **Window Functions**
Window functions transformed my approach to analytical queries. Rather than using subqueries for ranking and running totals, I now leverage the power of `ROW_NUMBER()`, `RANK()`, `DENSE_RANK()`, and `LAG()`/`LEAD()` functions.

**Key Learnings:**
- Partitioning data by specific columns to create "windows" of computation
- Using `ORDER BY` within window functions to establish sequence
- Calculating running totals, moving averages, and cumulative sums efficiently
- Identifying trends and comparing records within their partition

**Application in E-Commerce:**
- Customer purchase frequency rankings within each product category
- Month-over-month revenue growth comparisons
- Identifying the previous and next order for each customer

### 2. **Common Table Expressions (CTEs)**
CTEs have dramatically improved query readability and maintainability. They allow me to break complex logic into digestible, named subqueries.

**Key Learnings:**
- Writing single and multiple CTEs in a single query
- Recursive CTEs for hierarchical data (though not extensively used in this dataset)
- Building progressively complex logic layer by layer
- Improving code organization and debugging

**Application in E-Commerce:**
- Multi-stage customer segmentation pipelines
- Calculating intermediate metrics before final aggregation
- Creating reusable query patterns for business reporting

### 3. **Multi-Table Joins**
Mastering joins has been fundamental to extracting meaningful insights from relational data.

**Key Learnings:**
- Distinction between INNER, LEFT, RIGHT, and FULL OUTER joins
- CROSS JOINs for generating combinations
- Multiple consecutive joins with proper aliasing
- Avoiding cartesian products and managing join complexity
- Understanding the order of operations in multi-join scenarios

**Application in E-Commerce:**
- Connecting customers, orders, order items, and products
- Calculating metrics across dimensional and fact tables
- Creating comprehensive customer-product interaction matrices

### 4. **Aggregation & GROUP BY**
Advanced aggregation patterns have unlocked sophisticated business analysis capabilities.

**Key Learnings:**
- GROUP BY with multiple columns for hierarchical analysis
- HAVING clauses to filter aggregated results
- Combining COUNT, SUM, AVG, MAX, MIN, and custom expressions
- NULL handling in aggregations
- Using CASE statements within aggregate functions for conditional summation

**Application in E-Commerce:**
- Customer lifetime value calculations
- Category-wise sales performance
- Revenue distribution analysis
- Identifying high-value customer segments

### 5. **Business Analytics Techniques**
I've developed proficiency in translating business questions into SQL queries.

**Key Learnings:**
- Cohort analysis for understanding customer lifecycle
- RFM (Recency, Frequency, Monetary) segmentation
- Customer acquisition and retention metrics
- Product performance analysis and cross-selling opportunities
- Time-series analysis for seasonal trends
- Profitability analysis by segment

**Application in E-Commerce:**
- Identifying churn risk customers
- Calculating customer acquisition cost (CAC) and lifetime value (LTV)
- Discovering product affinity patterns
- Measuring marketing campaign effectiveness

---

## Challenges Overcome

### Challenge 1: Understanding Join Logic with Multiple Tables
**Problem:** Initial attempts to join 4+ tables resulted in duplicate rows and inflated metrics.

**Solution & Learning:**
- Realized that joining multiple fact tables can create cartesian products
- Learned to identify the granularity of each table (order vs. order items)
- Implemented proper aggregation before joining when necessary
- Used `GROUP BY` strategically to control the output grain

**Key Insight:** Always know what each row represents before joining.

### Challenge 2: Window Function Partition Complexity
**Problem:** Struggled with balancing `PARTITION BY` and `ORDER BY` clauses to achieve desired results.

**Solution & Learning:**
- Practiced decomposing the requirement: "What am I partitioning? What am I ordering?"
- Realized that `PARTITION BY` defines the "window" scope, while `ORDER BY` defines the sequence
- Tested queries incrementally, visualizing the intermediate results
- Learned when to use `ROWS BETWEEN` for precise window frame specification

**Key Insight:** Window functions are about perspective and scope—understand what you're analyzing within which context.

### Challenge 3: NULL Value Handling
**Problem:** Unexpected results when NULLs were present in calculations and aggregations.

**Solution & Learning:**
- Understood that NULL is "unknown," not zero
- Learned to use `COALESCE()`, `NULLIF()`, and conditional logic
- Recognized that `COUNT(*)` counts NULLs, but `COUNT(column)` doesn't
- Implemented `IS NULL` and `IS NOT NULL` checks appropriately

**Key Insight:** Never assume NULLs are handled automatically—be explicit.

### Challenge 4: Query Performance with Large Datasets
**Problem:** Queries that worked on sample data became sluggish with full datasets.

**Solution & Learning:**
- Started using EXPLAIN plans to understand query execution
- Learned the importance of filtering early (WHERE before GROUP BY)
- Discovered that CTEs can improve readability but may impact performance
- Practiced writing efficient subqueries vs. JOINs based on context

**Key Insight:** As data scales, query structure matters. Optimize for the database, not just readability.

### Challenge 5: Business Logic Translation
**Problem:** Business stakeholders' verbal requirements didn't always align with my SQL interpretation.

**Solution & Learning:**
- Started asking clarifying questions: "Is this customer-level or transaction-level?"
- Created documentation for metric definitions
- Built query templates for common requests
- Validated results against expected ranges and spot-checked manually

**Key Insight:** SQL is precise—ambiguity in requirements leads to incorrect analyses.

---

## Key Business Insights Discovered

### Insight 1: Customer Concentration
Discovered that a small percentage of customers (top 10%) generate a disproportionate portion of revenue—approximately 60-70% of total sales.

**SQL Technique Used:** Window functions (percentile ranking) combined with aggregation and filtering.

**Business Impact:** Recommended implementing a VIP customer program to retain high-value segments.

### Insight 2: Seasonal Product Demand Patterns
Identified clear seasonal trends in product categories, with certain categories peaking during specific months.

**SQL Technique Used:** Time-series analysis with date functions and month-over-month comparisons.

**Business Impact:** Enabled better inventory planning and targeted promotional campaigns.

### Insight 3: Product Category Profitability Variance
Not all categories contribute equally to profitability. Some categories have high volume but low margins, while others have lower volume but superior profitability.

**SQL Technique Used:** Multi-table joins linking products, orders, and detailed pricing; aggregation with CASE statements for conditional calculations.

**Business Impact:** Insights used to optimize product mix and category-level pricing strategies.

### Insight 4: Customer Order Value Growth Trajectory
Customers who place multiple orders show increasing order values over time, particularly in their first 6 months.

**SQL Technique Used:** Window functions to track sequential order metrics by customer.

**Business Impact:** Identified the critical period for customer engagement and upselling opportunities.

### Insight 5: Cross-Selling Opportunities
Certain product pairs are frequently purchased together, suggesting strong cross-selling potential.

**SQL Technique Used:** Self-joins and COUNT(DISTINCT) to identify co-purchase patterns.

**Business Impact:** Recommendations provided for product bundling and recommendation algorithms.

### Insight 6: Regional Performance Disparity
Geographic regions show significant variation in sales volume, average order value, and customer retention.

**SQL Technique Used:** CTEs for cohort segmentation; multi-dimensional aggregation.

**Business Impact:** Enabled regional targeting strategies and resource allocation decisions.

---

## Queries I'm Most Proud Of

### Query 1: Customer RFM Segmentation
```sql
-- A comprehensive RFM analysis that segments customers into strategic groups
-- Uses CTEs for clarity and window functions for ranking
```
**Why I'm Proud:** This query elegantly combines recency, frequency, and monetary value calculations into actionable customer segments. It demonstrates CTE organization and window function mastery.

**Business Value:** Enables targeted marketing strategies based on customer behavior patterns.

### Query 2: Month-over-Month Revenue Growth Analysis
```sql
-- Calculates growth rates while handling edge cases and NULL values
-- Uses window functions with LAG() for comparison across time periods
```
**Why I'm Proud:** The query handles the complexity of comparing non-adjacent time periods and calculating growth rates while maintaining data accuracy. It exemplifies clean window function usage.

**Business Value:** Provides actionable insights into business momentum and trend direction.

### Query 3: Product Category Affinity Matrix
```sql
-- Identifies which products are purchased together
-- Uses multi-table joins and correlation analysis
```
**Why I'm Proud:** This query demonstrates sophisticated join logic across multiple tables and creative use of aggregation to uncover hidden patterns in customer behavior.

**Business Value:** Directly supports product recommendation engines and bundling strategies.

### Query 4: Customer Cohort Retention Analysis
```sql
-- Tracks cohorts of customers from acquisition through subsequent periods
-- Uses date arithmetic and conditional aggregation
```
**Why I'm Proud:** This complex analytical query segments customers by acquisition month and then tracks their retention across subsequent periods. It required understanding customer lifecycle dynamics and implementing creative SQL logic.

**Business Value:** Measures customer retention effectiveness and identifies retention risk periods.

### Query 5: Profitability Deep Dive
```sql
-- Multi-dimensional profitability analysis by customer, product, and category
-- Combines multiple aggregation levels and CASE statement logic
```
**Why I'm Proud:** This query integrates margin calculations, customer lifetime value, and product profitability into a single, cohesive analysis. It demonstrates advanced aggregation and conditional logic.

**Business Value:** Provides comprehensive profitability visibility for strategic decision-making.

---

## Challenges Faced (Ongoing)

### 1. Balancing Readability vs. Performance
**Challenge:** More readable CTEs sometimes result in less efficient query plans.

**Current Approach:** Profile critical queries and optimize high-impact ones, accepting minor performance trade-offs for maintainability in less critical queries.

### 2. Handling Complex Business Requirements
**Challenge:** Real-world requirements often have edge cases and special conditions that complicate SQL logic.

**Current Approach:** Document all business rules, create test cases for edge cases, and validate with stakeholders.

### 3. Working with Incomplete or Dirty Data
**Challenge:** Real datasets contain gaps, duplicates, and inconsistencies.

**Current Approach:** Implement data quality checks, document assumptions, and communicate limitations to stakeholders.

### 4. Scaling Analysis as Data Grows
**Challenge:** Query optimization becomes increasingly important as datasets expand.

**Current Approach:** Use EXPLAIN ANALYZE for profiling, implement strategic indexing (when accessible), and redesign inefficient queries.

---

## Advanced SQL Techniques Mastered

### 1. **Advanced Window Functions**
- `ROW_NUMBER()` for unique row identification within partitions
- `RANK()` and `DENSE_RANK()` for handling ties differently
- `LAG()` and `LEAD()` for accessing adjacent rows
- `FIRST_VALUE()` and `LAST_VALUE()` for boundary values
- `NTILE()` for quantile segmentation

### 2. **Complex CTEs**
- Multiple CTEs building on each other
- Using CTEs for intermediate metric calculation
- Recursive CTEs for hierarchical data exploration
- Named window specifications within CTEs

### 3. **Sophisticated Joins**
- Proper handling of many-to-many relationships
- Understanding join order and impact on results
- Creative join conditions beyond simple key matching
- CROSS JOINs for generating comparison sets

### 4. **Advanced Aggregation**
- Conditional aggregation with CASE statements
- FILTER clauses for selective aggregation
- Multiple aggregation levels within a single query
- Aggregate functions within aggregate functions (filtered aggregates)

### 5. **Date and Time Analysis**
- Date arithmetic for period comparisons
- EXTRACT functions for temporal analysis
- Handling fiscal vs. calendar periods
- Time-series gap identification and filling

---

## Future Learning Goals

### 1. **SQL Performance Optimization**
- Deepen understanding of query execution plans
- Learn indexing strategies and their impact
- Master partitioning techniques for large tables
- Explore materialized views for performance improvement

### 2. **Advanced Analytics**
- Implement statistical functions (standard deviation, correlation)
- Explore predictive analytics within SQL
- Master time-series forecasting techniques
- Develop more sophisticated cohort analyses

### 3. **Data Integration & Transformation**
- Master complex data transformation pipelines
- Implement slowly changing dimension (SCD) logic
- Develop ETL validation queries
- Create data quality monitoring SQL

### 4. **Database-Specific Features**
- Explore PostgreSQL-specific capabilities (JSON, arrays, JSONB)
- Learn advanced T-SQL or Oracle-specific functions
- Understand database-specific optimization techniques
- Master transaction and locking mechanisms

### 5. **Reporting & Visualization Integration**
- Develop queries specifically optimized for BI tools
- Create reusable reporting templates
- Master parameter-driven queries
- Learn to structure data for optimal dashboard performance

### 6. **Machine Learning Integration**
- Understand how to prepare data for ML models using SQL
- Explore feature engineering at scale
- Learn prediction and model scoring in SQL
- Develop monitoring queries for model performance

---

## Personal Growth Summary

| Aspect | Beginning | Current | Goal |
|--------|-----------|---------|------|
| Query Complexity | Basic SELECT, single table | Multi-table joins, CTEs, window functions | Advanced analytics, optimization |
| Problem-Solving | Trial and error | Structured approach with testing | Intuitive optimization |
| Code Organization | Lengthy, hard to read | Well-structured with CTEs | Elegant, performance-optimized |
| Business Understanding | Surface-level | Deep analytical insights | Predictive and strategic analysis |
| Performance Awareness | Not considered | Actively profiling | Proactive optimization |

---

## 🎬 Conclusion

This whole project has been a game changer for me in terms of SQL skills. I went from just doing basic SELECT statements to actually building complex queries that pull meaningful insights from data. It's wild how much window functions and CTEs opened up once I really understood how to use them. 

The challenges I hit along the way—especially dealing with joins that multiplied my rows, or realizing NULL doesn't mean zero—those stuck with me. They weren't just "oh that's how SQL works" moments; they actually changed how I think about problems and made me ask better questions before I write code.

I'm definitely going to keep pushing on this. I want to get better at optimization, dive deeper into advanced analytics, and figure out how to use SQL as a real strategic tool for businesses, not just a way to pull data.  

The biggest thing I learned?  SQL is less about memorizing syntax and more about understanding the *shape* of your data and what you're actually trying to ask it. Additionally, the SUPER biggest thing I learned (or re-learned) was how complicated github formatting can be for repositories, given the fact that this has taken up most of my time. You'd think I would have spent more time on the SQL portion of the whole thing.
---

## Last Updated
December 19, 2025 - Initial comprehensive learning documentation
