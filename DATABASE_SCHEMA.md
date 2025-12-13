# 📋 Database Schema Documentation

## Overview

The E-Commerce Analytics database follows a **normalized relational design** optimized for analytical queries while maintaining data integrity. The schema supports comprehensive business intelligence operations including customer analytics, product performance tracking, and order analysis.

**Database Name:** `ecommerce_analytics`  
**Database System:** MySQL 8.0+ / PostgreSQL 12+  
**Design Pattern:** Star Schema (Fact & Dimension Tables)  
**Normalization Level:** 3NF (Third Normal Form)

---

## 📊 Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     E-COMMERCE DATABASE SCHEMA                      │
└─────────────────────────────────────────────────────────────────────┘

┌────────────────────────┐
│      Customers         │ ◄─────────┐
│  (Dimension Table)     │           │
├────────────────────────┤           │
│ PK: CustomerID         │           │
│     CustomerName       │           │
│     Email (UNIQUE)     │           │  1:N
│     Country            │           │
│     City               │           │
│     SignUpDate         │           │
│     LifetimeValue      │           │
│     LastPurchaseDate   │           │
│     IsActive           │           │
└────────────────────────┘           │
                                      │
                                      │
                          ┌───────────┴─────────┐
                          │      Orders         │
                          │   (Fact Table)      │
                          ├─────────────────────┤
                          │ PK: OrderID         │
                          │ FK: CustomerID      │
                          │     OrderDate       │
                          │     TotalAmount     │
                          │     OrderStatus     │
                          │     ShippingAddress │
                          └─────────┬───────────┘
                                    │
                                    │ 1:N
                                    │
                          ┌─────────▼───────────┐
                          │   Order_Details     │
                          │   (Fact Table)      │
                          ├─────────────────────┤
                          │ PK: OrderDetailID   │
                          │ FK: OrderID         │
                          │ FK: ProductID       │
                          │     Quantity        │
                          │     UnitPrice       │
                          │     LineTotal       │ ◄── GENERATED
                          └─────────┬───────────┘
                                    │
                                    │ N:1
                                    │
