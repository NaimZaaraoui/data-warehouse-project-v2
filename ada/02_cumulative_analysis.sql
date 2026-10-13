-- Calculate the total sales per month
-- the running total of sales over time
-- and the moving average of price

SELECT 
    order_month::date,
    total_sales,
    SUM(total_sales) OVER(PARTITION BY order_year ORDER BY order_month) AS running_total_sales,
    (total_sales - LAG(total_sales) OVER(PARTITION BY order_year ORDER BY order_month)) * 100 
    / NULLIF(LAG(total_sales) OVER(PARTITION BY order_year ORDER BY order_month), 0) AS growth_percentage,
    AVG(avg_price) OVER(ORDER BY order_month) AS moving_avg_price
FROM (
SELECT 
    DATE_TRUNC('month', order_date) AS order_month,
    EXTRACT(YEAR FROM order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_TRUNC('month', order_date), EXTRACT(YEAR FROM order_date))
ORDER BY order_month;

SELECT 
    order_year,
    total_sales,
    SUM(total_sales) OVER( ORDER BY order_year) AS running_total_sales,
    (total_sales - LAG(total_sales) OVER(ORDER BY order_year)) * 100 
    / NULLIF(LAG(total_sales) OVER(ORDER BY order_year), 0) AS growth_percentage,
    AVG(avg_price) OVER(ORDER BY order_year) AS moving_avg_price
FROM (
SELECT 
    EXTRACT(YEAR FROM order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date))
ORDER BY order_year;