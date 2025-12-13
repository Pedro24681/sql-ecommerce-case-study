# 📚 Queries Guide

## Overview

This guide provides detailed documentation for all SQL queries in the E-Commerce Analytics Case Study. Each query is explained with its **business purpose**, **SQL techniques used**, **expected output**, and **key insights**.

**Query Files:**
- `02_business_questions.sql` - 6 core business analytics questions
- `03_advanced_analytics.sql` - 10+ advanced analytical patterns

---

## 📖 Table of Contents

### Business Questions (02_business_questions.sql)
1. [Top-Selling Product Category](#question-1-top-selling-product-category)
2. [Top Customers by Revenue](#question-2-top-customers-by-revenue)
3. [Repeat Purchase Rate](#question-3-repeat-purchase-rate)
4. [Highest Sales Days](#question-4-highest-sales-days)
5. [Customer Lifetime Value (CLV)](#question-5-customer-lifetime-value)
6. [Churn Risk Analysis](#question-6-churn-risk-analysis)

### Advanced Analytics (03_advanced_analytics.sql)
1. [Window Functions - Sales Rankings](#analytics-1-window-functions)
2. [CTEs - Product Performance](#analytics-2-ctes-product-performance)
3. [Customer Segmentation (RFM)](#analytics-3-customer-segmentation)
4. [Order-to-Order Growth](#analytics-4-order-growth-analysis)
5. [Top Products Within Categories](#analytics-5-category-leaders)
6. [Month-over-Month Growth](#analytics-6-mom-growth)
7. [Customer Cohort Analysis](#analytics-7-cohort-analysis)
8. [Seasonal Trend Analysis](#analytics-8-seasonal-trends)
9. [Market Basket Analysis](#analytics-9-market-basket)
10. [Performance Benchmarking](#analytics-10-kpi-dashboard)

---

## 🔍 Business Questions (02_business_questions.sql)

### Question 1: Top-Selling Product Category

**Business Question:** *Which product categories generate the most revenue and how do they contribute to overall sales?*

**File Location:** `02_business_questions.sql` (Lines 11-41)

**SQL Techniques:**
- Multi-table INNER JOINs (4 tables)
- Window function: `RANK()`, `SUM() OVER ()`
- Aggregate functions: `COUNT()`, `SUM()`, `AVG()`
- Date filtering with `INTERVAL`
- Percentage calculation using window function

**Key Columns:**
- `category_name` - Product category
- `total_revenue` - Total sales in last 12 months
- `revenue_percentage` - Contribution to overall revenue
- `category_rank` - Performance ranking

**Business Value:**
- Identify top-performing categories for inventory investment
- Understand revenue distribution across product lines
- Guide marketing budget allocation
- Detect underperforming categories for optimization

**Sample Insight:**
> Electronics category leads with 35% revenue contribution, suggesting strong market demand. Fashion follows at 28%, indicating diversified revenue streams.

**Optimization Notes:**
- Index on `order_date` enables fast date filtering
- Category index supports efficient grouping
- Window function calculates percentage without subquery

---

### Question 2: Top Customers by Revenue

**Business Question:** *Who are our most valuable customers and what are their purchasing patterns?*

**File Location:** `02_business_questions.sql` (Lines 44-101)

**SQL Techniques:**
- Common Table Expression (CTE): `customer_metrics`
- Multiple aggregations: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- Window functions: `RANK()`, `ROW_NUMBER()`
- CASE statement for customer segmentation
- Date arithmetic for purchase intervals
- LEFT JOIN to include customers without orders

**Key Metrics:**
- `lifetime_revenue` - Total customer spend
- `total_purchases` - Order count
- `avg_order_value` - Average transaction size
- `avg_days_between_purchases` - Purchase frequency
- `customer_segment` - Value tier (VIP, Premium, Regular, At-Risk)

**Business Value:**
- Identify VIP customers for retention programs
- Understand purchase frequency patterns
- Segment customers for targeted marketing
- Calculate customer acquisition ROI

**Sample Insight:**
> Top 10% of customers (VIP segment) have avg lifetime revenue of $4,800 with 8+ purchases. They order every 45 days on average, making them ideal candidates for loyalty programs.

**Segmentation Logic:**
```
VIP:       ≥ $5,000 lifetime revenue
Premium:   ≥ $2,000
Regular:   ≥ $500
At-Risk:   < $500
```

---

### Question 3: Repeat Purchase Rate

**Business Question:** *What percentage of customers make repeat purchases and how loyal are they?*

**File Location:** `02_business_questions.sql` (Lines 104-174)

**SQL Techniques:**
- Multiple CTEs: `customer_purchase_history`, `repeat_metrics`
- Window functions: `LAG()`, `ROW_NUMBER()`, `PARTITION BY`
- Conditional aggregation with `CASE WHEN`
- Percentage calculations
- Complex CASE statement for loyalty classification

**Key Metrics:**
- `purchase_count` - Total orders per customer
- `repeat_orders` - Orders after first purchase
- `repeat_purchase_rate` - Percentage of repeat orders
- `avg_days_between_purchases` - Time between orders
- `loyalty_status` - Classification (One-Time Buyer, Highly Loyal, etc.)

**Business Value:**
- Measure customer retention effectiveness
- Identify one-time buyers for re-engagement campaigns
- Understand loyalty patterns by segment
- Calculate repeat purchase economics

**Sample Insight:**
> 68% of customers make repeat purchases within 90 days. Highly Loyal customers (80%+ repeat rate) generate 3x more revenue than One-Time Buyers.

**Loyalty Tiers:**
```
Highly Loyal:       ≥ 80% repeat rate
Repeat Customer:    50-79% repeat rate
Inconsistent Buyer: < 50% repeat rate
One-Time Buyer:     Single purchase only
```

---

### Question 4: Highest Sales Days

**Business Question:** *When are peak sales periods and what drives daily revenue fluctuations?*

**File Location:** `02_business_questions.sql` (Lines 177-234)

**SQL Techniques:**
- CTE: `daily_sales`
- Date functions: `CAST()`, `EXTRACT()`, `TO_CHAR()`
- Window functions: `RANK()`, `LAG()`, `SUM() OVER ()`
- Percentile calculations: `PERCENTILE_CONT()`
- Activity level classification
- Period-over-period change calculation

**Key Metrics:**
- `daily_revenue` - Total sales per day
- `total_orders` - Order volume
- `avg_order_value` - Transaction size
- `revenue_contribution_pct` - Daily percentage of total revenue
- `activity_level` - Peak Day, High Activity, Normal, Low Activity
- `revenue_change_pct` - Day-over-day growth

**Business Value:**
- Identify peak demand periods for staffing
- Understand day-of-week patterns
- Plan promotional timing
- Optimize inventory for high-activity days

**Sample Insight:**
> Peak Days (top 10%) generate 25% of total revenue. Friday-Sunday account for 45% of weekly sales, suggesting weekend shopping behavior. Black Friday shows 340% increase over baseline.

**Activity Classification:**
```
Peak Day:       ≥ 90th percentile revenue
High Activity:  75-90th percentile
Normal:         50-75th percentile
Low Activity:   < 50th percentile
```

---

### Question 5: Customer Lifetime Value (CLV)

**Business Question:** *What is the predicted lifetime value of each customer and which segments are most valuable?*

**File Location:** `02_business_questions.sql` (Lines 237-332)

**SQL Techniques:**
- Multiple CTEs: `customer_spending`, `clv_calculation`
- Complex calculations: annual spending rate, projected value
- Date arithmetic with `CURRENT_DATE`
- CASE statement for CLV multipliers
- Window functions: `RANK()`, `SUM() OVER ()`
- Division by zero protection with `NULLIF()`

**Key Metrics:**
- `calculated_clv` - Customer Lifetime Value formula
- `projected_clv_3years` - 3-year revenue projection
- `annual_spending_rate` - Annualized spending
- `days_since_last_purchase` - Recency metric
- `clv_tier` - Value classification

**Business Value:**
- Prioritize high-CLV customers for retention
- Calculate acceptable customer acquisition cost (CAC)
- Segment by predicted value for targeting
- Estimate long-term revenue potential

**Sample Insight:**
> Tier 1 (Premium) customers have projected 3-year CLV of $15,000+. Tier 2 shows CLV of $8,000. Focus retention efforts on Tier 1-2 to maximize ROI.

**CLV Formula:**
```
Basic CLV = (Total Spent / Total Orders) × (Total Orders / Customer Lifetime Days) × 365

Projected 3-Year CLV = Total Spent × Multiplier
  - 5+ orders: 3.0x multiplier
  - 3-4 orders: 2.5x
  - 1-2 orders: 2.0x
```

**CLV Tiers:**
```
Tier 1 - Premium:    ≥ $10,000
Tier 2 - High Value: $5,000-$9,999
Tier 3 - Medium:     $1,000-$4,999
Tier 4 - Low Value:  < $1,000
```

---

### Question 6: Churn Risk Analysis

**Business Question:** *Which customers are at risk of churning and what predicts churn likelihood?*

**File Location:** `02_business_questions.sql` (Lines 335-458)

**SQL Techniques:**
- Multiple CTEs: `customer_rfm`, `churn_scoring`
- RFM Analysis (Recency, Frequency, Monetary)
- Window functions: `PERCENT_RANK()`
- Complex CASE statements for scoring (5-point scale)
- Multiple classification dimensions
- Ranking with custom sort logic

**Key Metrics:**
- `recency_days` - Days since last purchase (R)
- `frequency_orders` - Total order count (F)
- `monetary_value` - Total spend (M)
- `recency_score` - 1-5 scale (5 = most recent)
- `frequency_score` - 1-5 scale (5 = highest frequency)
- `monetary_score` - 1-5 scale (5 = highest spend)
- `churn_risk_score` - Weighted risk calculation
- `churn_status` - Risk classification

**Business Value:**
- Proactive churn prevention campaigns
- Identify at-risk customers before loss
- Prioritize retention efforts by risk level
- Measure effectiveness of win-back programs

**Sample Insight:**
> 8.2% of customers classified as Critical Risk (recency > 180 days, frequency < 2). High Risk segment (12.4%) shows declining engagement. Win-back campaigns targeting these 20.6% could recover $85K in annual revenue.

**RFM Scoring System:**

**Recency (Lower is Better):**
```
Score 5: ≤ 30 days
Score 4: 31-60 days
Score 3: 61-90 days
Score 2: 91-180 days
Score 1: > 180 days
```

**Frequency (Higher is Better):**
```
Score 5: ≥ 10 orders
Score 4: 5-9 orders
Score 3: 3-4 orders
Score 2: 2 orders
Score 1: 1 order
```

**Monetary (Higher is Better):**
```
Score 5: ≥ $5,000
Score 4: $2,000-$4,999
Score 3: $500-$1,999
Score 2: $100-$499
Score 1: < $100
```

**Churn Risk Categories:**
```
Critical Risk: Recency > 180 days AND Frequency < 2
High Risk:     Recency > 120 days AND Frequency < 3
Medium Risk:   Recency > 90 days OR Frequency < 2
Low Risk:      Recency > 60 days
Stable:        Recency ≤ 60 days
```

---

## 🚀 Advanced Analytics (03_advanced_analytics.sql)

### Analytics 1: Window Functions

**Purpose:** Demonstrate advanced window function patterns for ranking, running totals, and comparative analysis

**File Location:** `03_advanced_analytics.sql` (Lines 17-68)

**Queries Included:**
1. **Product Sales Ranking with Running Total** (Lines 23-36)
2. **Customer Purchase Frequency** (Lines 40-52)
3. **Percentile Analysis - Order Value Distribution** (Lines 56-68)

**SQL Techniques:**
- `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()` - Different ranking methods
- `LAG()`, `LEAD()` - Access adjacent rows
- `SUM() OVER()` - Running totals
- `PERCENT_RANK()` - Percentile calculation
- `NTILE()` - Quartile/decile segmentation
- `PARTITION BY` - Window grouping

**Business Applications:**
- Product performance rankings within categories
- Customer order sequence analysis
- Order value distribution (quartiles, deciles)
- Identifying outliers and trends

**Sample Insight:**
> Top 10 products generate 45% of cumulative sales. Order value analysis shows 80% of orders fall below $500, with 5% exceeding $1,000 (premium segment).

---

### Analytics 2: CTEs - Product Performance

**Purpose:** Multi-stage product analysis with trend comparison

**File Location:** `03_advanced_analytics.sql` (Lines 72-165)

**Queries Included:**
1. **Comprehensive Product Performance Report** (Lines 76-114)
2. **Product Performance with Trend Analysis** (Lines 118-165)

**SQL Techniques:**
- Multiple CTEs: `product_sales`, `product_rankings`, `current_period`, `previous_period`
- Complex joins: FULL OUTER JOIN for missing period comparison
- `COALESCE()` for NULL handling
- Growth percentage calculations
- Date functions: `DATEADD()`, `DATEDIFF()`

**Key Metrics:**
- Revenue and units by product
- Period-over-period growth (MoM)
- Category contribution percentage
- Performance rankings

**Business Value:**
- Identify growing vs. declining products
- Prioritize inventory investment
- Detect seasonal patterns
- Optimize product mix

---

### Analytics 3: Customer Segmentation

**Purpose:** RFM-based customer segmentation for targeted marketing

**File Location:** `03_advanced_analytics.sql` (Lines 169-261)

**Queries Included:**
1. **RFM Segmentation** (Lines 173-215)
2. **Customer Lifetime Value Analysis** (Lines 219-261)

**SQL Techniques:**
- `NTILE()` for quintile scoring
- Multiple CTE layers
- Complex CASE statements for segmentation
- CLV calculation formulas

**Customer Segments Defined:**
- **Champions:** Best customers (R,F,M all high)
- **Loyal Customers:** High frequency, medium-high spend
- **At Risk:** Previously active, declining engagement
- **Can't Lose Them:** High value but declining recency
- **Potential Loyalists:** Recent customers with potential
- **New/Lost:** Recent first-timers or inactive

**Business Applications:**
- Personalized email campaigns by segment
- Loyalty program tier assignment
- Churn prevention targeting
- VIP customer identification

---

### Analytics 4: Order Growth Analysis

**Purpose:** Track customer order progression and value growth over time

**File Location:** `03_advanced_analytics.sql` (Lines 265-325)

**Queries Included:**
1. **Customer Purchase Pattern** (Lines 270-300)
2. **Order Value Progression** (Lines 304-325)

**SQL Techniques:**
- `ROW_NUMBER()` for sequence tracking
- `LAG()`, `LEAD()` for adjacent order comparison
- Growth percentage calculations
- Aggregation by order sequence

**Key Insights:**
- Average order value typically increases 15-30% by order 3
- Customer retention improves after second purchase
- Most growth occurs in first 6 months

---

### Analytics 5: Category Leaders

**Purpose:** Identify top-performing products within each category

**File Location:** `03_advanced_analytics.sql` (Lines 329-406)

**Queries Included:**
1. **Top 3 Products per Category** (Lines 334-361)
2. **Product vs. Category Average Comparison** (Lines 365-406)

**SQL Techniques:**
- `RANK() ... PARTITION BY category` - Category-wise ranking
- Filtering with `WHERE revenue_rank <= 3`
- Category-level aggregations
- Performance index calculations

**Business Value:**
- Feature top products in category pages
- Identify category growth opportunities
- Optimize product positioning
- Benchmark product performance

---

### Analytics 6: MoM Growth

**Purpose:** Month-over-month and year-over-year growth analysis

**File Location:** `03_advanced_analytics.sql` (Lines 410-505)

**Queries Included:**
1. **Monthly Sales Trend with YoY Comparison** (Lines 415-453)
2. **MoM Growth Rate with Trend Analysis** (Lines 457-505)

**SQL Techniques:**
- `LAG()` with `PARTITION BY month ORDER BY year` for YoY
- Date functions: `DATEPART()`, `FORMAT()`
- Growth rate formulas
- Trend calculations

**Business Applications:**
- Identify growth trends
- Seasonal pattern detection
- Goal setting and forecasting
- Performance monitoring

---

### Analytics 7: Cohort Analysis

**Purpose:** Track customer retention and behavior by acquisition cohort

**File Location:** `03_advanced_analytics.sql` (Lines 509-588)

**Queries Included:**
1. **Cohort Retention Analysis** (Lines 514-563)
2. **Repeat Purchase Rate by Cohort** (Lines 567-588)

**SQL Techniques:**
- Date-based cohort creation
- `DATEDIFF()` for months since cohort
- Retention rate calculations
- Cohort-level aggregations

**Key Metrics:**
- Month 0 (acquisition): 100%
- Month 1 retention: ~68-75%
- Month 3 retention: ~40-50%
- Month 12 retention: ~18-25%

**Business Insights:**
> Cohorts with high Month-1 retention (>70%) show 2x better Month-12 retention. First 90 days critical for engagement.

---

### Analytics 8: Seasonal Trends

**Purpose:** Identify seasonal patterns for demand planning

**File Location:** `03_advanced_analytics.sql` (Lines 592-722)

**Queries Included:**
1. **Seasonal Patterns by Quarter** (Lines 597-634)
2. **Day of Week Analysis** (Lines 638-682)
3. **Year-over-Year Seasonal Comparison** (Lines 686-722)

**SQL Techniques:**
- `DATEPART()` for quarter/month extraction
- `DATENAME()` for day names
- Pivot-like aggregation with CASE
- Variance from average calculations

**Seasonal Insights:**
- Q4 (Holiday): 40% of annual revenue
- Weekends: 45% of weekly sales
- Summer spike: +18% over baseline
- Post-holiday dip: -25% in January

---

### Analytics 9: Market Basket Analysis

**Purpose:** Identify products frequently purchased together

**File Location:** `03_advanced_analytics.sql` (Lines 726-799)

**Queries Included:**
1. **Frequently Purchased Together** (Lines 731-755)
2. **Customer Segment Performance** (Lines 759-799)

**SQL Techniques:**
- Self-join on order_items
- Product pair identification (`p1.product_id < p2.product_id`)
- Affinity percentage calculations
- Segment comparison analysis

**Cross-Sell Opportunities:**
> 73% of headphone buyers also purchase phone cases. 58% of laptop buyers add screen protectors. Bundle recommendations can increase AOV by $25-40.

---

### Analytics 10: KPI Dashboard

**Purpose:** High-level business metrics for executive reporting

**File Location:** `03_advanced_analytics.sql` (Lines 803-873)

**Queries Included:**
1. **Overall Business KPI Dashboard** (Lines 808-824)
2. **Category Performance Scorecard** (Lines 828-873)

**Key Metrics:**
- Total revenue, customers, orders
- Average order value (AOV)
- Revenue per customer
- Orders per customer
- Customer conversion rate
- Category-level performance scores

**Business Value:**
- Executive-level reporting
- Quick health check
- Performance benchmarking
- Strategic decision support

---

## 🎯 SQL Techniques Summary

### Complexity by Technique

| Technique | Difficulty | Use Cases | Example Queries |
|-----------|-----------|-----------|-----------------|
| Basic Aggregation | ⭐ | Totals, averages | Q1 partial |
| Multi-table Joins | ⭐⭐ | Combining data | Q1, Q2 |
| Subqueries | ⭐⭐ | Filtering, comparisons | Throughout |
| CTEs | ⭐⭐⭐ | Complex logic organization | Q2, Q3, Q5, Q6 |
| Window Functions | ⭐⭐⭐⭐ | Rankings, running totals | Q1, Q3, Q4 |
| Multi-level CTEs | ⭐⭐⭐⭐⭐ | Staged calculations | Q5, Q6 |
| Recursive CTEs | ⭐⭐⭐⭐⭐ | Hierarchical data | (Not used here) |

---

## 📊 Business Impact Matrix

| Query | Business Value | Frequency | Stakeholder |
|-------|---------------|-----------|-------------|
| Q1 - Category Performance | High | Weekly | Product Team |
| Q2 - Top Customers | High | Daily | Sales/CRM |
| Q3 - Repeat Rate | Medium | Monthly | Marketing |
| Q4 - Sales Days | Medium | Weekly | Operations |
| Q5 - CLV | High | Monthly | Finance/Strategy |
| Q6 - Churn Risk | Critical | Weekly | Retention Team |

---

## 🔗 Related Documentation

- [README.md](README.md) - Project overview
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) - Schema details
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [SAMPLE_OUTPUTS.md](SAMPLE_OUTPUTS.md) - Example results

---

**Version:** 1.0  
**Last Updated:** 2025-12-13  
**Author:** Pedro24681
