-- ============================================================================
-- E-COMMERCE DATABASE SETUP SCRIPT
-- ============================================================================
-- This script sets up the entire database for the e-commerce case study. 
-- It creates all the tables, loads in the sample data, and sets up indexes.
-- Run this once and you're good to go—no manual table creation needed. 
--
-- Works with:  MySQL 8.0+ or PostgreSQL 12+ (just swap a couple date functions)
-- ============================================================================
-- ============================================================================
-- STEP 1: DATABASE INITIALIZATION
-- ============================================================================
-- First thing:  drop the database if it exists (clean slate) and create a fresh one. 
-- This makes it safe to run the script multiple times without conflicts. 

DROP DATABASE IF EXISTS ecommerce_analytics;
CREATE DATABASE ecommerce_analytics;
USE ecommerce_analytics;

-- Display confirmation
SELECT 'Database created successfully' AS Status;


-- ============================================================================
-- STEP 2: CREATE TABLES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Customers Table
-- ----------------------------------------------------------------------------
-- Customers table – stores who's buying, where they're from, and how valuable they are
CREATE TABLE Customers (
CREATE TABLE Customers (
    CustomerID VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Country VARCHAR(50),
    City VARCHAR(50),
    SignUpDate DATE NOT NULL,
    LifetimeValue DECIMAL(10, 2) DEFAULT 0.00,
    LastPurchaseDate DATE,
    IsActive BOOLEAN DEFAULT TRUE,
    INDEX idx_customer_email (Email),
    INDEX idx_customer_signup (SignUpDate),
    INDEX idx_customer_country (Country)
);

-- ----------------------------------------------------------------------------
-- Products Table
-- ----------------------------------------------------------------------------
-- Products table – what we're selling, how much it costs, and how much we have in stock
CREATE TABLE Products (
CREATE TABLE Products (
    ProductID VARCHAR(10) PRIMARY KEY,
    ProductName VARCHAR(150) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL CHECK (Price > 0),
    StockQuantity INT DEFAULT 0 CHECK (StockQuantity >= 0),
    Supplier VARCHAR(100),
    CreatedDate DATE NOT NULL,
    INDEX idx_product_category (Category),
    INDEX idx_product_price (Price),
    INDEX idx_product_name (ProductName)
);

-- Orders table – every order a customer places, total spent, and status
CREATE TABLE Orders (
-- Orders Table
-- ----------------------------------------------------------------------------
-- Order header information with customer relationships
CREATE TABLE Orders (
    OrderID VARCHAR(10) PRIMARY KEY,
    CustomerID VARCHAR(10) NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL CHECK (TotalAmount >= 0),
    OrderStatus VARCHAR(20) DEFAULT 'Completed',
    ShippingAddress VARCHAR(255),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    INDEX idx_order_date (OrderDate),
    INDEX idx_order_customer (CustomerID),
    -- Order_Details table – breaks down each order into individual line items (which products, how many, what price)
CREATE TABLE Order_Details (
);

-- ----------------------------------------------------------------------------
-- Order_Details Table
-- ----------------------------------------------------------------------------
-- Order line items with product details
CREATE TABLE Order_Details (
    OrderDetailID VARCHAR(10) PRIMARY KEY,
    OrderID VARCHAR(10) NOT NULL,
    ProductID VARCHAR(10) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(10, 2) NOT NULL CHECK (UnitPrice >= 0),
    LineTotal DECIMAL(10, 2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    INDEX idx_orderdetail_order (OrderID),
    INDEX idx_orderdetail_product (ProductID)
);

SELECT 'Tables created successfully' AS Status;


-- ============================================================================
-- STEP 3: LOAD SAMPLE DATA
-- ============================================================================

-- ----------------------------------------------------------------------------
-- I'm using INSERT statements here so the script works on any database. 
-- In production, you'd use LOAD DATA INFILE for speed, but this is more portable.

INSERT INTO Customers (CustomerID, CustomerName, Email, Country, City, SignUpDate, LifetimeValue, LastPurchaseDate, IsActive) VALUES
('C001', 'John Anderson', 'john.anderson@email.com', 'USA', 'New York', '2023-01-15', 2450.50, '2025-12-08', TRUE),
('C002', 'Sarah Mitchell', 'sarah.mitchell@email.com', 'USA', 'Los Angeles', '2023-02-20', 3120.75, '2025-12-09', TRUE),
('C003', 'Michael Chen', 'michael.chen@email.com', 'Canada', 'Toronto', '2023-03-10', 1895.25, '2025-12-05', TRUE),
('C004', 'Emma Watson', 'emma.watson@email.com', 'UK', 'London', '2023-04-05', 2789.00, '2025-12-07', TRUE),
('C005', 'David Rodriguez', 'david.rodriguez@email.com', 'USA', 'Miami', '2023-05-12', 4235.80, '2025-12-10', TRUE),
('C006', 'Lisa Johnson', 'lisa.johnson@email.com', 'Canada', 'Vancouver', '2023-06-08', 1567.30, '2025-11-28', TRUE),
('C007', 'James Wilson', 'james.wilson@email.com', 'UK', 'Manchester', '2023-07-15', 3890.45, '2025-12-06', TRUE),
('C008', 'Maria Garcia', 'maria.garcia@email.com', 'USA', 'Chicago', '2023-08-20', 2145.90, '2025-12-04', TRUE),
('C009', 'Robert Taylor', 'robert.taylor@email.com', 'Australia', 'Sydney', '2023-09-10', 5420.60, '2025-12-09', TRUE),
('C010', 'Jennifer Lee', 'jennifer.lee@email.com', 'USA', 'Seattle', '2023-10-05', 1978.25, '2025-11-30', TRUE);

-- Add more sample customers
INSERT INTO Customers (CustomerID, CustomerName, Email, Country, City, SignUpDate, LifetimeValue, LastPurchaseDate, IsActive) VALUES
('C011', 'William Brown', 'william.brown@email.com', 'UK', 'Birmingham', '2023-11-12', 3250.00, '2025-12-03', TRUE),
('C012', 'Patricia Davis', 'patricia.davis@email.com', 'Canada', 'Montreal', '2023-12-01', 1845.50, '2025-11-25', TRUE),
('C013', 'Thomas Martinez', 'thomas.martinez@email.com', 'USA', 'Boston', '2024-01-08', 2890.75, '2025-12-08', TRUE),
('C014', 'Linda Anderson', 'linda.anderson@email.com', 'Australia', 'Melbourne', '2024-02-14', 4120.40, '2025-12-07', TRUE),
('C015', 'Charles Wilson', 'charles.wilson@email.com', 'USA', 'San Francisco', '2024-03-20', 3560.90, '2025-12-09', TRUE);

SELECT CONCAT('Loaded ', COUNT(*), ' customer records') AS Status FROM Customers;

-- ----------------------------------------------------------------------------
-- Load Products Data
-- ----------------------------------------------------------------------------
INSERT INTO Products (ProductID, ProductName, Category, Price, StockQuantity, Supplier, CreatedDate) VALUES
('P001', 'Wireless Headphones Pro', 'Electronics', 129.99, 45, 'TechSupply Co', '2022-05-10'),
('P002', 'USB-C Cable 3m', 'Electronics', 19.99, 150, 'CableWorks', '2022-06-15'),
('P003', 'Phone Case Premium', 'Accessories', 24.99, 200, 'AccessoryHub', '2022-07-20'),
('P004', 'Screen Protector Tempered Glass', 'Accessories', 9.99, 300, 'AccessoryHub', '2022-08-10'),
('P005', 'Bluetooth Speaker Portable', 'Electronics', 79.99, 60, 'TechSupply Co', '2022-09-05'),
('P006', 'Laptop Stand Aluminum', 'Accessories', 45.99, 85, 'OfficeMax Pro', '2022-10-12'),
('P007', 'Wireless Mouse Ergonomic', 'Electronics', 34.99, 120, 'TechSupply Co', '2022-11-08'),
('P008', 'Mechanical Keyboard RGB', 'Electronics', 89.99, 55, 'TechSupply Co', '2023-01-15'),
('P009', 'USB Hub 7-Port', 'Electronics', 29.99, 95, 'CableWorks', '2023-02-20'),
('P010', 'Webcam 1080p HD', 'Electronics', 69.99, 40, 'TechSupply Co', '2023-03-10');

-- Add more products
INSERT INTO Products (ProductID, ProductName, Category, Price, StockQuantity, Supplier, CreatedDate) VALUES
('P011', 'Smart Watch Fitness', 'Electronics', 199.99, 35, 'TechSupply Co', '2023-04-05'),
('P012', 'Power Bank 20000mAh', 'Electronics', 39.99, 100, 'TechSupply Co', '2023-05-12'),
('P013', 'Phone Holder Car Mount', 'Accessories', 15.99, 180, 'AccessoryHub', '2023-06-08'),
('P014', 'Tablet Case Leather', 'Accessories', 35.99, 70, 'AccessoryHub', '2023-07-15'),
('P015', 'Portable SSD 1TB', 'Electronics', 149.99, 50, 'TechSupply Co', '2023-08-20');

SELECT CONCAT('Loaded ', COUNT(*), ' product records') AS Status FROM Products;

-- ----------------------------------------------------------------------------
-- Load Orders Data
-- ----------------------------------------------------------------------------
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus, ShippingAddress) VALUES
('O001', 'C001', '2023-02-10', 189.97, 'Completed', '123 Main St, New York, NY 10001'),
('O002', 'C002', '2023-02-15', 159.96, 'Completed', '456 Oak Ave, Los Angeles, CA 90001'),
('O003', 'C003', '2023-03-05', 209.95, 'Completed', '789 Maple Dr, Toronto, ON M5V 3A8'),
('O004', 'C001', '2023-04-12', 299.90, 'Completed', '123 Main St, New York, NY 10001'),
('O005', 'C004', '2023-05-20', 449.85, 'Completed', '321 Park Lane, London, UK SW1A 1AA'),
('O006', 'C005', '2023-06-08', 379.92, 'Completed', '555 Beach Rd, Miami, FL 33101'),
('O007', 'C002', '2023-07-15', 524.88, 'Completed', '456 Oak Ave, Los Angeles, CA 90001'),
('O008', 'C006', '2023-08-22', 234.95, 'Completed', '777 Mountain View, Vancouver, BC V6B 1A1'),
('O009', 'C007', '2023-09-10', 689.85, 'Completed', '999 Queen St, Manchester, UK M1 1AA'),
('O010', 'C003', '2023-10-05', 345.90, 'Completed', '789 Maple Dr, Toronto, ON M5V 3A8');

-- Add more orders to create meaningful analytics
-- NOTE: Dates span from 2023 to 2025. For time-series queries to work correctly,
-- you may want to update these dates to be relative to your current date.
-- For example, recent orders should be within the last 30-90 days for
-- "active customer" queries to return meaningful results.
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus, ShippingAddress) VALUES
('O011', 'C008', '2023-11-12', 289.95, 'Completed', '111 Lake St, Chicago, IL 60601'),
('O012', 'C009', '2023-12-01', 789.80, 'Completed', '222 Harbor Dr, Sydney, NSW 2000'),
('O013', 'C001', '2024-01-08', 425.75, 'Completed', '123 Main St, New York, NY 10001'),
('O014', 'C010', '2024-02-14', 356.85, 'Completed', '333 Pine Ave, Seattle, WA 98101'),
('O015', 'C005', '2024-03-20', 678.90, 'Completed', '555 Beach Rd, Miami, FL 33101'),
('O016', 'C011', '2024-04-05', 445.80, 'Completed', '444 Station Rd, Birmingham, UK B1 1AA'),
('O017', 'C002', '2024-05-12', 523.95, 'Completed', '456 Oak Ave, Los Angeles, CA 90001'),
('O018', 'C012', '2024-06-08', 298.75, 'Completed', '666 River St, Montreal, QC H2Y 1A1'),
('O019', 'C013', '2024-07-15', 567.90, 'Completed', '888 Bay St, Boston, MA 02101'),
('O020', 'C009', '2024-08-22', 845.70, 'Completed', '222 Harbor Dr, Sydney, NSW 2000');

-- Recent orders for better analytics
INSERT INTO Orders (OrderID, CustomerID, OrderDate, TotalAmount, OrderStatus, ShippingAddress) VALUES
('O021', 'C014', '2025-09-10', 723.85, 'Completed', '777 Collins St, Melbourne, VIC 3000'),
('O022', 'C015', '2025-10-05', 634.90, 'Completed', '999 Market St, San Francisco, CA 94102'),
('O023', 'C001', '2025-11-12', 489.95, 'Completed', '123 Main St, New York, NY 10001'),
('O024', 'C007', '2025-11-28', 756.80, 'Completed', '999 Queen St, Manchester, UK M1 1AA'),
('O025', 'C005', '2025-12-08', 892.45, 'Completed', '555 Beach Rd, Miami, FL 33101');

SELECT CONCAT('Loaded ', COUNT(*), ' order records') AS Status FROM Orders;

-- ----------------------------------------------------------------------------
-- Load Order Details Data
-- ----------------------------------------------------------------------------
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD001', 'O001', 'P001', 1, 129.99),
('OD002', 'O001', 'P002', 3, 19.99),
('OD003', 'O002', 'P003', 2, 24.99),
('OD004', 'O002', 'P007', 1, 34.99),
('OD005', 'O002', 'P004', 5, 9.99),
('OD006', 'O003', 'P005', 1, 79.99),
('OD007', 'O003', 'P001', 1, 129.99),
('OD008', 'O004', 'P008', 2, 89.99),
('OD009', 'O004', 'P006', 2, 45.99),
('OD010', 'O005', 'P001', 2, 129.99);

-- Add more order details
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD011', 'O005', 'P010', 1, 69.99),
('OD012', 'O005', 'P009', 4, 29.99),
('OD013', 'O006', 'P005', 2, 79.99),
('OD014', 'O006', 'P011', 1, 199.99),
('OD015', 'O007', 'P008', 3, 89.99),
('OD016', 'O007', 'P012', 5, 39.99),
('OD017', 'O008', 'P006', 3, 45.99),
('OD018', 'O008', 'P013', 5, 15.99),
('OD019', 'O009', 'P001', 2, 129.99),
('OD020', 'O009', 'P011', 2, 199.99);

-- Additional line items for complex orders
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD021', 'O009', 'P015', 1, 149.99),
('OD022', 'O010', 'P007', 4, 34.99),
('OD023', 'O010', 'P012', 4, 39.99),
('OD024', 'O010', 'P003', 3, 24.99),
('OD025', 'O011', 'P008', 2, 89.99),
('OD026', 'O011', 'P009', 3, 29.99),
('OD027', 'O012', 'P011', 3, 199.99),
('OD028', 'O012', 'P015', 1, 149.99),
('OD029', 'O013', 'P001', 1, 129.99),
('OD030', 'O013', 'P005', 2, 79.99);

-- More recent orders details
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD031', 'O013', 'P014', 4, 35.99),
('OD032', 'O014', 'P010', 3, 69.99),
('OD033', 'O014', 'P012', 2, 39.99),
('OD034', 'O015', 'P011', 2, 199.99),
('OD035', 'O015', 'P008', 1, 89.99),
('OD036', 'O015', 'P015', 2, 149.99),
('OD037', 'O016', 'P001', 2, 129.99),
('OD038', 'O016', 'P007', 3, 34.99),
('OD039', 'O016', 'P006', 2, 45.99),
('OD040', 'O017', 'P011', 1, 199.99);

-- Final batch of order details
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD041', 'O017', 'P008', 2, 89.99),
('OD042', 'O017', 'P012', 3, 39.99),
('OD043', 'O018', 'P005', 1, 79.99),
('OD044', 'O018', 'P013', 8, 15.99),
('OD045', 'O018', 'P003', 3, 24.99),
('OD046', 'O019', 'P011', 1, 199.99),
('OD047', 'O019', 'P015', 2, 149.99),
('OD048', 'O019', 'P010', 1, 69.99),
('OD049', 'O020', 'P001', 3, 129.99),
('OD050', 'O020', 'P008', 2, 89.99);

-- Most recent orders
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD051', 'O020', 'P011', 2, 199.99),
('OD052', 'O021', 'P015', 3, 149.99),
('OD053', 'O021', 'P011', 1, 199.99),
('OD054', 'O021', 'P008', 1, 89.99),
('OD055', 'O022', 'P001', 2, 129.99),
('OD056', 'O022', 'P011', 1, 199.99),
('OD057', 'O022', 'P012', 5, 39.99),
('OD058', 'O023', 'P005', 3, 79.99),
('OD059', 'O023', 'P010', 2, 69.99),
('OD060', 'O023', 'P007', 2, 34.99);

-- Final orders
INSERT INTO Order_Details (OrderDetailID, OrderID, ProductID, Quantity, UnitPrice) VALUES
('OD061', 'O024', 'P011', 2, 199.99),
('OD062', 'O024', 'P015', 2, 149.99),
('OD063', 'O024', 'P008', 1, 89.99),
('OD064', 'O025', 'P001', 3, 129.99),
('OD065', 'O025', 'P011', 1, 199.99),
('OD066', 'O025', 'P015', 2, 149.99),
('OD067', 'O025', 'P008', 1, 89.99);

SELECT CONCAT('Loaded ', COUNT(*), ' order detail records') AS Status FROM Order_Details;


-- ============================================================================
-- STEP 4: DATA VALIDATION
-- ============================================================================

-- Display record counts
SELECT 'DATA VALIDATION SUMMARY' AS Report;

SELECT 
    'Customers' AS TableName,
    COUNT(*) AS RecordCount,
    MIN(SignUpDate) AS EarliestDate,
    MAX(SignUpDate) AS LatestDate
FROM Customers
UNION ALL
SELECT 
    'Products',
    COUNT(*),
    MIN(CreatedDate),
    MAX(CreatedDate)
FROM Products
UNION ALL
SELECT 
    'Orders',
    COUNT(*),
    MIN(OrderDate),
    MAX(OrderDate)
FROM Orders
UNION ALL
SELECT 
    'Order_Details',
    COUNT(*),
    NULL,
    NULL
FROM Order_Details;

-- Validate referential integrity
SELECT 'REFERENTIAL INTEGRITY CHECK' AS Report;

SELECT 
    'Orders with valid CustomerID' AS Check_Type,
    COUNT(*) AS Valid_Count
FROM Orders o
INNER JOIN Customers c ON o.CustomerID = c.CustomerID
UNION ALL
SELECT 
    'Order_Details with valid OrderID',
    COUNT(*)
FROM Order_Details od
INNER JOIN Orders o ON od.OrderID = o.OrderID
UNION ALL
SELECT 
    'Order_Details with valid ProductID',
    COUNT(*)
FROM Order_Details od
INNER JOIN Products p ON od.ProductID = p.ProductID;

-- Display sample data
SELECT 'SAMPLE DATA PREVIEW' AS Report;
SELECT * FROM Customers LIMIT 5;
SELECT * FROM Products LIMIT 5;
SELECT * FROM Orders LIMIT 5;
SELECT * FROM Order_Details LIMIT 5;


-- ============================================================================
-- STEP 5: QUICK ANALYTICS VERIFICATION
-- ============================================================================

SELECT 'QUICK ANALYTICS VERIFICATION' AS Report;

-- Total revenue
SELECT 
    'Total Revenue' AS Metric,
    CONCAT('$', FORMAT(SUM(TotalAmount), 2)) AS Value
FROM Orders
UNION ALL
-- Average order value
SELECT 
    'Average Order Value',
    CONCAT('$', FORMAT(AVG(TotalAmount), 2))
FROM Orders
UNION ALL
-- Total customers
SELECT 
    'Total Customers',
    COUNT(*)
FROM Customers
UNION ALL
-- Active customers (purchased in last 90 days)
SELECT 
    'Active Customers (Last 90 Days)',
    COUNT(DISTINCT CustomerID)
FROM Orders
WHERE OrderDate >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
UNION ALL
-- Total products
SELECT 
    'Total Products',
    COUNT(*)
FROM Products
UNION ALL
-- Total orders
SELECT 
    'Total Orders',
    COUNT(*)
FROM Orders;


-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================

SELECT '
================================================================================
                                                                
         DATABASE SETUP COMPLETED SUCCESSFULLY!          
                                                                
  Database: ecommerce_analytics                                
  Tables: 4 (Customers, Products, Orders, Order_Details)       
  Sample Data: Loaded and validated                            
                                                                
  Next Steps:                                                   
  1. Explore queries in 02_business_questions.sql              
  2. Try advanced analytics in 03_advanced_analytics.sql       
  3. Review QUERIES_GUIDE.md for detailed documentation        
                                                                
  Happy querying!                                            
                                                                
================================================================================
' AS 'Setup Status';

-- Display database summary
SELECT 
    (SELECT COUNT(*) FROM Customers) AS Customers,
    (SELECT COUNT(*) FROM Products) AS Products,
    (SELECT COUNT(*) FROM Orders) AS Orders,
    (SELECT COUNT(*) FROM Order_Details) AS Order_Items,
    CONCAT('$', FORMAT((SELECT SUM(TotalAmount) FROM Orders), 2)) AS Total_Revenue;
