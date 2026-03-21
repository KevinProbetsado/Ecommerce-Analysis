-- ================================================
-- Project: Olist E-commerce Analysis
-- Author: Your Name
-- Date: 2024
-- Description: Data cleaning and analysis of the
--              Brazilian E-commerce dataset
-- ================================================

USE ecommerce_practice
GO

-- ================================================
-- SECTION 1: DATA EXPLORATION
-- ================================================

-- Preview all tables
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
SELECT order_id, COUNT(*) as count
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2.2 Check for duplicates in payments
-- Note: duplicates are expected since one order
-- can have multiple payment types
SELECT order_id, COUNT(*) as count
FROM olist_order_payments_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 2.3 Verify payments duplicates are normal
SELECT TOP 10 * 
FROM olist_order_payments_dataset
WHERE order_id IN (
    SELECT order_id
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING COUNT(*) > 1
)
ORDER BY order_id;

-- 2.4 Check NULLs in customers
SELECT 
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM olist_customers_dataset;

-- 2.5 Check NULLs in orders
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_status
FROM olist_orders_dataset;

-- 2.6 Check NULLs in products
-- Result: 610 NULL categories found
SELECT 
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category
FROM olist_products_dataset;

-- 2.7 Replace NULL categories with 'unknown'
UPDATE olist_products_dataset
SET product_category_name = 'unknown'
WHERE product_category_name IS NULL;

-- 2.8 Fix column headers in category translation table
EXEC sp_rename 'product_category_name_translation.column1', 'product_category_name', 'COLUMN'
EXEC sp_rename 'product_category_name_translation.column2', 'product_category_name_english', 'COLUMN'

-- 2.9 Remove extra header row imported as data
DELETE FROM product_category_name_translation
WHERE product_category_name = 'product_category_name';

-- ================================================
-- SECTION 3: ANALYSIS
-- ================================================

--Top 5 Product Categories by Total Revenue
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

-- Top 10 Customers by Total Amount Paid
SELECT TOP 10
    ord.customer_id,
    UPPER(cust.customer_city) AS customer_city,
    UPPER(cust.customer_state) AS customer_state,
    ROUND(SUM(pay.payment_value), 2) AS total_paid
FROM olist_order_payments_dataset pay
JOIN olist_orders_dataset ord 
    ON pay.order_id = ord.order_id
JOIN olist_customers_dataset cust 
    ON ord.customer_id = cust.customer_id
GROUP BY ord.customer_id, cust.customer_city, cust.customer_state
ORDER BY total_paid DESC;

--MONTHLY SALES

SELECT TOP 10   
    YEAR(order_purchase_timestamp) AS year,
    MONTH(order_purchase_timestamp) AS month,
    ROUND(SUM(pay.payment_value), 2) AS monthly_revenue
FROM olist_orders_dataset ord
JOIN olist_order_payments_dataset pay
    ON ord.order_id = pay.order_id
GROUP BY YEAR(order_purchase_timestamp), MONTH(order_purchase_timestamp)
ORDER BY monthly_revenue DESC;

-- Payment Method Analysis
SELECT payment_type, COUNT(payment_type) AS total_payment_type, SUM(payment_value) AS total_revenue_per_payment_type
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue_per_payment_type DESC

-- AVG delivery time
SELECT cust.customer_state, AVG(DATEDIFF(day, ord.order_purchase_timestamp, ord.order_delivered_customer_date)) as avg_days
FROM olist_customers_dataset cust
    JOIN olist_orders_dataset ord
     ON cust.customer_id = ord.customer_id
WHERE order_delivered_customer_date IS NOT NULL
GROUP BY cust.customer_state
ORDER BY avg_days DESC;

-- TOP 10 SELLER
SELECT TOP 10 ord.seller_id, sel.seller_city, sel.seller_state, SUM(pay.payment_value) as total_revenue
FROM olist_order_items_dataset ord
     JOIN olist_order_payments_dataset pay
        ON ord.order_id = pay.order_id
     JOIN olist_sellers_dataset sel
        ON ord.seller_id = sel.seller_id
GROUP BY ord.seller_id,sel.seller_city, sel.seller_state
ORDER BY total_revenue DESC


