/*
===========================================================================================
                                  Product Report
===========================================================================================
Purpose: 
   - this report consolidates key product metrics and behaviours.



Highlights:
1. Gather essential field such as product name, category, subcategory, and cost.
2. segments products by revenue to identify high-performers, Mid-range, or low-performers.
3. Aggregates product-level metrics:
 -total orders
 -total sales
 -total quantity sold
 -told customers (unique)
 -lifespan (in months)
4. Calculate valuable KPIs:
 -recently (monthly since last sale)
 -average order revenue 

=============================================================================================
*/

WITH base_query AS (

/*--------------------------------------------------------------------------------------
1) Base Query: Retrieves core columns from fact_sales and dim_products
----------------------------------------------------------------------------------------*/

    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
FROM [gold.fact_sales] f
LEFT JOIN [gold.dim_products] p
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
),

product_aggregations AS (
/*----------------------------------------------------------------------------------
2) Product Agrregation: Summarizes key metrics at the product level
--------------------------------------------------------------------------------------*/

SELECT 
product_key,
product_name,
category,
subcategory,
cost,
DATEDIFF(MONTH,MIN(order_date), MAX(order_date)) AS lifespan,
MAX(order_date) AS last_sale_date,
COUNT(DISTINCT order_number) AS total_order,
COUNT(DISTINCT customer_key) AS total_customers,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)),1) AS avg_selling_price

FROM base_query

GROUP BY 
product_key,
product_name,
category,
subcategory,
cost

)

/*--------------------------------------------------------------------------------------------------------------
 3) Final Query: Combines all product results into one output
 ---------------------------------------------------------------------------------------------------------------*/
 
 SELECT 
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
DATEDIFF(MONTH, last_sale_date, GETDATE()) AS recency_in_months,
CASE 
        WHEN total_sales > 50000 THEN 'High-performer'
        WHEN total_sales >= 50000 THEN 'Mid-range'
        ELSE 'Low-performer'
  END AS product_segment,
lifespan,
total_order,
total_sales,
total_quantity,
total_customers,
avg_selling_price,


--Average Order Revenue (AOR)
CASE
    WHEN total_order = 0 THEN 0
    ELSE CAST(total_sales AS FLOAT)/ total_order
    END as avg_order_revenue,


--Average Monthly Revenue 
CASE 
WHEN lifespan = 0 THEN total_sales
ELSE CAST(total_sales AS FLOAT) / lifespan
END AS avg_monthly_revenue


FROM product_aggregations;