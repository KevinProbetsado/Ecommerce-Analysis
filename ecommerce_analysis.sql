-- ================================================
-- Project  : Olist E-Commerce Sales Analysis
-- Author   : Kevin Probetsado
-- Date     : 2025
-- Tool     : Microsoft SQL Server
-- Dataset  : Brazilian E-Commerce Public Dataset
--            by Olist (Kaggle)
-- Description: End-to-end data cleaning and
--              business analysis of 100,000+
--              orders from 2016 to 2018
-- ================================================

USE ecommerce_practice
GO

-- ================================================
-- SECTION 1: DATA EXPLORATION
-- ================================================

-- Preview all tables before any transformation
SELECT TOP 5 * FROM olist_orders_dataset
SELECT TOP 5 * FROM olist_order_items_dataset
SELECT TOP 5 * FROM olist_products_dataset
SELECT TOP 5 * FROM product_category_name_translation
SELECT TOP 5 * FROM olist_customers_dataset
SELECT TOP 5 * FROM olist_geolocation_dataset
SELECT TOP 5 * FROM olist_order_payments_dataset
SELECT TOP 5 * FROM olist_order_reviews_dataset
SELECT TOP 5 * FROM olist_sellers_dataset

-- ================================================
-- SECTION 2: DATA CLEANING
-- ================================================

