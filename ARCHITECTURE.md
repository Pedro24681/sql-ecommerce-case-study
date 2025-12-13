# 🏛️ System Architecture & Design

## Overview

This document outlines the **architectural approach**, **design philosophy**, and **analytical methodology** behind the E-Commerce SQL Case Study. It demonstrates system design thinking, data modeling principles, and scalable analytics architecture.

---

## 🎯 Design Philosophy

### Core Principles

1. **Data Integrity First** - Ensure accuracy through constraints and normalization
2. **Query Performance** - Optimize for analytical workloads with strategic indexing
3. **Maintainability** - Clear structure, comprehensive documentation, modular queries
4. **Scalability** - Design patterns that support growth without major refactoring
5. **Business Alignment** - Schema reflects real-world business processes

### Design Goals

- ✅ **Analytical-Friendly Schema** - Star schema elements for fast aggregations
- ✅ **Normalized Structure** - 3NF compliance to eliminate redundancy
- ✅ **Self-Documenting** - Descriptive naming, inline comments, external docs
- ✅ **Reproducible** - Automated setup scripts for consistent environments
- ✅ **Production-Ready** - Proper indexing, constraints, and relationships

---

## 🏗️ Architectural Layers

### 1. Data Storage Layer

**Purpose:** Persistent storage with ACID compliance

```
┌─────────────────────────────────────────────────┐
│           DATABASE MANAGEMENT SYSTEM            │
│                                                 │
│   MySQL 8.0+ / PostgreSQL 12+                  │
│   - ACID transactions                           │
│   - Referential integrity                       │
│   - Index management                            │
│   - Query optimization                          │
└─────────────────────────────────────────────────┘
```

**Components:**
- **MySQL InnoDB Engine** - Default transactional storage
- **B-Tree Indexes** - Primary keys and frequent lookup columns
- **Foreign Key Constraints** - Enforced relationships
- **Generated Columns** - Calculated fields (LineTotal)

**Rationale:**
- MySQL chosen for widespread adoption and compatibility
- InnoDB provides row-level locking for concurrent access
- Clustered index on primary keys improves range scans

---

### 2. Data Model Layer

**Purpose:** Logical representation of business entities

```
┌─────────────────────────────────────────────────┐
│              DATA MODEL LAYER                   │
│                                                 │
│  ┌─────────────┐         ┌─────────────┐      │
│  │ Dimension   │         │    Fact     │      │
│  │   Tables    │◄────────┤   Tables    │      │
│  └─────────────┘         └─────────────┘      │
│   - Customers              - Orders            │
│   - Products               - Order_Details     │
└─────────────────────────────────────────────────┘
```

**Design Pattern: Hybrid Star Schema**

**Dimension Tables (Descriptive Attributes):**
- `Customers` - Who is buying?
- `Products` - What is being sold?

**Fact Tables (Transactional Measures):**
- `Orders` - Transaction headers
- `Order_Details` - Line-item details

**Benefits:**
- Fast aggregations (SUM, AVG, COUNT)
- Simple join paths for analytics
- Intuitive business logic representation
- Supports complex queries with CTEs

---

### 3. Business Logic Layer

**Purpose:** Transform raw data into business insights

```
┌─────────────────────────────────────────────────┐
│          BUSINESS LOGIC LAYER                   │
│                                                 │
│  ┌─────────────────┐   ┌─────────────────┐    │
│  │   SQL Queries   │   │     CTEs &      │    │
│  │   (Analytics)   │   │ Window Functions│    │
│  └─────────────────┘   └─────────────────┘    │
│                                                 │
│  Analytical Patterns:                           │
│  - Customer Segmentation (RFM)                  │
│  - Cohort Analysis                              │
│  - Time-Series Trends                           │
│  - Product Performance                          │
│  - Churn Prediction                             │
└─────────────────────────────────────────────────┘
```

**Query Organization:**
- **01_schema_creation.sql** - Foundation (DDL)
- **02_business_questions.sql** - Core analytics (6 questions)
- **03_advanced_analytics.sql** - Advanced patterns (10+ queries)

**Complexity Progression:**
1. Simple aggregations → 2. Multi-table joins → 3. Window functions → 4. Multi-level CTEs

---

### 4. Presentation Layer

**Purpose:** Communicate insights to stakeholders

