# Ecommerce-Analysis

# 🛒 Olist E-Commerce Analysis | SQL

> Part of my data analytics portfolio — [View all projects](https://github.com/KevinProbetsado)

## Overview

An end-to-end data cleaning and analysis project using the **Brazilian Olist E-Commerce dataset** — a real-world, multi-table dataset covering orders, customers, products, payments, reviews, and sellers. This project demonstrates how raw, messy data is transformed into business-ready insights using SQL Server.

**Tools:** Microsoft SQL Server  
**Dataset:** [Olist Brazilian E-Commerce (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Skills Demonstrated:** Data Cleaning · NULL Handling · Duplicate Detection · JOINs · Aggregations · Data Transformation

---

## Dataset Overview

The Olist dataset spans 9 relational tables:

| Table | Description |
|---|---|
| `olist_orders_dataset` | Order status and timestamps |
| `olist_order_items_dataset` | Products per order with price and freight |
| `olist_order_payments_dataset` | Payment types and values |
| `olist_order_reviews_dataset` | Customer review scores and comments |
| `olist_customers_dataset` | Customer location data |
| `olist_products_dataset` | Product details and categories |
| `product_category_name_translation` | Portuguese → English category names |
| `olist_sellers_dataset` | Seller location data |
| `olist_geolocation_dataset` | ZIP code coordinates |

---

## Business Questions Answered

1. Which **product categories** generate the most revenue?
2. Who are the **top customers** by total amount paid?
3. Are there **data quality issues** in the dataset, and how were they resolved?

---

## Project Workflow

### 🔍 Section 1 — Data Exploration
Previewed all 9 tables to understand structure, column names, and data types before any transformation.

### 🧹 Section 2 — Data Cleaning

| Issue Found | Action Taken |
|---|---|
| Duplicate `order_id` in payments | Verified as expected — one order can have multiple payment types |
| 610 NULL `product_category_name` values | Replaced with `'unknown'` via `UPDATE` |
| Malformed column headers in category translation table | Renamed using `sp_rename` |
| Extra header row imported as data row | Deleted the erroneous record |
| NULLs checked across customers and orders | No critical NULLs found |

### 📊 Section 3 — Analysis

**Top 5 Product Categories by Revenue**
```sql
SELECT TOP 5
    prod_cat.product_category_name_english,
    ROUND(SUM(order_item.price), 2) AS total_revenue
FROM olist_order_items_dataset order_item
JOIN olist_products_dataset prod
    ON order_item.product_id = prod.product_id
JOIN product_category_name_translation prod_cat
    ON prod.product_category_name = prod_cat.product_category_name
GROUP BY prod_cat.product_category_name_english
ORDER BY total_revenue DESC;
```

**Top 10 Customers by Total Spend**
```sql
SELECT TOP 10
    ord.customer_id,
    UPPER(cust.customer_city) AS customer_city,
    UPPER(cust.customer_state) AS customer_state,
    ROUND(SUM(pay.payment_value), 2) AS total_paid
FROM olist_order_payments_dataset pay
JOIN olist_orders_dataset ord ON pay.order_id = ord.order_id
JOIN olist_customers_dataset cust ON ord.customer_id = cust.customer_id
GROUP BY ord.customer_id, cust.customer_city, cust.customer_state
ORDER BY total_paid DESC;
```

---

## How to Run

1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Import all CSV files into a SQL Server database named `ecommerce_practice`
3. Open `Ecommerce_Analysis.sql` and run sections sequentially in SSMS


*Dataset: Olist Store, made available on Kaggle under a CC BY-NC-SA 4.0 license.*
