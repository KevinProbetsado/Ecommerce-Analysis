# Brazilian E-Commerce Sales Analysis
### SQL Data Analysis Project | Microsoft SQL Server

> Part of my data analytics portfolio — [View all projects](https://github.com/KevinProbetsado)

---

## Overview

An end-to-end data cleaning and business analysis project using the **Brazilian Olist E-Commerce dataset** — a real-world, multi-table dataset covering 100,000+ orders from 2016 to 2018. This project demonstrates how raw messy data is transformed into actionable business insights using SQL Server.

**Tool:** Microsoft SQL Server · SSMS  
**Dataset:** [Olist Brazilian E-Commerce — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)  
**Skills:** Data Cleaning · NULL Handling · Duplicate Detection · JOINs · Aggregations · Subqueries · Window Functions

---

## Dataset

9 relational tables covering the full order lifecycle:

| Table | Description |
|---|---|
| `olist_orders_dataset` | Order status and timestamps |
| `olist_order_items_dataset` | Products per order with price and freight |
| `olist_order_payments_dataset` | Payment types and values |
| `olist_order_reviews_dataset` | Customer review scores |
| `olist_customers_dataset` | Customer location and unique ID |
| `olist_products_dataset` | Product details and categories |
| `product_category_name_translation` | Portuguese to English category names |
| `olist_sellers_dataset` | Seller location data |
| `olist_geolocation_dataset` | ZIP code coordinates |

---

## Project Workflow

### Section 1 — Data Exploration
Previewed all 9 tables to understand structure, column names, and data types before any transformation.

### Section 2 — Data Cleaning

| Issue Found | Action Taken |
|---|---|
| Duplicate `order_id` in payments | Investigated — confirmed as expected. One order can have multiple payment types (e.g. credit card + voucher) |
| 610 NULL `product_category_name` values | Replaced with `'unknown'` using `UPDATE` to preserve row integrity |
| Malformed column headers in translation table | Renamed using `sp_rename` |
| Extra header row imported as a data row | Deleted using `DELETE` |
| NULLs checked across customers and orders | No critical NULLs found |

### Section 3 — Business Analysis

10 business questions answered across revenue, customers, sellers, and logistics.

---

## Business Questions & Key Findings

### 1. Top 5 Product Categories by Revenue
Health & beauty, watches & gifts, and bed/bath/table lead revenue — Olist is driven by lifestyle products, not electronics.

### 2. Top 10 Customers by Total Spend
High-value customers are concentrated in São Paulo and Rio de Janeiro. City names were formatted using `UPPER()`, `LEFT()`, and `SUBSTRING()` for clean presentation.

### 3. Monthly Revenue Trend (2016–2018)
Revenue grew consistently month over month with spikes around November (Black Friday) and Q1 2018 — the business was in a strong growth phase during this period.

> Only `delivered` orders were included to exclude cancelled and refunded transactions.

### 4. Payment Method Analysis
Credit card dominates as the preferred payment method by both volume and total revenue. Boleto (bank slip) is the second most common method — reflecting Brazil's payment culture.

### 5. Average Delivery Time by State
Northern states have significantly longer delivery times than southern states, likely due to geographic distance from distribution centers concentrated in São Paulo.

### 6. Top 10 Sellers by Revenue
Top sellers are concentrated in São Paulo state, consistent with Olist's logistics hub being in the southeast region.

### 7. Top Sellers by Average Review Score
Filtered to sellers with **50+ reviews** to remove small sample bias.

> A seller with a 5.0 average from 2 reviews is far less reliable than one with 4.7 from 500 reviews. Volume matters when evaluating seller quality.

### 8. Customer Lifetime Value (LTV)
Most customers have an LTV below R$500. A small VIP segment spends R$1,000+ — a classic 80/20 pattern where a minority of customers drives most of the revenue.

### 9. Repeat Customer Rate

| Metric | Finding |
|---|---|
| Total customers | ~96,000 |
| Repeat customers | ~3–4% |
| Repeat percentage | ~3.2% |

> `customer_unique_id` was used instead of `customer_id` — Olist assigns a **new** `customer_id` per order for privacy. Using `customer_id` would make every customer appear as a first-time buyer.

### 10. Average Days Between Repeat Orders

| Metric | Finding |
|---|---|
| Overall average | 80 days (~2.5 months) |
| Top repeat customers | 180+ days between orders |

> Olist's customer base is **need-driven, not habit-driven.** An 80-day average repeat gap is consistent with a general marketplace selling durable goods rather than everyday consumables. This is not necessarily a retention problem — it reflects the nature of the product mix.

---

## Key Takeaways

> Olist shows strong and consistent revenue growth from 2016 to 2018, driven by lifestyle product categories and a credit-card-dominant payment culture. However, only ~3% of customers place more than one order, and repeat buyers take an average of 80 days to return.
>
> To improve retention, Olist could:
> - Expand into consumable or replenishable product categories
> - Build loyalty programs targeting high-LTV customers
> - Address long delivery times in northern states which may discourage repeat purchases

---

## How to Run

1. Download the [Olist dataset from Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
2. Import all CSV files into SQL Server as a database named `ecommerce_practice`
3. Open `ecommerce_analysis.sql` in SSMS
4. Run each section sequentially

---

*Dataset: Olist Store — made available on Kaggle under CC BY-NC-SA 4.0 license.*
