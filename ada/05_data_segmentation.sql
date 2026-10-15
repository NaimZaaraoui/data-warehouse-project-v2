-- Segment products into cost ranges
-- and count how many products fall into each segment

SELECT 
    MIN(cost) AS min_cost,
    MAX(cost) AS max_cost
FROM gold.dim_products;

WITH product_segments AS (
    SELECT 
        product_key,
        CASE
            WHEN cost < 100 THEN 'Below 100'
            WHEN cost BETWEEN 100 AND 500 THEN '100-500'
            WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range,
        cost
    FROM gold.dim_products)
SELECT 
    cost_range,
   COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products  DESC;

-- Group customers into 3 segments based on their spending behavior:
-- * VIP: at least 12 months of history and spending more than $5.000
-- * Regular: at least 12 months of history but spending $5.000 or less
-- * New: Lifespan less than 12 months
-- And find the total number of customers by each group.

WITH customer_metrics AS (
    SELECT 
        dc.customer_key,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, dc.create_date)) * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, dc.create_date)) AS lifespan_months,
        COALESCE(SUM(fs.sales_amount), 0) AS total_spend
    FROM gold.dim_customers dc
    LEFT JOIN gold.fact_sales fs
        ON dc.customer_key = fs.customer_key
    GROUP BY dc.customer_key, dc.create_date
), customer_segments AS (
    SELECT 
        CASE
            WHEN lifespan_months >= 12 AND total_spend > 5000 THEN 'VIP'
            WHEN lifespan_months >= 12 AND total_spend <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_category
    FROM customer_metrics
)
SELECT 
    customer_category,
    COUNT(*) AS total_customers
FROM customer_segments
GROUP BY customer_category
ORDER BY total_customers DESC;

WITH customer_spending AS (
    SELECT 
        dc.customer_key,
        SUM(fs.sales_amount) AS total_spending,
        MIN(fs.order_date) AS first_order,
        MAX(fs.order_date) AS last_order,
        CASE 
            WHEN MIN(fs.order_date) <= MAX(fs.order_date) - INTERVAL '1 year' THEN 12
            ELSE 0
        END AS lifespan_flag
    FROM gold.dim_customers dc
    LEFT JOIN gold.fact_sales fs 
        ON fs.customer_key = dc.customer_key
    GROUP BY dc.customer_key
), customer_segments AS (
    SELECT 
        customer_key,
        CASE
            WHEN lifespan_flag >= 12 AND total_spending > 5000 THEN 'VIP'
            WHEN lifespan_flag >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_category
    FROM customer_spending
)
SELECT 
    customer_category,
    COUNT(customer_key) AS total_customers
FROM customer_segments
GROUP BY customer_category
ORDER BY total_customers DESC;
