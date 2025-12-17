# Database Schema

This file explains the tables used in this SQL e-commerce project and how they relate to each other. I created or organized these tables so it’s easy to explore business questions with joins and aggregations.


# Tables and Fields

# Customers
Stores customer details.

- **customer_id** – Unique identifier for each customer  
- **first_name** – Customer’s first name  
- **last_name** – Customer’s last name  
- **email** – Contact email  
- **join_date** – When the customer first made a purchase

# Products
Contains product details.

- **product_id** – Primary key  
- **product_name** – Name of the product  
- **category** – High-level category (ex: Electronics, Apparel)  
- **price** – Sale price

# Orders
Has information on each order.

- **order_id** – Unique identifier  
- **customer_id** – Which customer placed the order  
- **order_date** – When the order was placed  
- **status** – Completed, returned, etc.

# Order_Details
Connects orders to products.

- **order_detail_id** – Primary key  
- **order_id** – Refers to Orders  
- **product_id** – Refers to Products  
- **quantity** – Units ordered  
- **line_total** – Product price × quantity


# Relationships

- `Orders.customer_id` → Customers  
- `Order_Details.order_id` → Orders  
- `Order_Details.product_id` → Products

These relationships let me join across tables to answer real business questions like total revenue by customer or product category.