-- 2.1 Check for duplicates in orders
SELECT order_id, COUNT(*) AS count
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2.2 Check for duplicates in payments
SELECT order_id, COUNT(*) AS count
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2.3 Verify payment duplicates are normal
-- One order can have multiple payment types
-- e.g. credit card + voucher on the same order
SELECT TOP 10 *
FROM olist_order_payments_dataset
WHERE order_id IN (
    SELECT order_id
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

-- 2.4 Check NULLs in customers table
SELECT
    SUM(CASE WHEN customer_id   IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_city  IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM olist_customers_dataset;

-- 2.5 Check NULLs in orders table
SELECT
    SUM(CASE WHEN order_id     IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id  IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_status
FROM olist_orders_dataset;

-- 2.6 Check NULLs in products table
-- Result: 610 NULL product categories found
SELECT
    SUM(CASE WHEN product_id            IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category
FROM olist_products_dataset;

-- 2.7 Replace NULL product categories with 'unknown'
UPDATE olist_products_dataset
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

-- 2.8 Fix malformed column headers in translation table
EXEC sp_rename 'product_category_name_translation.column1', 'product_category_name',         'COLUMN'
EXEC sp_rename 'product_category_name_translation.column2', 'product_category_name_english', 'COLUMN'

-- 2.9 Remove extra header row imported as a data row
DELETE FROM product_category_name_translation
WHERE product_category_name = 'product_category_name';

-- 2.10 Check all order statuses
-- Used to understand the data before filtering
SELECT order_status, COUNT(*) AS count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY count DESC;

-- ================================================
-- SECTION 3: ANALYSIS
-- ================================================

-- ------------------------------------------------
-- 3.1 Top 5 Product Categories by Total Revenue
-- ------------------------------------------------
-- Finding: Health & beauty, watches & gifts, and
-- bed/bath/table are the top revenue categories
-- ------------------------------------------------
SELECT TOP 5
    prod_cat.product_category_name_english,
    ROUND(SUM(items.price), 2) AS total_revenue
FROM olist_order_items_dataset items
JOIN olist_products_dataset prod
    ON items.product_id = prod.product_id
JOIN product_category_name_translation prod_cat
    ON prod.product_category_name = prod_cat.product_category_name
GROUP BY prod_cat.product_category_name_english
ORDER BY total_revenue DESC;

-- ------------------------------------------------
-- 3.2 Top 10 Customers by Total Amount Paid
-- ------------------------------------------------
-- Finding: High-value customers concentrated in
-- Sao Paulo and Rio de Janeiro
-- ------------------------------------------------
SELECT TOP 10
    ord.customer_id,
    UPPER(LEFT(cust.customer_city, 1)) +
    LOWER(SUBSTRING(cust.customer_city, 2, LEN(cust.customer_city))) AS customer_city,
    UPPER(cust.customer_state) AS customer_state,
    ROUND(SUM(pay.payment_value), 2) AS total_paid
FROM olist_order_payments_dataset pay
JOIN olist_orders_dataset ord
    ON pay.order_id = ord.order_id
JOIN olist_customers_dataset cust
    ON ord.customer_id = cust.customer_id
WHERE ord.order_status = 'delivered'
GROUP BY ord.customer_id, cust.customer_city, cust.customer_state
ORDER BY total_paid DESC;

-- ------------------------------------------------
-- 3.3 Monthly Revenue Trend (2016-2018)
-- ------------------------------------------------
-- Finding: Consistent growth with spikes around
-- November (Black Friday) and Q1 2018
-- ------------------------------------------------
SELECT
    FORMAT(ord.order_purchase_timestamp, 'yyyy-MM') AS order_month,
    ROUND(SUM(items.price), 2)                      AS total_revenue
FROM olist_order_items_dataset items
JOIN olist_orders_dataset ord
    ON items.order_id = ord.order_id
WHERE ord.order_status = 'delivered'
GROUP BY FORMAT(ord.order_purchase_timestamp, 'yyyy-MM')
ORDER BY order_month ASC;

-- ------------------------------------------------
-- 3.4 Payment Method Analysis
-- ------------------------------------------------
-- Finding: Credit card dominates as the preferred
-- payment method by both volume and revenue
-- ------------------------------------------------
SELECT
    pay.payment_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(pay.payment_value), 2) AS total_revenue,
    ROUND(AVG(pay.payment_value), 2) AS avg_order_value
FROM olist_order_payments_dataset pay
JOIN olist_orders_dataset ord
    ON pay.order_id = ord.order_id
WHERE ord.order_status = 'delivered'
GROUP BY pay.payment_type
ORDER BY total_revenue DESC;

-- ------------------------------------------------
-- 3.5 Average Delivery Time by State
-- ------------------------------------------------
-- Finding: Northern states have significantly
-- longer delivery times than southern states
-- ------------------------------------------------
SELECT
    cust.customer_state,
    AVG(DATEDIFF(day,
        ord.order_purchase_timestamp,
        ord.order_delivered_customer_date)) AS avg_delivery_days
FROM olist_customers_dataset cust
JOIN olist_orders_dataset ord
    ON cust.customer_id = ord.customer_id
WHERE ord.order_status = 'delivered'
  AND ord.order_delivered_customer_date  IS NOT NULL
GROUP BY cust.customer_state
ORDER BY avg_delivery_days DESC;

-- ------------------------------------------------
-- 3.6 Top 10 Sellers by Total Revenue
-- ------------------------------------------------
SELECT TOP 10
    items.seller_id,
    sel.seller_city,
    UPPER(sel.seller_state)          AS seller_state,
    ROUND(SUM(items.price), 2)       AS total_revenue,
    COUNT(DISTINCT items.order_id)   AS total_orders
FROM olist_order_items_dataset items
JOIN olist_orders_dataset ord
    ON items.order_id = ord.order_id
JOIN olist_sellers_dataset sel
    ON items.seller_id = sel.seller_id
WHERE ord.order_status = 'delivered'
GROUP BY items.seller_id, sel.seller_city, sel.seller_state
ORDER BY total_revenue DESC;

-- ------------------------------------------------
-- 3.7 Top Sellers by Average Review Score
-- ------------------------------------------------
-- Filtered to sellers with 50+ reviews to remove
-- small sample bias — a seller with a 5.0 average
-- from 2 reviews is less reliable than 4.7 from 500
-- ------------------------------------------------
SELECT
    items.seller_id,
    ROUND(AVG(reviews.review_score), 2) AS avg_review_score,
    COUNT(reviews.review_score)         AS total_reviews
FROM olist_order_items_dataset items
JOIN olist_order_reviews_dataset reviews
    ON items.order_id = reviews.order_id
GROUP BY items.seller_id
HAVING COUNT(reviews.review_score) >= 50
ORDER BY avg_review_score DESC;

-- ------------------------------------------------
-- 3.8 Customer Lifetime Value (LTV)
-- ------------------------------------------------
-- Finding: Small VIP segment drives most revenue
-- Classic 80/20 pattern
-- ------------------------------------------------
SELECT TOP 20
    cust.customer_unique_id,
    UPPER(LEFT(cust.customer_city, 1)) +
    LOWER(SUBSTRING(cust.customer_city, 2, LEN(cust.customer_city))) AS customer_city,
    UPPER(cust.customer_state) AS customer_state,
    COUNT(DISTINCT ord.order_id) AS total_orders,
    ROUND(SUM(pay.payment_value), 2) AS lifetime_value
FROM olist_order_payments_dataset pay
JOIN olist_orders_dataset ord
    ON pay.order_id = ord.order_id
JOIN olist_customers_dataset cust
    ON ord.customer_id = cust.customer_id
WHERE ord.order_status = 'delivered'
GROUP BY cust.customer_unique_id, cust.customer_city, cust.customer_state
ORDER BY lifetime_value DESC;

-- ------------------------------------------------
-- 3.9 Repeat Customer Rate
-- ------------------------------------------------
-- Note: customer_unique_id is used here instead
-- of customer_id because Olist assigns a new
-- customer_id per order for privacy — using
-- customer_id would make every customer look
-- like a first-time buyer
-- Finding: Only ~3-4% of customers placed
-- more than one order
-- ------------------------------------------------
SELECT
    COUNT(customer_unique_id)AS total_customers,
    COUNT(CASE WHEN total_orders > 1 THEN 1 END)AS repeat_customers,
    ROUND(
        CAST(COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS FLOAT)
        / COUNT(customer_unique_id) * 100, 2
         ) AS repeat_percentage
FROM (
    SELECT
        cust.customer_unique_id,
        COUNT(ord.order_id) AS total_orders
    FROM olist_orders_dataset ord
    JOIN olist_customers_dataset cust
        ON ord.customer_id = cust.customer_id
    WHERE ord.order_status = 'delivered'
    GROUP BY cust.customer_unique_id
) AS customer_orders;

-- ------------------------------------------------
-- 3.10 Average Days Between Repeat Orders
-- ------------------------------------------------
-- Finding: Repeat customers take an average of
-- 80 days (~2.5 months) to place their next order
-- Top customers wait 180+ days
-- Suggests need-driven, not habit-driven buying
-- ------------------------------------------------

-- Per repeat customer breakdown
SELECT
    cust.customer_unique_id,
    MIN(ord.order_purchase_timestamp)  AS first_order,
    MAX(ord.order_purchase_timestamp)  AS last_order,
    COUNT(ord.order_id)                AS total_orders,
    DATEDIFF(day,
        MIN(ord.order_purchase_timestamp),
        MAX(ord.order_purchase_timestamp)
    ) / (COUNT(ord.order_id) - 1)     AS avg_days_between_orders
FROM olist_orders_dataset ord
JOIN olist_customers_dataset cust
    ON ord.customer_id = cust.customer_id
WHERE ord.order_status = 'delivered'
GROUP BY cust.customer_unique_id
HAVING COUNT(ord.order_id) > 1
ORDER BY total_orders DESC;

-- Overall average across all repeat customers
SELECT AVG(avg_days_between_orders) AS overall_avg_days
FROM (
    SELECT
        cust.customer_unique_id,
        DATEDIFF(day,
            MIN(ord.order_purchase_timestamp),
            MAX(ord.order_purchase_timestamp)
        ) / (COUNT(ord.order_id) - 1) AS avg_days_between_orders
    FROM olist_orders_dataset ord
    JOIN olist_customers_dataset cust
        ON ord.customer_id = cust.customer_id
    WHERE ord.order_status = 'delivered'
    GROUP BY cust.customer_unique_id
    HAVING COUNT(ord.order_id) > 1
) AS repeat_customers;
