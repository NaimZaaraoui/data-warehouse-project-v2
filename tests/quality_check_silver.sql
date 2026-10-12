/*
 ================================================================================
 Quality Check: silver Layer
 Project: AdventureWorks Cycles Data Warehouse
 Database: PostgreSQL
 ================================================================================
 
 PURPOSE
 -------
 Validate the contents of the silver layer after the cleansing process.
 
 The silver layer contains cleansed and standardized data from the bronze layer. This script performs quality checks to ensure that the data in the silver layer meets the expected standards and business rules.
 
 SECTIONS
 --------
 1. Null or duplicate primary keys.
 2. Unwanted spaces in string fields.
 3. Data standardization and consistency.
 4. Invalid date ranges and ships.
 5. Data consistency between related fields.
 
 
 
 HOW TO USE
 ----------
 - Run after the silver layer has been populated.
 - Review the results of each query.
 - Queries labelled "EXPECTATION: No Results" should ideally return no rows.
 - Investigate unexpected results before taking corrective action.
 Confirm that the source data is correct and that the ETL process is functioning as intended.
 
 ================================================================================
 */
/*
 ================================================================================
 1. CUSTOMER DATA INTEGRITY silver.crm_cust_info
 ================================================================================
 
 TABLE:
 silver.crm_cust_info
 
 PURPOSE:
 Investigate uniqueness, whitespace, standardization, and missing customer data.
 */
-- ----------------------------------------------------------------------------
-- 1.1 CHECK FOR NULL OR DUPLICATE CUSTOMER IDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
-- cst_id is expected to identify a customer uniquely.
SELECT cst_id,
    COUNT(*) AS row_count
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING cst_id IS NULL
    OR COUNT(*) > 1
ORDER BY cst_id NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 1.2 CHECK FOR UNWANTED SPACES IN CUSTOMER TEXT FIELDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
-- TRIM removes leading and trailing spaces.
-- NULL values are handled by the separate completeness checks.
SELECT cst_firstname,
    LENGTH(cst_firstname) AS original_length,
    LENGTH(TRIM(cst_firstname)) AS trimmed_length
FROM silver.crm_cust_info
WHERE cst_firstname IS NOT NULL
    AND cst_firstname <> TRIM(cst_firstname);

SELECT cst_lastname,
    LENGTH(cst_lastname) AS original_length,
    LENGTH(TRIM(cst_lastname)) AS trimmed_length
FROM silver.crm_cust_info
WHERE cst_lastname IS NOT NULL
    AND cst_lastname <> TRIM(cst_lastname);

-- ----------------------------------------------------------------------------
-- 1.3 CHECK DISTINCT GENDER VALUES
-- ----------------------------------------------------------------------------
-- EXPECTATION: Values should follow consistent source conventions.
-- Review the values before deciding how to standardize them in Silver.
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info
ORDER BY cst_gndr NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 1.4 CHECK DISTINCT MARITAL STATUS VALUES
-- ----------------------------------------------------------------------------
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info
ORDER BY cst_marital_status NULLS FIRST;

/*
 ================================================================================
 2. PRODUCT DATA INTEGRITY
 ================================================================================
 
 TABLE:
 silver.crm_prd_info
 
 PURPOSE:
 Check product ID uniqueness, text formatting, product line values, date ranges,
 and previously identified missing fields.
 */
-- ----------------------------------------------------------------------------
-- 2.1 CHECK FOR NULL OR DUPLICATE PRODUCT IDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
-- Assumes prd_id is intended to uniquely identify a product record.
SELECT prd_id,
    COUNT(*) AS row_count
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING prd_id IS NULL
    OR COUNT(*) > 1
ORDER BY prd_id NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 2.2 CHECK FOR UNWANTED SPACES IN PRODUCT NAMES
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
SELECT prd_nm,
    LENGTH(prd_nm) AS original_length,
    LENGTH(TRIM(prd_nm)) AS trimmed_length
FROM silver.crm_prd_info
WHERE prd_nm IS NOT NULL
    AND prd_nm <> TRIM(prd_nm);

-- ----------------------------------------------------------------------------
-- 2.3 REVIEW DISTINCT PRODUCT LINE VALUES
-- ----------------------------------------------------------------------------
-- EXPECTATION: Values should follow consistent source conventions.
SELECT DISTINCT prd_line
FROM silver.crm_prd_info
ORDER BY prd_line;

-- ----------------------------------------------------------------------------
-- 2.4 CHECK FOR INVALID PRODUCT DATE RANGES
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
-- This comparison assumes the two columns use comparable date-compatible types.
-- A missing end date is not flagged because it may be valid for an active product.
SELECT *
FROM silver.crm_prd_info
WHERE prd_start_dt IS NOT NULL
    AND prd_end_dt IS NOT NULL
    AND prd_end_dt < prd_start_dt;

