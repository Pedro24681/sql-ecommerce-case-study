# E-Commerce SQL Analytics Case Study

[![SQL](https://img.shields.io/badge/SQL-Advanced-blue.svg)](https://www.mysql.com/)
[![Database](https://img.shields.io/badge/Database-MySQL%20%7C%20PostgreSQL-orange.svg)](https://www.postgresql.org/)
[![Analytics](https://img.shields.io/badge/Analytics-Business%20Intelligence-green.svg)](https://github.com/Pedro24681/sql-ecommerce-case-study)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> # SQL E-Commerce Analytics Case Study

In this project, I worked with a realistic e-commerce dataset to explore real business questions using SQL. My goal was to build analytical queries that help answer questions about sales performance, customer behavior, and product trends — the kinds of questions a data analyst would tackle in a real company.

I designed the database schema, wrote queries to answer specific business questions, and used advanced SQL features like window functions and CTEs to derive deeper insights. Throughout this case study I document my approach, share results, and explain what the findings mean in a business context.




# Project Overview

This repository showcases advanced SQL analytics applied to a realistic e-commerce database. It demonstrates proficiency in complex queries, window functions, CTEs, business intelligence, and translating data into actionable insights.



# Prerequisites
- MySQL 8.0+ or PostgreSQL 12+ installed
- Basic SQL knowledge
- Command-line or GUI database client (MySQL Workbench, pgAdmin, DBeaver, etc.)

# Setup (2 minutes)

```bash
# 1. Clone the repository
git clone https://github.com/Pedro24681/sql-ecommerce-case-study.git
cd sql-ecommerce-case-study

# 2. Run the setup script in your SQL client
# This creates tables and loads sample data
source setup.sql
# OR for PostgreSQL: \i setup.sql

# 3. Explore the queries
# Open and run queries from:
# - 02_business_questions.sql
# - 03_advanced_analytics.sql
```



# Database Architecture

**4 Core Tables** | **Normalized Design** | **Referential Integrity**

```
┌─────────────┐       ┌─────────────┐       ┌─────────────┐
│  Customers  │◄──────┤   Orders    │──────►│  Products   │
└─────────────┘       └─────────────┘       └─────────────┘
                             │
                             ▼
                      ┌──────────────┐
                      │Order_Details │
                      └──────────────┘
```

- **Customers**: 50+ customer records with lifetime value metrics
- **Orders**: Transaction history with status tracking
- **Products**: Catalog with pricing, inventory, and categories
- **Order_Details**: Line-item details with calculated totals

I put the full database schema in `DATABASE_SCHEMA.md`. It includes a diagram and description of each table’s columns and relationships.



# Key Features & Skills Demonstrated

## What I Did

- Imported and modeled 4 core tables: Customers, Orders, Products, and Order Details
- Defined relationships and ensured data integrity in setup scripts
- Answered key business questions, including:
  - Who are our most valuable customers?
  - Which product categories drive the most revenue?
  - What are month-over-month sales trends?
- Applied advanced SQL techniques like window functions (e.g., `ROW_NUMBER()`, `LAG()`) and multi-level CTEs to solve more complex problems
- Documented query logic and results so someone else can understand my decisions

# Business Analytics
-  **Customer Segmentation** - RFM analysis, cohort behavior
-  **Revenue Analysis** - Product performance, profitability
-  **Growth Metrics** - MoM/YoY trends, retention rates
-  **Churn Prediction** - At-risk customer identification
-  **Customer Lifetime Value (CLV)** - Predictive modeling
-  **Market Basket Analysis** - Cross-sell opportunities

# Professional Development Practices
-  Comprehensive documentation with business context
-  Automated setup scripts for reproducibility
-  Organized query structure with clear naming
-  Detailed comments explaining complex logic
-  Sample outputs demonstrating insights


# Repository Structure

```
sql-ecommerce-case-study/
│
├── README.md                      # You are here
├── setup.sql                      # Automated database setup
├── .gitignore                     # Standard project patterns
│
├── 01_schema_creation.sql         # Table definitions & indexes
├── 02_business_questions.sql      # 6 core business analyses
├── 03_advanced_analytics.sql      # 10+ advanced analytical queries
│
├── DATABASE_SCHEMA.md             # Complete schema documentation
├── ARCHITECTURE.md                # System design & approach
├── QUERIES_GUIDE.md               # Query-by-query breakdown
├── SAMPLE_OUTPUTS.md              # Example results & insights
│
├── CASE_STUDY_REPORT.md           # Comprehensive findings report
├── LEARNING_NOTES.md              # SQL learning journey
│
└── Data Files/
    ├── customers.csv              # Customer master data
    ├── orders.csv                 # Order transactions
    ├── products.csv               # Product catalog
    └── order_details.csv          # Order line items
```


# Featured Queries

# 1. Customer Lifetime Value Analysis
Calculates predicted customer value using purchase frequency, recency, and spending patterns.

```sql
-- Demonstrates: CTEs, Window Functions, CASE logic
-- Business Value: Identify high-value customers for retention programs
-- File: 02_business_questions.sql (Question 5)
```

# 2. RFM Segmentation for Churn Risk
Segments customers by Recency, Frequency, and Monetary value to predict churn.

```sql
-- Demonstrates: Multiple CTEs, PERCENT_RANK(), Complex scoring
-- Business Value: Proactive churn prevention campaigns
-- File: 02_business_questions.sql (Question 6)
```

# 3. Product Performance with Trend Analysis
Compares current vs. previous period performance with growth calculations.

```sql
-- Demonstrates: Multi-CTE design, COALESCE(), Period comparison
-- Business Value: Inventory planning and product optimization
-- File: 03_advanced_analytics.sql (Query 2.2)
```

# 4. Customer Cohort Retention Analysis
Tracks customer cohorts from acquisition through subsequent months.

```sql
-- Demonstrates: Date arithmetic, Self-joins, Aggregation layers
-- Business Value: Measure retention effectiveness
-- File: 03_advanced_analytics.sql (Query 7.1)
```

 See [QUERIES_GUIDE.md](QUERIES_GUIDE.md) for all query documentation


# Business Insights Generated

This project answers critical business questions:

| Question | Analysis Type | Key Findings |
|----------|---------------|--------------|
| Top-selling categories | Revenue Analysis | Electronics leads with 28% margin |
| High-value customers | Customer Segmentation | Top 10% drive 42% of revenue |
| Repeat purchase rate | Retention Analysis | 68% repeat within 3 months |
| Peak sales periods | Seasonal Trends | Q4 accounts for 40% annual revenue |
| Customer lifetime value | Predictive Analytics | VIP segment: $48.5K average CLV |
| Churn risk scoring | Risk Analysis | 8.2% customers at high churn risk |

 See [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md) for detailed results


# Technical Implementation

# SQL Dialects Supported

This project demonstrates SQL concepts using both MySQL and PostgreSQL syntax:

- **setup.sql & 01_schema_creation.sql**: MySQL 8.0+ syntax (AUTO_INCREMENT, MySQL functions)
- **02_business_questions.sql & 03_advanced_analytics.sql**: PostgreSQL 12+ syntax (::NUMERIC casting, INTERVAL)

> ** Learning Note:** The queries showcase advanced SQL patterns applicable to both databases. Converting between dialects typically requires minor adjustments:
> - PostgreSQL `::NUMERIC` → MySQL `CAST(... AS DECIMAL)`  
> - PostgreSQL `INTERVAL '12 months'` → MySQL `INTERVAL 12 MONTH`  
> - PostgreSQL-specific table references updated to match actual schema

**For Production Use:** Choose one database and apply consistent syntax throughout. The analytical patterns and business logic remain universal.

# Query Complexity Levels
- **Beginner**: Basic SELECT, WHERE, GROUP BY
- **Intermediate**: JOINs, subqueries, aggregation
- **Advanced**: Window functions, CTEs, complex analytics
- **Expert**: Multi-level CTEs, recursive queries, optimization

# Performance Considerations
- Strategic indexing on foreign keys and date columns
- Efficient use of CTEs vs. subqueries
- Proper filtering before aggregation
- Optimized window function partitioning


# Learning Resources

# For Beginners
Start with `01_schema_creation.sql` to understand the data model, then explore simpler queries in `02_business_questions.sql`.

# For Intermediate Users
Focus on `02_business_questions.sql` to see practical applications of window functions and CTEs.

# For Advanced Users
Dive into `03_advanced_analytics.sql` for complex multi-CTE patterns and sophisticated business logic.



# Contributing

While this is a personal portfolio project for me, suggestions and feedback are welcome


# License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


##  Author

**Pedro24681**

- GitHub: [@Pedro24681](https://github.com/Pedro24681)
- Project: [SQL E-Commerce Case Study](https://github.com/Pedro24681/sql-ecommerce-case-study)


</div>
