-- Explore all countries our customers come from
SELECT DISTINCT country 
FROM gold.dim_customers;

-- Explore all product categories 'The major divisions'
SELECT DISTINCT category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category NULLS FIRST, subcategory, product_name;