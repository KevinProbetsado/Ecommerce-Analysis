# 🛒 Olist E-Commerce Analysis | SQL

> Part of my data analytics portfolio — [View all projects](https://github.com/KevinProbetsado)

## Overview

An end-to-end data cleaning and analysis project using the **Brazilian Olist E-Commerce dataset** — a real-world, multi-table dataset covering orders, customers, products, payments, reviews, and sellers. This project investigates revenue trends, delivery performance, payment behavior, and seller concentration using SQL Server.

**Tools:** Microsoft SQL Server  
**Dataset:** [Olist Brazilian E-Commerce (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Skills Demonstrated:** Data Cleaning · NULL Handling · Duplicate Detection · JOINs · Aggregations · DATEDIFF · Data Transformation

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
2. Who are the **top 10 customers** by total amount paid?
3. What is the **monthly revenue trend** over time?
4. Which **payment method** is most used?
5. Which **states have the slowest delivery times**?
6. Which **sellers** generate the most revenue?
7. What is the **average review score** by product category? *(in progress)*
8. What **percentage of orders** are delivered on time? *(in progress)*

---

## Key Findings

| Analysis | Finding |
|---|---|
| Monthly Revenue | Peaked in Nov 2017 (~$1.19M), likely driven by Black Friday. 2016 and late 2018 data are incomplete. |
| Payment Methods | 76% of payments are via credit card. Heavy concentration on one payment method creates risk if processing is disrupted. |
| Delivery Time | RR state averages 29 days vs SP at 8 days — nearly 4x slower, likely due to distance from distribution centers. |
| Top Sellers | 9 of the top 10 sellers are from São Paulo (SP), indicating geographic revenue concentration. |

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

**Monthly Revenue Trend**
```sql
SELECT 
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month,
    ROUND(SUM(pay.payment_value), 2) AS monthly_revenue
FROM olist_orders_dataset ord
JOIN olist_order_payments_dataset pay
    ON ord.order_id = pay.order_id
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY year, month;
```

**Payment Method Analysis**
```sql
SELECT 
    payment_type, 
    COUNT(payment_type) AS total_transactions, 
    ROUND(SUM(payment_value), 2) AS total_revenue
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue DESC;
```

**Average Delivery Time by State**
```sql
SELECT 
    cust.customer_state, 
    AVG(DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date)) AS avg_days
FROM olist_customers_dataset cust
JOIN olist_orders_dataset ord
    ON cust.customer_id = ord.customer_id
WHERE ord.order_delivered_customer_date IS NOT NULL
GROUP BY cust.customer_state
ORDER BY avg_days DESC;
```

**Top 10 Sellers by Revenue**
```sql
SELECT TOP 10 
    ord.seller_id, 
    sel.seller_city, 
    sel.seller_state, 
    ROUND(SUM(pay.payment_value), 2) AS total_revenue
FROM olist_order_items_dataset ord
JOIN olist_order_payments_dataset pay ON ord.order_id = pay.order_id
JOIN olist_sellers_dataset sel ON ord.seller_id = sel.seller_id
GROUP BY ord.seller_id, sel.seller_city, sel.seller_state
ORDER BY total_revenue DESC;
```

---

## How to Run

1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Import all CSV files into a SQL Server database named `ecommerce_practice`
3. Open `ecommerce_analysis.sql` and run sections sequentially in SSMS

---

*Dataset: Olist Store, made available on Kaggle under a CC BY-NC-SA 4.0 license.*
