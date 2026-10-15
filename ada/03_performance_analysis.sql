-- Analyze the yearly performance of products
-- by comparing each product's sales to both
-- its average sales performance and the previous year's sales

WITH yearly_product_sales AS (
    SELECT 
        dp.product_name,
        EXTRACT(YEAR FROM fs.order_date) AS order_year,
        SUM(fs.sales_amount) AS current_sales
    FROM gold.fact_sales fs
    LEFT JOIN gold.dim_products dp
        ON fs.product_key = dp.product_key
    WHERE fs.order_date IS NOT NULL
    GROUP BY dp.product_name, EXTRACT(YEAR FROM fs.order_date)
),
calculated_metrics AS (
    SELECT 
        product_name,
        order_year,
        current_sales,
        -- Window Averages
        ROUND(AVG(current_sales) OVER (PARTITION BY product_name), 0) AS avg_sales,
        
        -- Window Prior Year Fetching
        LAG(order_year) OVER (PARTITION BY product_name ORDER BY order_year) AS prev_year_found,
        LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS raw_prev_sales
    FROM yearly_product_sales
),
final_metrics AS (
    SELECT
        product_name,
        order_year,
        current_sales,
        avg_sales,
        (current_sales - avg_sales) AS diff_avg_sales,
        
        -- Validate if the previous row found is actually the consecutive prior year
        CASE WHEN prev_year_found = order_year - 1 THEN raw_prev_sales 
            ELSE NULL 
        END AS previous_year_sales
    FROM calculated_metrics
)
SELECT 
    product_name,
    order_year,
    current_sales,
    avg_sales,
    diff_avg_sales,
    CASE 
        WHEN diff_avg_sales > 0 THEN 'Above Avg'
        WHEN diff_avg_sales < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,
    previous_year_sales,
    (current_sales - previous_year_sales) AS diff_previous_year,
    CASE 
        WHEN (current_sales - previous_year_sales) > 0 THEN 'Increase'
        WHEN (current_sales - previous_year_sales) < 0 THEN 'Decrease'
        WHEN (current_sales - previous_year_sales) = 0 THEN 'No Change'
        ELSE 'No Prior Data' -- Handles missing consecutive year gaps cleanly
    END AS previous_year_change
FROM final_metrics
ORDER BY product_name, order_year;