-- ----------------------------------------------------------------------------
-- 2.5 INVESTIGATE MISSING PRODUCT COSTS OR PRODUCT LINES
-- ----------------------------------------------------------------------------
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL
    OR prd_line IS NULL;

-- ----------------------------------------------------------------------------
-- 2.6 INVESTIGATE NEGATIVE PRODUCT COSTS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost < 0;

/*
 ================================================================================
 6. SALES DATA INTEGRITY
 ================================================================================
 
 TABLE:
 silver.crm_sales_details
 
 PURPOSE:
 Investigate missing identifiers and measures, potential invalid numeric values,
 date inconsistencies, and relationships to CRM customer and product records.
 
 IMPORTANT:
 An order number may appear multiple times because an order can contain multiple
 products. Do not assume sls_ord_num alone must be unique.
 */
-- ----------------------------------------------------------------------------
-- 6.1 INVESTIGATE INCOMPLETE SALES RECORDS
-- ----------------------------------------------------------------------------
SELECT *
FROM silver.crm_sales_details
WHERE sls_ord_num IS NULL
    OR sls_prd_key IS NULL
    OR sls_cust_id IS NULL
    OR sls_order_dt IS NULL
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL;

-- ----------------------------------------------------------------------------
-- 6.2 CHECK FOR NEGATIVE SALES, QUANTITIES, OR PRICES
-- ----------------------------------------------------------------------------
-- INVESTIGATION QUERY:
-- Negative values may indicate data issues, but returns or adjustments may also
-- explain them. Confirm the business rules before classifying them as invalid.
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales < 0
    OR sls_quantity < 0
    OR sls_price < 0;

-- ----------------------------------------------------------------------------
-- 6.3 CHECK FOR ZERO SALES, QUANTITIES, OR PRICES
-- ----------------------------------------------------------------------------
-- INVESTIGATION QUERY:
-- Zero values are not automatically invalid; inspect them in context.
SELECT *
FROM silver.crm_sales_details
WHERE sls_sales = 0
    OR sls_quantity = 0
    OR sls_price = 0;

-- ----------------------------------------------------------------------------
-- 6.4 CHECK SALES DATE CHRONOLOGY
-- ----------------------------------------------------------------------------
-- EXPECTATION: No unexpected date ordering.
-- Assumes the date columns use comparable date-compatible types.
-- Confirm the source's date rules before treating every result as invalid.
SELECT *
FROM silver.crm_sales_details
WHERE (
        sls_order_dt IS NOT NULL
        AND sls_ship_dt IS NOT NULL
        AND sls_ship_dt < sls_order_dt
    )
    OR (
        sls_order_dt IS NOT NULL
        AND sls_due_dt IS NOT NULL
        AND sls_due_dt < sls_order_dt
    );

-- ----------------------------------------------------------------------------
-- 6.5 CHECK WHETHER SALES EQUAL QUANTITY MULTIPLIED BY PRICE
-- ----------------------------------------------------------------------------
-- INVESTIGATION QUERY:
-- This is a potential consistency check, not a guaranteed business rule.
-- Discounts, rounding, or other pricing rules may explain differences.
-- Exact comparison may be inappropriate if numeric rounding is expected.
SELECT sls_ord_num,
    sls_prd_key,
    sls_quantity,
    sls_price,
    sls_sales,
    sls_quantity * sls_price AS calculated_sales
FROM silver.crm_sales_details
WHERE sls_quantity IS NOT NULL
    AND sls_price IS NOT NULL
    AND sls_sales IS NOT NULL
    AND sls_sales <> sls_quantity * sls_price;

-- ----------------------------------------------------------------------------
-- 6.6 CHECK FOR SALES WITH NO MATCHING CRM CUSTOMER
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results, if the source systems are expected to be consistent.
-- Investigate any unmatched IDs; do not delete these records in silver.
SELECT s.sls_cust_id,
    COUNT(*) AS sales_rows
FROM silver.crm_sales_details AS s
WHERE s.sls_cust_id IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM silver.crm_cust_info AS c
        WHERE c.cst_id = s.sls_cust_id
    )
GROUP BY s.sls_cust_id
ORDER BY s.sls_cust_id;

-- ----------------------------------------------------------------------------
-- 6.7 CHECK FOR SALES WITH NO MATCHING CRM PRODUCT KEY
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results, if product keys are expected to match across tables.
-- Confirm the source key conventions before interpreting unmatched values.
SELECT s.sls_prd_key,
    COUNT(*) AS sales_rows
FROM silver.crm_sales_details AS s
WHERE s.sls_prd_key IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM silver.crm_prd_info AS p
        WHERE p.prd_key = s.sls_prd_key
    )
GROUP BY s.sls_prd_key
ORDER BY s.sls_prd_key;

/*
 ================================================================================
 7. ERP CUSTOMER DEMOGRAPHICS INTEGRITY
 ================================================================================
 
 TABLE:
 silver.erp_cust_az12
 
 PURPOSE:
 Inspect customer identifier uniqueness, gender values, and birth dates.
 */
