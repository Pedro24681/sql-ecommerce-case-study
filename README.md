# 📊 E-Commerce SQL Analytics Case Study

[![SQL](https://img.shields.io/badge/SQL-Advanced-blue.svg)](https://www.mysql.com/)
[![Database](https://img.shields.io/badge/Database-MySQL%20%7C%20PostgreSQL-orange.svg)](https://www.postgresql.org/)
[![Analytics](https://img.shields.io/badge/Analytics-Business%20Intelligence-green.svg)](https://github.com/Pedro24681/sql-ecommerce-case-study)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A comprehensive SQL case study demonstrating advanced query techniques, business analytics, and data-driven insights for e-commerce operations.

---

## 🎯 Project Overview

This repository showcases **advanced SQL analytics** applied to a realistic e-commerce database. It demonstrates proficiency in complex queries, window functions, CTEs, business intelligence, and translating data into actionable insights.

**Perfect for:**
- 📈 Data Analysts seeking real-world SQL examples
- 💼 Business Intelligence professionals
- 🎓 Students learning advanced SQL techniques
- 👔 Hiring managers evaluating SQL expertise

---

## ⚡ Quick Start

### Prerequisites
- MySQL 8.0+ or PostgreSQL 12+ installed
- Basic SQL knowledge
- Command-line or GUI database client (MySQL Workbench, pgAdmin, DBeaver, etc.)

### Setup (2 minutes)

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

---

## 🏗️ Database Architecture

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

👉 See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for complete schema documentation

---

## 🚀 Key Features & Skills Demonstrated

### Advanced SQL Techniques
- ✅ **Window Functions** - ROW_NUMBER(), RANK(), LAG(), LEAD(), NTILE()
- ✅ **Common Table Expressions (CTEs)** - Multi-level, recursive patterns
- ✅ **Complex Joins** - Multi-table relationships, self-joins
- ✅ **Subqueries & Derived Tables** - Nested logic and optimization
- ✅ **Date/Time Analysis** - Period-over-period comparisons, trends
- ✅ **Conditional Aggregation** - CASE statements within aggregates

### Business Analytics
- 📊 **Customer Segmentation** - RFM analysis, cohort behavior
- 💰 **Revenue Analysis** - Product performance, profitability
- 📈 **Growth Metrics** - MoM/YoY trends, retention rates
- ⚠️ **Churn Prediction** - At-risk customer identification
- 🎯 **Customer Lifetime Value (CLV)** - Predictive modeling
- 🛒 **Market Basket Analysis** - Cross-sell opportunities

### Professional Development Practices
- 📖 Comprehensive documentation with business context
- 🔄 Automated setup scripts for reproducibility
- 🗂️ Organized query structure with clear naming
- 💬 Detailed comments explaining complex logic
- 📊 Sample outputs demonstrating insights

---

## 📂 Repository Structure

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

---

## 🔍 Featured Queries

### 1. Customer Lifetime Value Analysis
Calculates predicted customer value using purchase frequency, recency, and spending patterns.

```sql
-- Demonstrates: CTEs, Window Functions, CASE logic
-- Business Value: Identify high-value customers for retention programs
-- File: 02_business_questions.sql (Question 5)
```

### 2. RFM Segmentation for Churn Risk
Segments customers by Recency, Frequency, and Monetary value to predict churn.

```sql
-- Demonstrates: Multiple CTEs, PERCENT_RANK(), Complex scoring
-- Business Value: Proactive churn prevention campaigns
-- File: 02_business_questions.sql (Question 6)
```

### 3. Product Performance with Trend Analysis
Compares current vs. previous period performance with growth calculations.

```sql
-- Demonstrates: Multi-CTE design, COALESCE(), Period comparison
-- Business Value: Inventory planning and product optimization
-- File: 03_advanced_analytics.sql (Query 2.2)
```

### 4. Customer Cohort Retention Analysis
Tracks customer cohorts from acquisition through subsequent months.

```sql
-- Demonstrates: Date arithmetic, Self-joins, Aggregation layers
-- Business Value: Measure retention effectiveness
-- File: 03_advanced_analytics.sql (Query 7.1)
```

👉 See [QUERIES_GUIDE.md](QUERIES_GUIDE.md) for all query documentation

---

## 📊 Business Insights Generated

This project answers critical business questions:

| Question | Analysis Type | Key Findings |
|----------|---------------|--------------|
| Top-selling categories | Revenue Analysis | Electronics leads with 28% margin |
| High-value customers | Customer Segmentation | Top 10% drive 42% of revenue |
| Repeat purchase rate | Retention Analysis | 68% repeat within 3 months |
| Peak sales periods | Seasonal Trends | Q4 accounts for 40% annual revenue |
| Customer lifetime value | Predictive Analytics | VIP segment: $48.5K average CLV |
| Churn risk scoring | Risk Analysis | 8.2% customers at high churn risk |

👉 See [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md) for detailed results

---

## 🛠️ Technical Implementation

### SQL Dialects Supported
- **MySQL 8.0+** (Primary)
- **PostgreSQL 12+** (Minor syntax adjustments needed)

### Query Complexity Levels
- **Beginner**: Basic SELECT, WHERE, GROUP BY
- **Intermediate**: JOINs, subqueries, aggregation
- **Advanced**: Window functions, CTEs, complex analytics
- **Expert**: Multi-level CTEs, recursive queries, optimization

### Performance Considerations
- Strategic indexing on foreign keys and date columns
- Efficient use of CTEs vs. subqueries
- Proper filtering before aggregation
- Optimized window function partitioning

---

## 📚 Learning Resources

### For Beginners
Start with `01_schema_creation.sql` to understand the data model, then explore simpler queries in `02_business_questions.sql`.

### For Intermediate Users
Focus on `02_business_questions.sql` to see practical applications of window functions and CTEs.

### For Advanced Users
Dive into `03_advanced_analytics.sql` for complex multi-CTE patterns and sophisticated business logic.

### Documentation
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Understand table structures
- [QUERIES_GUIDE.md](QUERIES_GUIDE.md) - Query-by-query explanations
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design thinking
- [LEARNING_NOTES.md](LEARNING_NOTES.md) - Personal learning journey

---

## 💡 Use Cases

### For Job Seekers
- **Portfolio piece** demonstrating advanced SQL skills
- **Interview preparation** with real-world scenarios
- **Technical assessment** practice problems
- **Skills showcase** for data analyst roles

### For Hiring Managers
- **Assessment reference** for candidate evaluation
- **Skill validation** across multiple SQL competencies
- **Business acumen** evaluation through analytical thinking
- **Code quality** standards demonstration

### For Students
- **Learning resource** for advanced SQL techniques
- **Practice dataset** with realistic business context
- **Query patterns** to adapt for other domains
- **Best practices** in SQL development

---

## 🎯 Skills Matrix

| Skill Category | Proficiency | Evidence |
|----------------|-------------|----------|
| SQL Fundamentals | ⭐⭐⭐⭐⭐ | 50+ queries across all files |
| Window Functions | ⭐⭐⭐⭐⭐ | Extensive use in analytics queries |
| CTEs | ⭐⭐⭐⭐⭐ | Multi-level patterns throughout |
| Data Modeling | ⭐⭐⭐⭐ | Normalized schema with integrity |
| Business Analytics | ⭐⭐⭐⭐⭐ | 6 business questions + 10 analyses |
| Query Optimization | ⭐⭐⭐⭐ | Strategic indexing & efficient design |
| Documentation | ⭐⭐⭐⭐⭐ | Comprehensive guides & comments |

---

## 🤝 Contributing

While this is a personal portfolio project, suggestions and feedback are welcome!

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Pedro24681**

- GitHub: [@Pedro24681](https://github.com/Pedro24681)
- Project: [SQL E-Commerce Case Study](https://github.com/Pedro24681/sql-ecommerce-case-study)

---

## 🌟 Acknowledgments

- Inspired by real-world e-commerce analytics challenges
- Designed to demonstrate production-ready SQL skills
- Built with hiring managers and recruiters in mind

---

## 📧 Contact & Feedback

Have questions or suggestions? Feel free to open an issue or reach out!

**⭐ If you find this project useful, please consider giving it a star! ⭐**

---

<div align="center">

**Made with ❤️ and SQL**

*Transforming data into insights, one query at a time.*

</div>
