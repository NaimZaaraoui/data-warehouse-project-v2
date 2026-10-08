/*
 =============================================================
 Create Database and Schemas
 =============================================================
 
 Script Purpose:
 This script creates a new database named 'adventureworks_dwh' after checking if it already exists. 
 If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
 within the database: 'bronze', 'silver', and 'gold'.
 
 WARNING:
 To be able to DROP the database if exists, connect to the default 'postgres' database in psql then
 run the DROP command
 Running it will drop the entire 'adventureworks_dwh' database if it exists. 
 All data in the database will be permanently deleted. Proceed with caution 
 and ensure you have proper backups before running this script.
 */
-- \c postgres in psql
-- Drop the database if already exists
DROP DATABASE IF EXISTS adventureworks_dwh;

-- Create the dedicated Data Warehouse Database
CREATE DATABASE adventureworks_dwh;

-- COMMENT ON DATABASE adventureworks_dwh IS 'AdventureWorks Data Warehouse Database';
COMMENT ON DATABASE adventureworks_dwh IS 'AdventureWorks Data Warehouse Database';

-- Create isolated medallion layer schemas
CREATE SCHEMA IF NOT EXISTS bronze;

COMMENT ON SCHEMA bronze IS 'Bronze Layer: Raw data';

CREATE SCHEMA IF NOT EXISTS silver;

COMMENT ON SCHEMA silver IS 'Silver Layer: Cleaned, standardized data';

CREATE SCHEMA IF NOT EXISTS gold;

COMMENT ON SCHEMA gold IS 'Gold Layer: Business-ready data';

- -