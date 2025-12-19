-- Database schema for the e-commerce case study
-- Setting up 4 tables: Customers, Products, Orders, and Order_Details

-- Create Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Country VARCHAR(50),
    City VARCHAR(50),
    SignUpDate DATE NOT NULL,
    LifetimeValue DECIMAL(10, 2) DEFAULT 0,
    LastPurchaseDate DATE,
    IsActive BOOLEAN DEFAULT TRUE
);

-- Create Products Table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductName VARCHAR(150) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    StockQuantity INT DEFAULT 0,
    Supplier VARCHAR(100),
    CreatedDate DATE NOT NULL
);

-- Create Orders Table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    OrderStatus VARCHAR(20) DEFAULT 'Completed',
    ShippingAddress VARCHAR(255),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- Create Order_Details Table
CREATE TABLE Order_Details (
    OrderDetailID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10, 2) NOT NULL,
    LineTotal DECIMAL(10, 2) GENERATED ALWAYS AS (Quantity * UnitPrice) STORED,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create Indexes for Performance
CREATE INDEX idx_customer_signup ON Customers(SignUpDate);
CREATE INDEX idx_order_date ON Orders(OrderDate);
CREATE INDEX idx_order_customer ON Orders(CustomerID);
CREATE INDEX idx_orderdetail_order ON Order_Details(OrderID);
CREATE INDEX idx_orderdetail_product ON Order_Details(ProductID);
CREATE INDEX idx_product_category ON Products(Category);
