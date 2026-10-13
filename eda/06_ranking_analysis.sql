-- Which 5 products generate the highest revenue
SELECT 
    dp.product_key,
    dp.product_name,
    SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name
ORDER BY total_revenue DESC
LIMIT 5;


SELECT 
    product_key,
    product_name,
    total_revenue
FROM (
    SELECT 
        dp.product_key,
        dp.product_name,
        SUM(fs.sales_amount) AS total_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(fs.sales_amount) DESC) AS revenue_rank
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp
        ON fs.product_key = dp.product_key
    GROUP BY dp.product_key, dp.product_name
)
WHERE revenue_rank <= 5;

-- Top 5 products per category

SELECT 
    category,
    product_name,
    total_revenue,
    revenue_rank
FROM (
    SELECT 
        dp.product_name,
        dp.category,
        SUM(fs.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY dp.category ORDER BY SUM(fs.sales_amount) DESC) AS revenue_rank
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp
        ON fs.product_key = dp.product_key
    GROUP BY dp.category, dp.product_name
)
WHERE revenue_rank <= 5;


-- Which are the 5 worst-performing products in terms of sales?
SELECT 
    dp.product_key,
    dp.product_name,
    SUM(fs.sales_amount) AS total_revenue
FROM gold.fact_sales fs
LEFT JOIN gold.dim_products dp
    ON fs.product_key = dp.product_key
GROUP BY dp.product_key, dp.product_name
ORDER BY total_revenue
LIMIT 5;