-- Which categories contribute the most to overall sales?

WITH calculated_metrics AS (
    SELECT 
        dp.category,
        SUM(fs.sales_amount) AS category_sales,
        SUM(SUM(fs.sales_amount)) OVER() AS total_sales
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp
        ON fs.product_key = dp.product_key
    GROUP BY dp.category
)
SELECT 
    category,
    category_sales,
    total_sales,
    CONCAT(ROUND((category_sales / NULLIF(total_sales, 0)) * 100, 2), '%') AS category_percentage
FROM calculated_metrics
ORDER BY category_sales DESC;

-- Which countries contribute the most to overall soled items?

WITH country_sold_items AS (
    SELECT 
        dc.country,
        SUM(fs.quantity) AS total_quantity
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_customers dc
        ON fs.customer_key = dc.customer_key
    GROUP BY dc.country
)
SELECT 
    country,
    total_quantity,
    SUM(total_quantity) OVER() AS overall_quantity,
    ROUND((total_quantity / SUM(total_quantity) OVER()) * 100, 2) AS percentage_of_total
FROM country_sold_items
ORDER BY total_quantity DESC;

-- Which gender contribute the most to overall soled items?

WITH gender_sold_items AS (
    SELECT 
        dc.gender,
        SUM(fs.quantity) AS total_quantity
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_customers dc
        ON fs.customer_key = dc.customer_key
    GROUP BY dc.gender
)
SELECT 
    gender,
    total_quantity,
    SUM(total_quantity) OVER() AS overall_quantity,
    ROUND((total_quantity / SUM(total_quantity) OVER()) * 100, 2) AS percentage_of_total
FROM gender_sold_items
ORDER BY total_quantity DESC;