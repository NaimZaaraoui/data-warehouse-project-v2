/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

CREATE OR REPLACE VIEW gold.dim_customers AS
SELECT 
    ROW_NUMBER() OVER(ORDER BY cci.cst_id) AS customer_key, -- Surrogate key 
    cci.cst_id AS customer_id,
    cci.cst_key AS customer_number,
    cci.cst_firstname AS first_name,
    cci.cst_lastname AS last_name,
    ela.cntry AS country,
    CASE cci.cst_gndr
        WHEN 'n/a' THEN COALESCE(eca.gen, 'n/a')
        ELSE cci.cst_gndr -- CRM is the master for gender info
    END AS gender,
    eca.bdate AS birthdate,
    cci.cst_marital_status AS marital_status,
    cci.cst_create_date AS create_date
FROM silver.crm_cust_info cci
LEFT JOIN silver.erp_cust_az12 eca
    ON cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
    ON cci.cst_key = ela.cid;


-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

CREATE OR REPLACE VIEW gold.dim_products AS
SELECT 
    ROW_NUMBER() OVER (ORDER BY cpn.prd_start_dt, cpn.prd_key) AS product_key, -- Surrogate key
    cpn.prd_id  AS prdoduct_id,
    cpn.prd_key AS product_number,
    cpn.prd_nm AS product_name,
    cpn.prd_cat_id AS category_id,
    epc.cat AS category,
    epc.subcat AS subcategory,
    epc.maintenance,
    cpn.prd_cost AS cost,
    cpn.prd_line AS product_line,
    cpn.prd_start_dt AS start_date
FROM silver.crm_prd_info cpn
LEFT JOIN silver.erp_px_cat_g1v2 epc
    ON cpn.prd_cat_id = epc.id
WHERE cpn.prd_end_dt IS NULL; -- Filter out all historical data

-- =============================================================================
-- Create Fact: gold.fact_sales
-- =============================================================================

CREATE OR REPLACE VIEW gold.fact_sales AS
SELECT 
    sd.sls_ord_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS ship_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products dp
    ON sd.sls_prd_key = dp.product_number
LEFT JOIN gold.dim_customers dc
    ON sd.sls_cust_id = dc.customer_id;