┌────────────────────────┐          │
│      Products          │ ◄────────┘
│  (Dimension Table)     │
├────────────────────────┤
│ PK: ProductID          │
│     ProductName        │
│     Category           │
│     Price              │
│     StockQuantity      │
│     Supplier           │
│     CreatedDate        │
└────────────────────────┘
```

---

## 📁 Table Specifications

### 1. Customers (Dimension Table)

**Purpose:** Master table for customer data, demographics, and lifetime metrics.

**Schema:**

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `CustomerID` | VARCHAR(10) | PRIMARY KEY | Unique customer identifier (e.g., C001) |
| `CustomerName` | VARCHAR(100) | NOT NULL | Full name of the customer |
| `Email` | VARCHAR(100) | UNIQUE, NOT NULL | Email address for communication |
| `Country` | VARCHAR(50) | | Customer's country of residence |
| `City` | VARCHAR(50) | | Customer's city |
| `SignUpDate` | DATE | NOT NULL | Date when customer registered |
| `LifetimeValue` | DECIMAL(10,2) | DEFAULT 0.00 | Total cumulative spending |
| `LastPurchaseDate` | DATE | | Date of most recent order |
| `IsActive` | BOOLEAN | DEFAULT TRUE | Active status flag |

**Indexes:**
- `PRIMARY KEY (CustomerID)` - Unique customer identification
- `INDEX idx_customer_email (Email)` - Fast email lookups
- `INDEX idx_customer_signup (SignUpDate)` - Date range queries
- `INDEX idx_customer_country (Country)` - Geographic analysis

**Sample Data:**
```sql
CustomerID | CustomerName   | Email                    | Country | SignUpDate  | LifetimeValue
-----------+----------------+--------------------------+---------+-------------+--------------
C001       | John Anderson  | john.anderson@email.com  | USA     | 2023-01-15  | 2450.50
C002       | Sarah Mitchell | sarah.mitchell@email.com | USA     | 2023-02-20  | 3120.75
```

**Business Rules:**
- Email must be unique (one account per email)
- CustomerID follows pattern: C + 3-digit number
- LifetimeValue updated via triggers or batch processes
- IsActive defaults to TRUE; set FALSE for closed accounts

---

### 2. Products (Dimension Table)

**Purpose:** Product catalog with pricing, inventory, and categorization.

**Schema:**

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `ProductID` | VARCHAR(10) | PRIMARY KEY | Unique product identifier (e.g., P001) |
| `ProductName` | VARCHAR(150) | NOT NULL | Product display name |
| `Category` | VARCHAR(50) | NOT NULL | Product category classification |
| `Price` | DECIMAL(10,2) | NOT NULL, CHECK > 0 | Current selling price |
| `StockQuantity` | INT | DEFAULT 0, CHECK >= 0 | Available inventory units |
| `Supplier` | VARCHAR(100) | | Vendor/supplier name |
| `CreatedDate` | DATE | NOT NULL | Date product added to catalog |

**Indexes:**
- `PRIMARY KEY (ProductID)` - Unique product identification
- `INDEX idx_product_category (Category)` - Category filtering
- `INDEX idx_product_price (Price)` - Price range queries
- `INDEX idx_product_name (ProductName)` - Search functionality

**Sample Data:**
```sql
ProductID | ProductName             | Category    | Price  | StockQuantity | Supplier
----------+-------------------------+-------------+--------+---------------+--------------
P001      | Wireless Headphones Pro | Electronics | 129.99 | 45            | TechSupply Co
P002      | USB-C Cable 3m          | Electronics | 19.99  | 150           | CableWorks
```

**Business Rules:**
- ProductID follows pattern: P + 3-digit number
- Price must be positive (> 0)
- StockQuantity cannot be negative
- Category standardized (Electronics, Accessories, etc.)

---

### 3. Orders (Fact Table)

**Purpose:** Order header information capturing transaction details.

**Schema:**

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `OrderID` | VARCHAR(10) | PRIMARY KEY | Unique order identifier (e.g., O001) |
| `CustomerID` | VARCHAR(10) | FOREIGN KEY → Customers | Customer who placed order |
| `OrderDate` | DATE | NOT NULL | Date order was placed |
| `TotalAmount` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | Total order value (USD) |
| `OrderStatus` | VARCHAR(20) | DEFAULT 'Completed' | Order fulfillment status |
| `ShippingAddress` | VARCHAR(255) | | Delivery address |

**Indexes:**
- `PRIMARY KEY (OrderID)` - Unique order identification
- `INDEX idx_order_date (OrderDate)` - Time-series analysis
- `INDEX idx_order_customer (CustomerID)` - Customer order history
- `INDEX idx_order_status (OrderStatus)` - Status filtering

**Foreign Keys:**
- `CustomerID` → `Customers(CustomerID)` (ON DELETE RESTRICT)

**Sample Data:**
```sql
OrderID | CustomerID | OrderDate  | TotalAmount | OrderStatus | ShippingAddress
--------+------------+------------+-------------+-------------+------------------
O001    | C001       | 2023-02-10 | 189.97      | Completed   | 123 Main St, NY
O002    | C002       | 2023-02-15 | 159.96      | Completed   | 456 Oak Ave, LA
```

**Business Rules:**
- OrderID follows pattern: O + 3-digit number
- TotalAmount must be non-negative
- OrderStatus values: 'Completed', 'Pending', 'Cancelled', 'Refunded'
- Cascading constraints prevent deletion of referenced customers

---

### 4. Order_Details (Fact Table)

**Purpose:** Line-item details for each order (order-product relationship).

**Schema:**

| Column Name | Data Type | Constraints | Description |
|------------|-----------|-------------|-------------|
| `OrderDetailID` | VARCHAR(10) | PRIMARY KEY | Unique line item identifier (e.g., OD001) |
| `OrderID` | VARCHAR(10) | FOREIGN KEY → Orders | Parent order reference |
| `ProductID` | VARCHAR(10) | FOREIGN KEY → Products | Product purchased |
| `Quantity` | INT | NOT NULL, CHECK > 0 | Units ordered |
| `UnitPrice` | DECIMAL(10,2) | NOT NULL, CHECK >= 0 | Price per unit at order time |
| `LineTotal` | DECIMAL(10,2) | GENERATED (Quantity * UnitPrice) | Calculated line total |

**Indexes:**
- `PRIMARY KEY (OrderDetailID)` - Unique line item identification
- `INDEX idx_orderdetail_order (OrderID)` - Order line lookup
- `INDEX idx_orderdetail_product (ProductID)` - Product sales analysis

**Foreign Keys:**
- `OrderID` → `Orders(OrderID)` (ON DELETE CASCADE)
- `ProductID` → `Products(ProductID)` (ON DELETE RESTRICT)

**Sample Data:**
```sql
OrderDetailID | OrderID | ProductID | Quantity | UnitPrice | LineTotal
--------------+---------+-----------+----------+-----------+----------
OD001         | O001    | P001      | 1        | 129.99    | 129.99
OD002         | O001    | P002      | 3        | 19.99     | 59.97
```

**Business Rules:**
- OrderDetailID follows pattern: OD + 3-digit number
- Quantity must be positive (> 0)
- UnitPrice captures price at order time (may differ from current price)
- LineTotal automatically calculated as GENERATED ALWAYS column
- Cascade delete: removing order removes its line items

---

## 🔗 Relationships & Cardinality

### One-to-Many Relationships

**1. Customers → Orders (1:N)**
- One customer can place multiple orders
- Each order belongs to exactly one customer
- Foreign Key: `Orders.CustomerID` → `Customers.CustomerID`
- Business Logic: Customer history tracking, loyalty analysis

**2. Orders → Order_Details (1:N)**
- One order contains multiple line items
- Each line item belongs to exactly one order
- Foreign Key: `Order_Details.OrderID` → `Orders.OrderID`
- Business Logic: Multi-product orders, basket analysis

**3. Products → Order_Details (1:N)**
- One product appears in multiple orders
- Each line item references exactly one product
- Foreign Key: `Order_Details.ProductID` → `Products.ProductID`
- Business Logic: Product performance tracking

### Many-to-Many Relationships

**Customers ↔ Products (M:N)**
- Implemented through Order_Details as junction table
- Allows tracking which customers bought which products
- Enables cross-sell and recommendation analysis

---

## 🎯 Design Rationale

### Normalization Strategy

**3rd Normal Form (3NF) Compliance:**
- ✅ No repeating groups (1NF)
- ✅ No partial dependencies (2NF)
- ✅ No transitive dependencies (3NF)

**Trade-offs:**
- Prioritizes data integrity over query performance
- Some denormalization for common metrics (LifetimeValue)
- Calculated columns (LineTotal) for consistency

### Star Schema Elements

**Fact Tables:**
- `Orders` - Transaction facts
- `Order_Details` - Line-item facts

**Dimension Tables:**
- `Customers` - Customer attributes
- `Products` - Product attributes

This hybrid approach enables:
- Fast aggregation queries (star schema benefit)
- Normalized data integrity (relational benefit)
- Flexible analytical operations

### Indexing Strategy

**Performance Optimization:**
- Primary keys for unique identification
- Foreign keys for join optimization
- Date columns for time-series queries
- Category columns for group-by operations

**Index Selection Criteria:**
- Columns frequently used in WHERE clauses
- Join columns (foreign keys)
- Columns used in ORDER BY
- High-selectivity columns

---

## 🔒 Data Integrity Constraints

### Referential Integrity

**Cascading Rules:**

```sql
Orders.CustomerID → Customers.CustomerID
  ON DELETE RESTRICT   -- Cannot delete customer with orders
  ON UPDATE CASCADE    -- Update propagates to orders

