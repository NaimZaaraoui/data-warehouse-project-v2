

-- Find the total sales
SELECt SUM(sales_amount) AS total_sales
FROM gold.fact_sales;

-- Find how many items are sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;

-- Find the average selling price
SELECT AVG(price) AS avg_price
FROM gold.fact_sales;

-- Find the total number of orders
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;

-- Find the total number of products
SELECT COUNT(DISTINCT product_key) AS total_products
FROM gold.dim_products;

-- Find the total number of customers
SELECT COUNT(DISTINCT customer_key) AS total_customers
FROM gold.dim_customers;

-- Find the total number of customers that has placed an order
SELECT COUNT(DISTINCT customer_key)
FROM gold.fact_sales;

-- Report that shows all key metrics of the business
SELECt 
    'Total Sales' AS measure_name,
    SUM(sales_amount) AS measure_value
FROM gold.fact_sales
UNION ALL
SELECt 
    'Total Quantity',
    SUM(quantity)
FROM gold.fact_sales
UNION ALL
SELECt 
    'Average Price',
    AVG(price) 
FROM gold.fact_sales
UNION ALL
SELECt 
    'Total Orders',
    COUNT(DISTINCT order_number)
FROM gold.fact_sales
UNION ALL
SELECt 
    'Total Products',
    COUNT(product_key) 
FROM gold.dim_products
UNION ALL
SELECt 
    'Total Customers',
    COUNT(customer_key)
FROM gold.dim_customers;