-- ----------------------------------------------------------------------------
-- 7.1 CHECK FOR NULL OR DUPLICATE ERP CUSTOMER IDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results, if CID is expected to be unique in this source.
SELECT CID,
    COUNT(*) AS row_count
FROM silver.erp_cust_az12
GROUP BY CID
HAVING CID IS NULL
    OR COUNT(*) > 1
ORDER BY CID NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 7.2 REVIEW DISTINCT ERP GENDER VALUES
-- ----------------------------------------------------------------------------
SELECT DISTINCT GEN
FROM silver.erp_cust_az12
ORDER BY GEN NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 7.3 INVESTIGATE MISSING ERP GENDER VALUES
-- ----------------------------------------------------------------------------
SELECT *
FROM silver.erp_cust_az12
WHERE GEN IS NULL;

-- ----------------------------------------------------------------------------
-- 7.4 CHECK FOR FUTURE BIRTH DATES
-- ----------------------------------------------------------------------------
-- INVESTIGATION QUERY:
-- Uses the database's current date.
-- Review any results and confirm the expected date rules before acting.
SELECT *
FROM silver.erp_cust_az12
WHERE BDATE > CURRENT_DATE;

/*
 ================================================================================
 8. ERP CUSTOMER LOCATION INTEGRITY
 ================================================================================
 
 TABLE:
 silver.erp_loc_a101
 
 PURPOSE:
 Inspect customer identifier uniqueness, country values, and missing countries.
 */
-- ----------------------------------------------------------------------------
-- 8.1 CHECK FOR NULL OR DUPLICATE ERP LOCATION CUSTOMER IDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results, if each customer should have one location record.
SELECT cid,
    COUNT(*) AS row_count
FROM silver.erp_loc_a101
GROUP BY cid
HAVING cid IS NULL
    OR COUNT(*) > 1
ORDER BY cid NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 8.2 REVIEW DISTINCT COUNTRY VALUES
-- ----------------------------------------------------------------------------
-- EXPECTATION: Country values should follow consistent source conventions.
-- Review abbreviations, spelling, whitespace, and NULL values.
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 8.3 INVESTIGATE MISSING COUNTRY VALUES
-- ----------------------------------------------------------------------------
SELECT *
FROM silver.erp_loc_a101
WHERE cntry IS NULL;

-- ----------------------------------------------------------------------------
-- 8.4 CHECK FOR UNWANTED SPACES IN COUNTRY VALUES
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
SELECT cntry,
    LENGTH(cntry) AS original_length,
    LENGTH(TRIM(cntry)) AS trimmed_length
FROM silver.erp_loc_a101
WHERE cntry IS NOT NULL
    AND cntry <> TRIM(cntry);

SELECT *
FROM silver.erp_loc_a101;

/*
 ================================================================================
 9. ERP PRODUCT CATEGORY INTEGRITY
 ================================================================================
 
 TABLE:
 silver.erp_px_cat_g1v2
 
 PURPOSE:
 Inspect product category identifiers, uniqueness, and descriptive values.
 */
-- ----------------------------------------------------------------------------
-- 9.1 CHECK FOR NULL OR DUPLICATE CATEGORY PRODUCT IDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results, if ID is expected to uniquely identify a record.
SELECT id,
    COUNT(*) AS row_count
FROM silver.erp_px_cat_g1v2
GROUP BY id
HAVING id IS NULL
    OR COUNT(*) > 1
ORDER BY id NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 9.2 REVIEW DISTINCT CATEGORY VALUES
-- ----------------------------------------------------------------------------
SELECT DISTINCT cat
FROM silver.erp_px_cat_g1v2
ORDER BY cat NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 9.3 REVIEW DISTINCT SUBCATEGORY VALUES
-- ----------------------------------------------------------------------------
SELECT DISTINCT subcat
FROM silver.erp_px_cat_g1v2
ORDER BY subcat NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 9.4 REVIEW DISTINCT MAINTENANCE VALUES
-- ----------------------------------------------------------------------------
SELECT DISTINCT maintenance
FROM silver.erp_px_cat_g1v2
ORDER BY maintenance NULLS FIRST;

-- ----------------------------------------------------------------------------
-- 9.5 CHECK FOR UNWANTED SPACES IN CATEGORY TEXT FIELDS
-- ----------------------------------------------------------------------------
-- EXPECTATION: No Results
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE (
        cat IS NOT NULL
        AND cat <> TRIM(cat)
    )
    OR (
        subcat IS NOT NULL
        AND subcat <> TRIM(subcat)
    )
    OR (
        maintenance IS NOT NULL
        AND maintenance <> TRIM(maintenance)
    );

/*
 ================================================================================
 END OF SILVER QUALITY CHECKS
 ================================================================================
 ================================================================================
 */