Order_Details.OrderID → Orders.OrderID
  ON DELETE CASCADE    -- Deleting order removes line items
  ON UPDATE CASCADE    -- Update propagates to details

Order_Details.ProductID → Products.ProductID
  ON DELETE RESTRICT   -- Cannot delete product in orders
  ON UPDATE CASCADE    -- Update propagates to details
```

### Check Constraints

- `Price > 0` - No free or negative-priced products
- `StockQuantity >= 0` - Inventory cannot be negative
- `TotalAmount >= 0` - No negative order totals
- `Quantity > 0` - Must order at least one unit

### Unique Constraints

- `Customers.Email` - One account per email
- `CustomerID, ProductID, OrderID` - Primary key uniqueness

---

## 📈 Calculated & Derived Fields

### Generated Columns

**Order_Details.LineTotal:**
```sql
LineTotal DECIMAL(10,2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED
```
- Automatically calculated on insert/update
- Stored in database for query performance
- Ensures consistency across all records

### Maintained Aggregates

**Customers.LifetimeValue:**
- Updated via application logic or triggers
- Denormalized for performance (avoids SUM aggregation)
- Requires periodic reconciliation

**Customers.LastPurchaseDate:**
- Updated on new orders
- Enables recency analysis without scanning orders
- Critical for churn prediction

---

## 🔍 Query Patterns

### Common Access Patterns

**Customer Analysis:**
```sql
-- Find high-value customers
SELECT * FROM Customers 
WHERE LifetimeValue > 5000 
ORDER BY LifetimeValue DESC;
```

**Order History:**
```sql
-- Customer order timeline
SELECT o.*, od.* 
FROM Orders o
INNER JOIN Order_Details od ON o.OrderID = od.OrderID
WHERE o.CustomerID = 'C001'
ORDER BY o.OrderDate;
```

**Product Performance:**
```sql
-- Best-selling products
SELECT p.ProductName, SUM(od.Quantity) AS TotalSold
FROM Products p
INNER JOIN Order_Details od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSold DESC;
```

---

## 🛠️ Maintenance Considerations

### Data Growth Projections

| Table | Current Size | Annual Growth | 5-Year Projection |
|-------|--------------|---------------|-------------------|
| Customers | 15 rows | +20% | ~37 rows |
| Products | 15 rows | +15% | ~30 rows |
| Orders | 25 rows | +100% | ~800 rows |
| Order_Details | 67 rows | +100% | ~2,144 rows |

### Optimization Opportunities

**Partitioning:**
- Orders table: Partition by OrderDate (yearly/monthly)
- Improves query performance for time-range filters
- Facilitates archival of historical data

**Archival Strategy:**
- Move orders >2 years old to archive tables
- Maintains performance on active data
- Preserves historical data for analysis

**Index Maintenance:**
- Rebuild fragmented indexes quarterly
- Analyze query plans for missing indexes
- Remove unused indexes

---

## 📝 Change Log

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-12-13 | Initial schema documentation |

---

## 🔗 Related Documentation

- [README.md](README.md) - Project overview
- [QUERIES_GUIDE.md](QUERIES_GUIDE.md) - Query documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design
- [setup.sql](setup.sql) - Database setup script

---

**Last Updated:** 2025-12-13  
**Maintained by:** Pedro24681  
**Database Version:** MySQL 8.0+ / PostgreSQL 12+
