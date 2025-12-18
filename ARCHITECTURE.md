# System Architecture & Design

## Overview

This document explains how the E-Commerce SQL Case Study is structured from a “systems + analytics” point of view. The goal isn’t to pretend this is a full production platform—it’s to show that the project is designed intentionally: the schema matches business reality, the queries scale cleanly, and the analysis patterns are reusable.

What this demonstrates:
- Data modeling decisions (normalized core + analytics-friendly joins)
- How the SQL files build from setup → core questions → advanced analytics
- How you’d think about performance, quality controls, and future scaling


## Design philosophy

### Core principles

1. **Data integrity first** — enforce correctness using constraints and clean relationships  
2. **Query performance matters** — design for analytics workloads (indexes, join paths, filters)  
3. **Maintainability** — a clear structure that’s easy to follow and extend  
4. **Scalability** — patterns that still work when data volume grows  
5. **Business alignment** — tables represent real entities and real workflows

### Design goals

- **Analytics-friendly structure**: supports aggregation-heavy queries (revenue, CLV, cohorts)
- **Normalized foundation**: avoids redundant data and keeps updates reliable
- **Readable documentation**: consistent naming + docs where decisions are explained
- **Reproducible setup**: scripts create the same environment every time
- **“Portfolio production-ready”**: constraints, indexing, and realistic query patterns


## Architectural layers

### 1) Data storage layer

**Purpose:** reliable, persistent storage with transactional consistency.

┌─────────────────────────────────────────────────┐
│ DATABASE MANAGEMENT SYSTEM │
│ │
│ MySQL 8.0+ / PostgreSQL 12+ │
│ - ACID transactions │
│ - Referential integrity │
│ - Index management │
│ - Query optimization │
└─────────────────────────────────────────────────┘


**Key components**
- Transactional engine (ex: InnoDB on MySQL)
- B-tree indexes on PKs and common filter/join columns
- Foreign keys to enforce relationships
- Optional generated / calculated columns (ex: line totals)

**Why this makes sense**
- MySQL / PostgreSQL are common and interview-relevant
- Constraints catch data issues early (instead of silently producing wrong results)
- A predictable index strategy helps analytics queries remain fast


### 2) Data model layer

**Purpose:** represent business entities in a way that supports both correctness and analysis.

┌─────────────────────────────────────────────────┐
│ DATA MODEL LAYER │
│ │
│ ┌─────────────┐ ┌─────────────┐ │
│ │ Dimension │ │ Fact │ │
│ │ Tables │◄────────┤ Tables │ │
│ └─────────────┘ └─────────────┘ │
│ - Customers - Orders │
│ - Products - Order_Details │
└─────────────────────────────────────────────────┘


**Design pattern:** hybrid star-style analytics on top of a normalized base.

**Dimension tables (descriptive attributes)**
- `Customers` — who is buying?
- `Products` — what is being sold?

**Fact tables (events + measures)**
- `Orders` — transaction headers
- `Order_Details` — line-item details

**Benefits**
- Simple join paths (easy for analysts and BI tools)
- Fast rollups for KPIs (SUM/AVG/COUNT)
- The model stays understandable even as queries get complex


### 3) Business logic layer

**Purpose:** turn raw transactions into answers a business would care about.

┌─────────────────────────────────────────────────┐
│ BUSINESS LOGIC │
│ │
│ ┌─────────────────┐ ┌─────────────────┐ │
│ │ SQL Queries │ │ CTEs + Windows │ │
│ └─────────────────┘ └─────────────────┘ │
│ │
│ Examples: │
│ - RFM / churn risk │
│ - Cohort retention │
│ - Time-series trends │
│ - Product performance │
└─────────────────────────────────────────────────┘


**How queries are organized**
- `01_schema_creation.sql` — tables, constraints, keys
- `02_business_questions.sql` — the core business questions
- `03_advanced_analytics.sql` — additional “analyst toolkit” patterns

**Complexity progression**
1) Aggregations → 2) multi-table joins → 3) window functions → 4) multi-CTE pipelines


### 4) Presentation layer

**Purpose:** make the results understandable and useful to someone who isn’t reading SQL.

┌─────────────────────────────────────────────────┐
│ PRESENTATION │
│ │
│ Query Results → Documentation → Insights │
│ │
│ - SAMPLE_OUTPUTS.md │
│ - QUERIES_GUIDE.md │
│ - CASE_STUDY_REPORT.md │
└─────────────────────────────────────────────────┘


The goal here is “stakeholder readability”: what was asked, how it was answered, and what the results suggest.


## Data flow architecture

### End-to-end journey

┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│ CSV Files │──────►│ Database │──────►│ SQL Queries │
└──────────────┘ └──────────────┘ └──────────────┘
Raw input Structured Analytics output
storage + rules
│
▼
┌──────────────┐
│ Constraints │
│ Indexes │
│ Relations │
└──────────────┘

### What happens at each step

**1) Ingestion**
- CSV files are loaded using setup / insert scripts
- Constraints validate data as it is inserted
- Foreign keys enforce relationships between entities

**2) Storage**
- Tables are normalized to reduce redundancy
- Indexes support joins and common filters
- Core date fields support auditing and trend analysis

**3) Processing**
- Business questions are answered using SQL
- CTEs break complex logic into readable steps
- Window functions enable ranking, retention, and trend analysis

**4) Output**
- Results are returned as structured tables
- Outputs are documented in markdown files
- Findings are translated into business takeaways


## Analytical approach

### Pattern 1: Multi-level CTE pipelines

Use this pattern when a problem requires multiple stages of calculation, such as computing base metrics, applying scoring logic, and then segmenting results.

