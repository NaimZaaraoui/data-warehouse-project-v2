/*
============================================================================================
Product Report
============================================================================================
Purpose:
    - This report consolidates key product metrics and behaviors

Highlights:
    1. Gathers essential fields such as product name, category, subcaegory, and cost.
    2. Segments products by revenue to identify High-Performers, Mid-Range, or Low-Performers.
    3. Aggregates product-level metrics:
        - Total orders
        - Total sales
        - Total quantity sold
        - Total customers (unique)
        - Lifespan (in months)
    4. Calculates valuable KPIs:
        - Recency (months since last sale)
        - Average order revenue (AOR)
        - Average monthly revenue
=============================================================================================
*/

CREATE OR REPLACE VIEW gold.report_product AS
WITH base_query AS (
    /*-------------------------------------------------------------------------
    1) Base Query: Retrieves core columns from tables fact_sales & dim_products
    ---------------------------------------------------------------------------*/
    SELECT 
        fs.order_number,
        fs.customer_key,
        fs.order_date,
        fs.sales_amount,
        fs.quantity,
        dp.product_key,
        dp.product_name,
        dp.category,
        dp.subcategory,
        dp.cost
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp
        ON fs.product_key = dp.product_key
    WHERE fs.order_date IS NOT NULL -- Only consider valid sales dates
), product_aggregations AS (
    /*--------------------------------------------------------------------
    2) Product Aggregations: Summarizes key metrics at the product level
    -----------------------------------------------------------------------*/
    SELECT 
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount) AS total_revenue,
        SUM(quantity) AS total_quantity_sold,
        COUNT(DISTINCT customer_key) AS total_customers,
        MAX(order_date) AS last_sale_date,
        EXTRACT(YEAR FROM AGE(MAX(order_date), MIN(order_date))) * 12 +
        EXTRACT(MONTH FROM AGE(MAX(order_date), MIN(order_date))) AS lifespan,
        ROUND(SUM(sales_amount) / NULLIF(SUM(quantity), 0), 1) AS avg_selling_price
    FROM base_query
    GROUP BY product_key,
        product_name,
        category,
        subcategory,
        cost
)
    /*--------------------------------------------------------------------
    3) Final Query: Combines all product results into one output
    -----------------------------------------------------------------------*/
SELECT 
    product_key,
        product_name,
        category,
        subcategory,
        cost,
        total_orders,
        total_revenue,
        avg_selling_price,
        CASE 
            WHEN total_revenue > 50000 THEN 'High-performer'
            WHEN total_revenue >= 10000 THEN 'Mid-range'
            ELSE 'Low-performer'
        END AS product_segment,
        -- Average Order Revenue (AOR)
        CASE 
            WHEN total_orders = 0 THEN 0
            ELSE total_revenue / total_orders
        END AS avg_order_revenue,
        total_quantity_sold,
        total_customers,
        last_sale_date,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, last_sale_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, last_sale_date)) AS recency,
        lifespan,
        -- Average Monthly Revenue
        CASE 
            WHEN lifespan = 0 THEN total_revenue
            ELSE ROUND(total_revenue / lifespan, 2)
        END AS avg_monthly_revenue
FROM product_aggregations;