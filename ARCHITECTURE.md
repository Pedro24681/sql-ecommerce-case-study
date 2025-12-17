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
- CSV → setup / insert steps
- constraints validate data during load
- foreign keys enforce relationships

**2) Storage**
- normalized tables reduce redundancy
- indexes support joins and filters
- core fields support auditability (dates, statuses)

**3) Processing**
- business questions answered using SQL
- CTEs keep complex logic readable
- window functions support ranking, retention, trend analysis

**4) Output**
- results returned as tables
- documented in markdown
- translated into business takeaways and recommendations


## Analytical approach

- Pattern 1: Multi-level CTE pipelines

Use this when you need staged calculations (metrics → scoring → classification).

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

*Why this pattern is useful*:

- reads top-to-bottom like a workflow

- easier to debug than nested subqueries

- intermediate results are easy to validate

- Examples in this project:

- RFM / churn scoring

- period-over-period comparisons

- cohort retention rollups