```sql
WITH base_metrics AS (
    -- Step 1: compute base metrics
    SELECT ...
),
scored_data AS (
    -- Step 2: apply scoring logic
    SELECT ..., metrics FROM base_metrics
),
final_segmentation AS (
    -- Step 3: segment into business categories
    SELECT ..., scores FROM scored_data
)
SELECT * FROM final_segmentation;
```

Why this pattern is useful:

- Reads top-to-bottom like a workflow

-Easier to debug than deeply nested subqueries

- Intermediate results can be validated independently

- Examples in this project:

- RFM and churn scoring

- Period-over-period comparisons

- Cohort retention analysis

### Pattern 2: Window Functions

Window functions are used for ranking, running totals, and comparing values across time without collapsing rows.

SELECT 
    order_date,
    revenue,
    LAG(revenue) OVER (ORDER BY order_date) AS prev_revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM daily_sales;

Why this matters:

- Avoids expensive self-joins

- Preserves row-level detail

- Enables advanced analytics in a single query

- Used in this project for:

- Customer purchase sequences

- Product rankings within categories

- Month-over-month and year-over-year trends

### Pattern 3: Conditional aggregation

Conditional aggregation allows multiple business metrics to be calculated in a single pass

SELECT 
    category,
    SUM(CASE WHEN year = 2024 THEN revenue ELSE 0 END) AS revenue_2024,
    SUM(CASE WHEN year = 2025 THEN revenue ELSE 0 END) AS revenue_2025,
    COUNT(CASE WHEN status = 'Completed' THEN 1 END) AS completed_orders
FROM orders
GROUP BY category;

This pattern is especially useful for:

- Segmentation analysis

- Pivot-style reporting

- KPI tables used by dashboards

### Business intelligence framing
## What the analysis covers

# Customer analytics

- Segmentation using RFM and value tiers

- Purchase frequency and ordering behavior

- Early churn risk indicators

# Product analytics

- Revenue and unit performance

- Category contribution and concentration

- Cross-sell and bundle opportunities

# Operational analytics

- Order volume and velocity

- Revenue trends over time

-Category-level benchmarking

### KPI hierarchy

┌─────────────────────────────────────────────────────┐
│                TOP-LEVEL KPIs                       │
│  - Total Revenue                                    │
│  - Customer Lifetime Value                          │
│  - Repeat Purchase Rate                             │
└──────────────────┬──────────────────────────────────┘
                   │
       ┌───────────┴────────────┬──────────────────┐
       ▼                        ▼                  ▼
┌──────────────┐      ┌──────────────┐   ┌──────────────┐
│  CUSTOMER    │      │   PRODUCT    │   │ OPERATIONAL  │
│   METRICS    │      │   METRICS    │   │   METRICS    │
└──────────────┘      └──────────────┘   └──────────────┘

### Scalability considerations
## Current state (MVP dataset)
- 15 customers

- 15 products

- 25 orders

- 67 order line items

At this scale, all queries run instantly. The structure is designed so the same logic still works when data volume grows.

## Example growth screnario
- 10,000+ customers

- 500+ products

- 100,000+ orders

- 250,000+ order line items

### Scaling strategies
## Partitioning orders by date

CREATE TABLE Orders (
    ...
) PARTITION BY RANGE (YEAR(OrderDate)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pFuture VALUES LESS THAN MAXVALUE
);

## Composite indexes for common access paths

CREATE INDEX idx_orders_customer_date 
ON Orders(CustomerID, OrderDate);

CREATE INDEX idx_orderdetails_product_order
ON Order_Details(ProductID, OrderID);

## Materialized views for heavy dashboards

CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT 
    OrderDate,
    COUNT(*) AS order_count,
    SUM(TotalAmount) AS daily_revenue,
    AVG(TotalAmount) AS avg_order_value
FROM Orders
GROUP BY OrderDate;

### Data governance (portfolio scope)

- NOT NULL constraints for required fields

- CHECK constraints for valid ranges

- UNIQUE constraints for natural keys (e.g., email)

- Foreign keys to maintain referential integrity

Audit-friendly fields:

- signup / created dates

- order dates for recency analysis

## Testing strategy

# Setup validation

- Verify record counts after load

- Confirm foreign key enforcement

- Validate constraints

# Query validation

- Check expected outputs for known cases

- Ensure NULL and zero-purchase cases behave correctly

- Spot-check performance on joins and windows

# Performance considerations

- Filter early (WHERE before GROUP BY)

- Prefer INNER JOINs when business logic allows

- Avoid SELECT * in analytical queries

- Use HAVING only for aggregate conditions

### Development workflow

sql-ecommerce-case-study/
├── Setup & Infrastructure
│   ├── setup.sql
│   └── .gitignore
│
├── Schema Definition
│   └── 01_schema_creation.sql
│
├── Analytics Queries
│   ├── 02_business_questions.sql
│   └── 03_advanced_analytics.sql
│
├── Documentation
│   ├── README.md
│   ├── DATABASE_SCHEMA.md
│   ├── ARCHITECTURE.md
│   ├── QUERIES_GUIDE.md
│   ├── SAMPLE_OUTPUTS.md
│   ├── CASE_STUDY_REPORT.md
│   └── LEARNING_NOTES.md
│
└── Data Files
    ├── customers.csv
    ├── products.csv
    ├── orders.csv
    └── order_details.csv

### Conclusion

This architecture is intentionally designed to balance clarity and realism. It shows how transactional data can be modeled, queried, and analyzed using patterns that scale beyond toy examples, while remaining easy to understand and review.

The structure reflects how a real analyst would approach:

- schema design

- analytical SQL development

- documentation and communication of results
