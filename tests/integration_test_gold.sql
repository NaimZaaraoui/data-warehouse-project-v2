SELECT DISTINCT
    cci.cst_gndr,
    eca.gen,
    CASE cci.cst_gndr
        WHEN 'n/a' THEN COALESCE(eca.gen, 'n/a')
        ELSE cci.cst_gndr -- CRM is the master for gender info
    END AS final_gen
FROM silver.crm_cust_info cci
LEFT JOIN silver.erp_cust_az12 eca
    ON cci.cst_key = eca.cid
LEFT JOIN silver.erp_loc_a101 ela
    ON cci.cst_key = ela.cid
ORDER BY 1,2;