```
┌─────────────────────────────────────────────────┐
│          PRESENTATION LAYER                     │
│                                                 │
│  Query Results → Documentation → Insights       │
│                                                 │
│  - SAMPLE_OUTPUTS.md (example results)          │
│  - QUERIES_GUIDE.md (explanations)              │
│  - CASE_STUDY_REPORT.md (business findings)     │
└─────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Architecture

### End-to-End Data Journey

```
┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│              │       │              │       │              │
│   CSV Files  │──────►│   Database   │──────►│  SQL Queries │
│              │       │    Tables    │       │              │
└──────────────┘       └──────────────┘       └──────────────┘
   Raw Data              Structured              Analytics
                         Storage
                            │
                            ▼
                    ┌──────────────┐
                    │   Indexes    │
                    │  Constraints │
                    │   Relations  │
                    └──────────────┘
                      Data Integrity
```

### Detailed Flow

**1. Data Ingestion:**
- CSV files → `setup.sql` → INSERT statements
- Validates constraints during load
- Establishes foreign key relationships
- Populates indexes automatically

**2. Data Storage:**
- Normalized tables (3NF)
- Indexed columns for performance
- Referential integrity enforced
- Audit fields (dates, statuses)

**3. Data Processing:**
- SQL queries extract insights
- CTEs organize complex logic
- Window functions enable advanced analytics
- Aggregations generate metrics

**4. Data Output:**
- Result sets in tabular format
- Documented in markdown files
- Business interpretations provided
- Actionable recommendations

---

## 📊 Analytical Approach

### Query Design Patterns

#### Pattern 1: Multi-Level CTEs

**Use Case:** Complex calculations requiring intermediate results

```sql
WITH base_metrics AS (
    -- Step 1: Calculate basic metrics
    SELECT ...
),
scored_data AS (
    -- Step 2: Apply scoring logic
    SELECT ..., metrics FROM base_metrics
),
final_segmentation AS (
    -- Step 3: Segment and classify
    SELECT ..., scores FROM scored_data
)
SELECT * FROM final_segmentation;
```

**Benefits:**
- Readable, maintainable code
- Logical progression of calculations
- Easier debugging and testing
- Reusable intermediate results

**Examples:**
- Customer RFM scoring (Question 6)
- Product performance trends (Query 2.2)
- Cohort retention analysis (Query 7.1)

#### Pattern 2: Window Functions

**Use Case:** Ranking, running totals, period-over-period comparisons

```sql
SELECT 
    order_date,
    revenue,
    LAG(revenue) OVER (ORDER BY order_date) AS prev_revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    SUM(revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM daily_sales;
```

**Benefits:**
- Avoids self-joins
- Efficient calculations within partitions
- Enables sophisticated analytics
- Preserves row-level detail

**Examples:**
- Customer purchase sequences (Query 4.1)
- Product rankings by category (Query 5.1)
- Month-over-month growth (Query 6.1)

#### Pattern 3: Conditional Aggregation

**Use Case:** Segmentation, pivot-like operations, metric variations

```sql
SELECT 
    category,
    SUM(CASE WHEN year = 2024 THEN revenue ELSE 0 END) AS revenue_2024,
    SUM(CASE WHEN year = 2025 THEN revenue ELSE 0 END) AS revenue_2025,
    COUNT(CASE WHEN status = 'Completed' THEN 1 END) AS completed_orders
FROM orders
GROUP BY category;
```

**Benefits:**
- Single-pass aggregation
- Flexible metric definitions
- Cleaner than multiple subqueries
- Efficient execution plans

**Examples:**
- Customer segmentation by value tiers
- Status-based order counts
- Category performance matrices

---

## 🎯 Business Intelligence Framework

### Analytical Categories

**1. Customer Analytics**
- **Segmentation:** RFM analysis, value tiers, lifecycle stages
- **Behavior:** Purchase frequency, order patterns, channel preferences
- **Prediction:** Churn risk, lifetime value, next purchase probability

**2. Product Analytics**
- **Performance:** Revenue, units sold, margin contribution
- **Trends:** Growth rates, seasonality, lifecycle stage
- **Optimization:** Pricing analysis, inventory turnover, cross-sell opportunities

**3. Operational Analytics**
- **Efficiency:** Order fulfillment times, error rates, process bottlenecks
- **Financial:** Revenue trends, cost metrics, profitability by segment
- **Strategic:** Market penetration, competitive positioning, growth opportunities

### Metric Hierarchy

```
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
├──────────────┤      ├──────────────┤   ├──────────────┤
│- Acquisition │      │- Sales Volume│   │- Fulfillment │
│- Retention   │      │- Margin %    │   │- Inventory   │
│- Engagement  │      │- Turnover    │   │- Cost Control│
└──────────────┘      └──────────────┘   └──────────────┘
```

---

## 🚀 Scalability Considerations

### Current State (MVP)

**Data Volume:**
- 15 customers
- 15 products
- 25 orders
- 67 order line items

**Query Performance:** Sub-second response times

### Growth Projections

**5-Year Outlook:**
- 10,000+ customers
- 500+ products
- 100,000+ orders
- 250,000+ line items

### Scaling Strategies

#### 1. Horizontal Partitioning

**Orders Table Partitioning:**
```sql
-- Partition by year
CREATE TABLE Orders (
    ...
) PARTITION BY RANGE (YEAR(OrderDate)) (
    PARTITION p2023 VALUES LESS THAN (2024),
    PARTITION p2024 VALUES LESS THAN (2025),
    PARTITION p2025 VALUES LESS THAN (2026),
    PARTITION pFuture VALUES LESS THAN MAXVALUE
);
```

**Benefits:**
- Faster queries with partition pruning
- Easier archival of historical data
- Improved maintenance operations

#### 2. Index Optimization

**Composite Indexes for Common Queries:**
```sql
-- Customer order history
CREATE INDEX idx_orders_customer_date 
ON Orders(CustomerID, OrderDate);

-- Product sales analysis
CREATE INDEX idx_orderdetails_product_order
ON Order_Details(ProductID, OrderID);
```

**Benefits:**
- Reduced disk I/O
- Faster joins and filters
- Lower memory footprint

#### 3. Materialized Views

**Pre-Aggregated Metrics:**
```sql
CREATE MATERIALIZED VIEW mv_daily_sales AS
SELECT 
    OrderDate,
    COUNT(*) AS order_count,
    SUM(TotalAmount) AS daily_revenue,
    AVG(TotalAmount) AS avg_order_value
FROM Orders
GROUP BY OrderDate;
```

**Benefits:**
- Sub-second dashboard queries
- Reduced computation overhead
- Scheduled refresh process

#### 4. Data Archival

**Cold Storage Strategy:**
- Archive orders >2 years old to separate tables
- Maintain hot data for active analytics
- Union queries for historical reporting when needed

---

## 🔒 Data Governance

### Quality Controls

**1. Constraint Enforcement:**
- NOT NULL for required fields
- CHECK constraints for valid ranges
- UNIQUE constraints for natural keys
- FOREIGN KEY for referential integrity

**2. Validation Rules:**
- Email format validation (via CHECK or application)
- Date range checks (OrderDate <= CURRENT_DATE)
- Price positivity (Price > 0)
- Quantity positivity (Quantity > 0)

**3. Audit Trail:**
- SignUpDate - Customer acquisition tracking
- CreatedDate - Product catalog history
- OrderDate - Transaction timeline
- LastPurchaseDate - Recency tracking

### Privacy & Compliance

**PII Handling:**
- Customer email addresses (UNIQUE, indexed)
- Shipping addresses (stored for fulfillment)
- Customer names (for personalization)

**Compliance Considerations:**
- GDPR: Right to erasure (soft delete via IsActive flag)
- Data retention policies (archival strategy)
- Access controls (application-layer enforcement)

---

## 🧪 Testing Strategy

### Data Validation

**1. Setup Verification:**
- Record count checks after data load
- Referential integrity validation
- Constraint enforcement testing
- Sample data preview

**2. Query Testing:**
- Expected result validation
- Edge case handling (NULL values, zero quantities)
- Performance benchmarking
- Comparison across database engines

### Quality Assurance

**Query Categories:**
- **Unit Tests:** Single-table operations
- **Integration Tests:** Multi-table joins
- **Regression Tests:** Known result validation
- **Performance Tests:** Execution time tracking

---

## 📈 Performance Optimization

### Query Optimization Techniques

**1. Index Usage:**
- Always filter on indexed columns where possible
- Use covering indexes for SELECT-heavy queries
- Monitor index selectivity and usage stats

**2. Join Strategy:**
- Order joins from smallest to largest result sets
- Use INNER JOIN when possible (better optimization)
- Avoid unnecessary OUTER JOINs

**3. Subquery vs. CTE:**
- CTEs for readability and multiple references
- Inline subqueries for one-time use
- Derived tables for complex filters

**4. Aggregation Optimization:**
- Filter before aggregating (WHERE before GROUP BY)
- Limit result sets early
- Use HAVING only for aggregate conditions

### Execution Plan Analysis

**Key Metrics:**
- Rows examined vs. rows returned (selectivity)
- Index vs. full table scan
- Join algorithm (nested loop, hash, merge)
- Temporary table usage

---

## 🛠️ Development Workflow

### File Organization

```
sql-ecommerce-case-study/
├── Setup & Infrastructure
│   ├── setup.sql              # Automated database creation
│   └── .gitignore             # Version control exclusions
│
├── Schema Definition
│   └── 01_schema_creation.sql # DDL statements
│
├── Analytics Queries
│   ├── 02_business_questions.sql   # Core 6 questions
│   └── 03_advanced_analytics.sql   # 10+ advanced queries
│
├── Documentation
│   ├── README.md              # Project overview
│   ├── DATABASE_SCHEMA.md     # Schema details
│   ├── ARCHITECTURE.md        # This file
│   ├── QUERIES_GUIDE.md       # Query documentation
│   ├── SAMPLE_OUTPUTS.md      # Example results
│   ├── CASE_STUDY_REPORT.md   # Business findings
│   └── LEARNING_NOTES.md      # Personal learning
│
└── Data Files
    ├── customers.csv
    ├── products.csv
    ├── orders.csv
    └── order_details.csv
```

### Development Principles

**1. Modularity:**
- Each SQL file has a clear purpose
- Queries organized by complexity
- Reusable patterns documented

**2. Documentation:**
- Inline comments for complex logic
- External docs for architecture
- Sample outputs for validation

**3. Version Control:**
- Git for change tracking
- Meaningful commit messages
- Feature branches for experimentation

---

## 🎓 Learning Progression

### Skill Development Path

**Level 1: Foundation**
- Schema design and normalization
- Basic SELECT, WHERE, GROUP BY
- Simple joins (INNER JOIN)

**Level 2: Intermediate**
- Complex joins (LEFT, RIGHT, FULL OUTER)
- Subqueries and derived tables
- Aggregate functions with HAVING

**Level 3: Advanced**
- Window functions (RANK, LAG, LEAD)
- Common Table Expressions (CTEs)
- Conditional aggregation with CASE

**Level 4: Expert**
- Multi-level CTEs with dependencies
- Recursive queries
- Query optimization and indexing

---

## 🔗 Integration Points

### Potential Enhancements

**1. BI Tool Integration:**
- Tableau / Power BI dashboards
- Pre-built queries for common visualizations
- Real-time data refresh strategies

**2. Application Layer:**
- REST API for programmatic access
- ORM integration (Python SQLAlchemy, Java Hibernate)
- Microservices for specific analytics

**3. Machine Learning:**
- Feature engineering SQL queries
- Customer segmentation inputs
- Predictive model training data

**4. ETL Pipelines:**
- Automated data refresh from source systems
- Data quality validation scripts
- Incremental load strategies

---

## 📝 Best Practices Summary

### Do's ✅
- ✅ Use meaningful, descriptive names
- ✅ Comment complex logic
- ✅ Index foreign keys and date columns
- ✅ Validate constraints at database level
- ✅ Organize queries by business purpose
- ✅ Test edge cases and NULL handling
- ✅ Document assumptions and business rules

### Don'ts ❌
- ❌ Use SELECT * in production queries
- ❌ Ignore execution plans
- ❌ Over-index (too many indexes hurt writes)
- ❌ Mix business logic across layers
- ❌ Store unencrypted sensitive data
- ❌ Skip referential integrity constraints
- ❌ Use cursors when set-based operations work

---

## 🌟 Conclusion

This architecture balances **academic rigor** with **practical applicability**, demonstrating:

- **System Design Thinking** - Layered architecture, separation of concerns
- **Data Modeling Expertise** - Normalization, star schema, indexing strategy
- **Analytical Sophistication** - Advanced SQL patterns, business intelligence
- **Professional Standards** - Documentation, testing, scalability planning

The design is **production-ready** yet **approachable for learning**, making it ideal for portfolio demonstration, interview preparation, and skill development.

---

## 🔗 Related Documentation

- [README.md](README.md) - Project overview & quick start
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Detailed schema specs
- [QUERIES_GUIDE.md](QUERIES_GUIDE.md) - Query documentation
- [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md) - Example results

---

**Version:** 1.0  
**Last Updated:** 2025-12-13  
**Author:** Pedro24681  
**License:** MIT
