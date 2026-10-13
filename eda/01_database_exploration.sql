-- Explore all objects in the database
SELECT * 
FROM information_schema.tables
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
-- 15 tables


-- Explore all columns in the database
SELECT * 
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema');
-- 101 columns

SELECT * 
FROM information_schema.columns 
WHERE table_name = 'dim_customers'
ORDER BY ordinal_position;