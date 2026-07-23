/*
========================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
========================================================================================

Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;

========================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	-- Declare tracking variables for overall and per-table execution duration
	DECLARE @start_time DATETIME, @end_time DATETIME, @bronze_start_time DATETIME, @bronze_end_time DATETIME;
	
	BEGIN TRY
		-- Track total execution start time for the Bronze layer batch
		SET @bronze_start_time = GETDATE();

		PRINT '======================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '======================================================';

		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------------';

		-------------------------------------------------------------------------------
		-- 1. Load CRM Table: bronze.crm_cust_info
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		PRINT '>>Inserting Data Into: bronze.crm_cust_info';
		-- Bulk load customer raw data from CRM CSV source file
		BULK INSERT bronze.crm_cust_info
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		with	(
				FIRSTROW = 2,           -- Skip CSV header row
				FIELDTERMINATOR = ',',  -- Comma-separated values
				TABLOCK                 -- Minimal logging / table lock for faster load
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 2. Load CRM Table: bronze.crm_prd_info
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		PRINT '>>Inserting Data Into: bronze.crm_prd_info';
		-- Bulk load product raw data from CRM CSV source file
		BULK INSERT bronze.crm_prd_info
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		with	(
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 3. Load CRM Table: bronze.crm_sales_details
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
	
		PRINT '>>Inserting Data Into: bronze.crm_sales_details';
		-- Bulk load sales transactions raw data from CRM CSV source file
		BULK INSERT bronze.crm_sales_details
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		with	(
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';
		
		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------------';

		-------------------------------------------------------------------------------
		-- 4. Load ERP Table: bronze.erp_cust_az12
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>>Inserting Data Into: bronze.erp_cust_az12';
		-- Bulk load customer demographic/ERP raw data from CSV source file
		BULK INSERT bronze.erp_cust_az12
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
		with	(
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';
		
		-------------------------------------------------------------------------------
		-- 5. Load ERP Table: bronze.erp_loc_a101
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
	
		PRINT '>>Inserting Data Into: bronze.erp_loc_a101';
		-- Bulk load location raw data from ERP CSV source file
		BULK INSERT bronze.erp_loc_a101
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
		with	(
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 6. Load ERP Table: bronze.erp_px_cat_g1v2
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
	
		PRINT '>>Inserting Data Into: bronze.erp_px_cat_g1v2';
		-- Bulk load product category hierarchy raw data from ERP CSV source file
		BULK INSERT bronze.erp_px_cat_g1v2
		from 'E:\Data Engineering\SQL\SQL\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
		with	(
				FIRSTROW = 2,
				FIELDTERMINATOR = ',',
				TABLOCK
				);
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-- Measure total execution time for the full Bronze layer load
		SET @bronze_end_time = GETDATE();
		PRINT '>>Bronze Layer Load Duration: ' + CAST(DATEDIFF(second, @bronze_start_time, @bronze_end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';
	END TRY
	
	-------------------------------------------------------------------------------
	-- Centralized Error Handling Block
	-------------------------------------------------------------------------------
	BEGIN CATCH
		PRINT '======================================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '======================================================';
	END CATCH
END
