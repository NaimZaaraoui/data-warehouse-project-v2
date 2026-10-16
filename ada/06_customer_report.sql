/*
============================================================================================
Customer Report
============================================================================================
Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - Total orders
        - Total sales
        - Total quantity purchased
        - Total products
        - Lifespan (in months)
    4. Calculates valuable KPIs:
        - Recency (months since last order)
        - Average order value
        - Average monthly spend
=============================================================================================
*/

CREATE OR REPLACE VIEW gold.report_customers AS
WITH base_query AS (
/*--------------------------------------------------------------------
1) Base Query: Retrieves core columns from tables
-----------------------------------------------------------------------*/
    SELECT 
        fs.order_number,
        fs.product_key,
        fs.order_date,
        fs.sales_amount,
        fs.quantity,
        dc.customer_key,
        dc.customer_number,
        CONCAT(dc.first_name, ' ', dc.last_name) AS customer_name,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, dc.birthdate)) AS age
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_customers dc
        ON fs.customer_key = dc.customer_key
    WHERE fs.order_date IS NOT NULL
), customer_aggregations AS (
    /*--------------------------------------------------------------------
    2) Customer Aggregations: Summarizes key metrics at the customer level
    -----------------------------------------------------------------------*/
    SELECT 
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_sales,
        SUM(quantity) AS total_quantity,
        COUNT(DISTINCT product_key) AS total_products,
        MAX(order_date) AS last_order_date,
        EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
        EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan
    FROM base_query
    GROUP BY customer_key,
            customer_number,
            customer_name,
            age
)
    /*--------------------------------------------------------------------
    3) Final Query: Combines all cutsomer results into one output
    -----------------------------------------------------------------------*/
SELECT customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age < 20 THEN 'Under 20'
        WHEN age BETWEEN 20 and 29 THEN '20-29'
        WHEN age BETWEEN 30 and 39 THEN '30-39'
        WHEN age BETWEEN 30 and 39 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    last_order_date,
    lifespan,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_order_date)) * 12 +
    EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_order_date)) AS recency,
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE total_sales / total_orders
    END AS avg_order_value,
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE ROUND(total_sales / lifespan, 2)
    END AS avg_monthly_spend
from customer_aggregations;
