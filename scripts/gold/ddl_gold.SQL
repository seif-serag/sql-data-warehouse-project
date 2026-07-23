/*
===============================================================================
DDL Script: Create Gold Layer Views
===============================================================================
Script Purpose:
    This script creates dimension and fact views for the Gold layer in the data 
    warehouse (Star Schema). It performs key transformations, merges CRM and ERP 
    data, generates surrogate keys, and formats column names for business use.
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1. Create Dimension: Customers (gold.dim_customers)
-------------------------------------------------------------------------------

-- Drop existing view if it exists
if OBJECT_id ('gold.dim_customers') is not null
	drop view gold.dim_customers
go

-- Create Customer Dimension View
create view gold.dim_customers as
select
    -- Generate surrogate key for customers
	ROW_NUMBER() over (order by ci.cst_id ) as customer_key,
    
    -- Customer Business & Natural Identifiers
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
    
    -- Demographics & Personal Attributes
	ci.cst_fisrtname as fisrt_name,
	ci.cst_lastname as last_name,
	la.cntry as country,
	ci.cst_material_status as material_status,
    
    -- Handle missing gender info by falling back on ERP source data
	case	when ci.cst_gndr != 'n/a' then ci.cst_gndr
			else coalesce (ca.gen , 'n/a')
	end gender,
    
	ca.bdate as birthdate,
	ci.cst_create_date as create_date

-- Source Data Integration (CRM primary, ERP secondary)
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
	on ci.cst_key = ca.cid
left join silver.erp_loc_a101 la
	on ci.cst_key = la.cid
go

-------------------------------------------------------------------------------
-- 2. Create Dimension: Products (gold.dim_products)
-------------------------------------------------------------------------------

-- Drop existing view if it exists
if OBJECT_id ('gold.dim_products') is not null
	drop view gold.dim_products
go

-- Create Product Dimension View
create view gold.dim_products as
select
    -- Generate surrogate key for products
	ROW_NUMBER() over (order by pn.prd_start_dt , pn.prd_key) as product_key,
    
    -- Product Identifiers and Names
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
    
    -- Product Hierarchy & Categorization
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
    
    -- Attributes & Pricing
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date

-- Source Data Integration
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
	on pn.cat_id = pc.id

-- Filter out historical/inactive records to retain only current active products
where pn.prd_end_dt is null
go

-------------------------------------------------------------------------------
-- 3. Create Fact Table: Sales (gold.fact_sales)
-------------------------------------------------------------------------------

-- Drop existing view if it exists
if OBJECT_id ('gold.fact_sales') is not null
	drop view gold.fact_sales
go

-- Create Sales Fact View
create view gold.fact_sales as
select
    -- Degenerate Dimension / Order Reference
	sd.sls_ord_num as order_number,
    
    -- Foreign Keys to Gold Dimensions
	pr.product_key,
	cu.customer_key,
    
    -- Dates & Timestamps
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
    
    -- Sales Metrics / Measures
	sd.sls_sales as sales_amount,
	sd.sls_quantity as quantity,
	sd.sls_price as price

-- Source Data & Dimension Lookups
from silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	on sd.sls_prd_key = pr.product_number
left join gold.dim_customers cu
	on sd.sls_cust_id = cu.customer_id
