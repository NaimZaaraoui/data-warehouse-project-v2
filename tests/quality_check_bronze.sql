-- Check wheter the Bronze tables have been loaded with data. 
-- This test is intended to be run after the Bronze load process has completed.
-- Row count validation
SELECT 'bronze.crm_cust_info' AS table_name,
    COUNT(*) AS row_count
FROM bronze.crm_cust_info
UNION ALL
SELECT 'bronze.crm_prd_info',
    COUNT(*)
FROM bronze.crm_prd_info
UNION ALL
SELECT 'bronze.crm_sales_details',
    COUNT(*)
FROM bronze.crm_sales_details
UNION ALL
SELECT 'bronze.erp_cust_az12',
    COUNT(*)
FROM bronze.erp_cust_az12
UNION ALL
SELECT 'bronze.erp_loc_a101',
    COUNT(*)
FROM bronze.erp_loc_a101
UNION ALL
SELECT 'bronze.erp_px_cat_g1v2',
    COUNT(*)
FROM bronze.erp_px_cat_g1v2
ORDER BY table_name;

-- Schema and column validation
SELECT *
FROM bronze.crm_cust_info
LIMIT 5;

SELECT table_name,
    ordinal_position,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'bronze'
ORDER BY table_name,
    ordinal_position;

-- Data completeness
SELECT COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE cst_id IS NULL
    ) AS missing_cst_id,
    COUNT(*) FILTER (
        WHERE cst_key IS NULL
    ) AS missing_cst_key,
    COUNT(*) FILTER (
        WHERE cst_firstname IS NULL
    ) AS missing_firstname,
    COUNT(*) FILTER (
        WHERE cst_lastname IS NULL
    ) AS missing_lastname,
    COUNT(*) FILTER (
        WHERE cst_marital_status IS NULL
    ) AS missing_marital_status,
    COUNT(*) FILTER (
        WHERE cst_gndr IS NULL
    ) AS missing_gender,
    COUNT(*) FILTER (
        WHERE cst_create_date IS NULL
    ) AS missing_create_date
FROM bronze.crm_cust_info;

SELECT *
FROM bronze.crm_cust_info
WHERE cst_lastname IS NULL;

SELECT COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE prd_id IS NULL
    ) AS missing_prd_id,
    COUNT(*) FILTER (
        WHERE prd_key IS NULL
    ) AS missing_prd_key,
    COUNT(*) FILTER (
        WHERE prd_name IS NULL
    ) AS missing_prd_name,
    COUNT(*) FILTER (
        WHERE prd_cost IS NULL
    ) AS missing_prd_cost,
    COUNT(*) FILTER (
        WHERE prd_line IS NULL
    ) AS missing_prd_line,
    COUNT(*) FILTER (
        WHERE prd_start_dt IS NULL
    ) AS missing_prd_start_dt
FROM bronze.crm_prd_info;