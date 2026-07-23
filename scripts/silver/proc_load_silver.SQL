/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
Actions Performed:
    - Truncates Silver tables.
    - Inserts transformed and cleansed data from Bronze into Silver tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/
create or alter procedure silver.load_silver AS
Begin
	-- Declare tracking variables for overall and per-table execution metrics
	DECLARE @start_time DATETIME, @end_time DATETIME, @silver_start_time DATETIME, @silver_end_time DATETIME;
	
	Begin try
		-- Mark the start time for the overall Silver layer ETL process
		SET @silver_start_time = GETDATE();

		PRINT '======================================================';
		PRINT 'Loading Silver Layer';
		PRINT '======================================================';

		PRINT '------------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------------';

		-------------------------------------------------------------------------------
		-- 1. Load Table: silver.crm_cust_info
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.crm_cust_info';
		truncate table silver.crm_cust_info;
		
		print '>> Inserting Data Into: silver.crm_cust_info';
		insert into silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_fisrtname,
			cst_lastname,
			cst_material_status,
			cst_gndr,
			cst_create_date)

		SELECT
			cst_id,
			cst_key,
			-- Trim leading/trailing whitespaces from customer names
			TRIM(cst_fisrtname) AS cst_fisrtname,
			TRIM(cst_lastname) AS cst_lastname,
			-- Standardize marital status codes to full descriptive values
			case	when upper(trim(cst_material_status)) = 'M' then 'Maried'
					when upper(trim(cst_material_status)) = 'S' then 'Single'
					else 'n/a'
			end cst_material_status,
			-- Standardize gender values
			case	when upper(trim(cst_gndr)) = 'M' then 'Male'
					when upper(trim(cst_gndr)) = 'F' then 'Female'
					else 'n/a'
			end cst_gndr,
			cst_create_date
		FROM (
			-- Deduplicate records by selecting only the latest entry per customer ID
			SELECT
				*,
				ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			FROM bronze.crm_cust_info
			where cst_id is not null
		) t where flag_last = 1
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 2. Load Table: silver.crm_prd_info
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.crm_prd_info';
		truncate table silver.crm_prd_info;
		
		print '>> Inserting Data Into: silver.crm_prd_info';
		insert into silver.crm_prd_info (
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt)

		Select
			prd_id,
			-- Extract category ID prefix from composite product key
			replace(SUBSTRING(prd_key , 1 , 5),'-','_') AS cat_id,
			-- Extract clean product key suffix
			SUBSTRING(prd_key ,7, LEN(prd_key)) as prd_key,
			prd_nm,
			-- Handle NULL values for product cost by defaulting to 0
			ISNULL (prd_cost,0) as prd_cost,
			-- Standardize product line codes
			case when	upper(trim(prd_line)) = 'M' then 'Mountain'
				 when	upper(trim(prd_line)) = 'R' then 'Road'
				 when	upper(trim(prd_line)) = 'S' then 'Other Sales'
				 when	upper(trim(prd_line)) = 'T' then 'Touring'
						else 'n/a'
			end prd_line,
			cast(prd_start_dt AS date) AS prd_start_dt,
			-- Calculate SCD Type 2 end date using LEAD window function
			cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 AS Date) AS prd_end_dt
		from bronze.crm_prd_info
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 3. Load Table: silver.crm_sales_details
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.crm_sales_details';
		truncate table silver.crm_sales_details;
		
		print '>> Inserting Data Into: silver.crm_sales_details';
		insert into silver.crm_sales_details(
				sls_ord_num,
				sls_prd_key,
				sls_cust_id,
				sls_order_dt,
				sls_ship_dt,
				sls_due_dt,
				sls_sales,
				sls_quantity,
				sls_price
				)

		select
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			-- Convert integer YYYYMMDD date representations into proper DATE data types
			case	when sls_order_dt = 0 or len(sls_order_dt) != 8 then null
					else cast(cast(sls_order_dt as varchar) as date)
			end sls_order_dt,
			case	when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null
					else cast(cast(sls_ship_dt as varchar) as date)
			end sls_ship_dt,
			case	when sls_due_dt = 0 or len(sls_due_dt) != 8 then null
					else cast(cast(sls_due_dt as varchar) as date)
			end sls_due_dt,
			-- Recalculate sales amount if invalid, non-positive, or mismatched with (quantity * price)
			case	when sls_sales <= 0 or sls_sales is null or sls_sales != sls_quantity * ABS(sls_price) then sls_quantity * ABS(sls_price)
					else sls_sales
			end sls_sales,
			sls_quantity,
			-- Recalculate unit price if missing or non-positive
			case	when sls_price <= 0 or sls_price is null then sls_sales / nullif( sls_quantity,0)
					else sls_price
			end sls_price
		from bronze.crm_sales_details
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		PRINT '------------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------------';

		-------------------------------------------------------------------------------
		-- 4. Load Table: silver.erp_cust_az12
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;
		
		print '>> Inserting Data Into: silver.erp_cust_az12';
		insert into silver.erp_cust_az12 (
			cid,
			bdate,
			gen)

		select
			-- Remove unwanted prefix 'NAS' if present in customer ID
			case	when cid like 'NAS%' then SUBSTRING(cid,4,len(cid))
					else cid
			end cid,
			-- Invalidate future/unrealistic birth dates by setting to NULL
			case	when bdate > getdate() then null
					else bdate
			end bdate,
			-- Standardize gender representation
			case	when upper(trim(gen)) in ('F' , 'FEMALE') then 'Female'
					when upper(trim(gen)) in ('M' , 'MALE') then 'Male'
					else 'n/a'
			end gen
		from bronze.erp_cust_az12
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 5. Load Table: silver.erp_loc_a101
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;
		
		print '>> Inserting Data Into: silver.erp_loc_a101';
		insert into silver.erp_loc_a101 (
			cid,
			cntry)

		select
			-- Normalize customer IDs by stripping hyphens
			replace(cid,'-','') as cid,
			-- Map country codes to full country names
			case	when trim(cntry) = 'DE' then 'Germany'
					when trim(cntry) in ('US' , 'USA') then 'United States'
					when trim(cntry) is null or trim(cntry) = '' then 'n/a'
					else cntry
			end cntry
		from bronze.erp_loc_a101
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-------------------------------------------------------------------------------
		-- 6. Load Table: silver.erp_px_cat_g1v2
		-------------------------------------------------------------------------------
		SET @start_time = GETDATE();
		print '>> Truncating Table: silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2;
		
		print '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		insert into silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
			)
		select
			id,
			cat,
			subcat,
			maintenance
		from bronze.erp_px_cat_g1v2
		
		SET @end_time = GETDATE();
		PRINT '>>Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';

		-- Measure total runtime for the Silver layer pipeline
		SET @silver_end_time = GETDATE();
		PRINT '>>Silver Layer Load Duration: ' + CAST(DATEDIFF(second, @silver_start_time, @silver_end_time) AS NVARCHAR) + ' seconds';
		PRINT '-------------';
	end try
	
	-------------------------------------------------------------------------------
	-- Centralized Error Handling Block
	-------------------------------------------------------------------------------
	begin catch
		PRINT '======================================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '======================================================';
	end catch
end
