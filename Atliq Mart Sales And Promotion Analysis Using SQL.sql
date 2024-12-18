USE retail_events_db;

-- Business Requests

/* 1. Provide a list of products with a base price greater than 500 and that are featured in promo type of 
     'BOGOF' (Buy One Get One Free)? */
 
SELECT DISTINCT t2.product_code, t1.product_name, t2.base_price FROM dim_products t1
JOIN fact_events t2
ON t1.product_code = t2.product_code
WHERE t2.product_code IN (SELECT DISTINCT product_code FROM fact_events
							WHERE base_price > 500 AND promo_type = 'BOGOF');
                            
-- -------------------------------------------------------------------------------------------------------
                            
/* 2. Generate a report that provides an overview of the number of stores in each city? */

SELECT city, count(*) AS num_stores FROM retail_events_db.dim_stores
GROUP BY city
ORDER BY num_stores DESC;

-- ---------------------------------------------------------------------------------------------------------

/* 3. Generate a report that displays each campaign along with the total revenue generated before and after 
      campaign? */
      
SELECT t2.campaign_name, 
round(sum(t1.base_price * t1.`quantity_sold(before_promo)`)/1000000,2) AS total_revenue_before_promo,
round(sum(t1.base_price * t1.`quantity_sold(after_promo)`)/1000000,2) AS total_revenue_after_promo
FROM fact_events t1 
JOIN dim_campaigns t2
ON t1.campaign_id = t2.campaign_id
GROUP BY t1.campaign_id;

-- --------------------------------------------------------------------------------------------------------

/* 4. Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the 
      Diwali campaign. Additionally provide rankings for the categories based on their ISU% */

SELECT t2.category,
SUM(`quantity_sold(after_promo)` - `quantity_sold(before_promo)`) / SUM(`quantity_sold(before_promo)`) * 100 AS Incremental_Sold_Quantity_Percentage,
RANK() OVER(ORDER BY SUM(`quantity_sold(after_promo)` - `quantity_sold(before_promo)`) / SUM(`quantity_sold(before_promo)`) * 100 DESC) AS isu_rank
FROM fact_events t1
JOIN dim_products t2
ON t1.product_code = t2.product_code
WHERE t1.campaign_id ='CAMP_DIW_01'
GROUP BY t2.category;

-- -------------------------------------------------------------------------------------------------------------------

/* 5. Create a report featuring top 5 products, ranked by Incremental Revenue Percentage (IR%) across all
      campains */
      
SELECT product_name, category,
ROUND((SUM(base_price * `quantity_sold(after_promo)`) - SUM(base_price * `quantity_sold(before_promo)`)) / SUM(base_price * `quantity_sold(before_promo)`) * 100,2) AS Incremental_Revenue_Percentage
FROM fact_events t1
JOIN dim_products t2
ON t1.product_code = t2.product_code
GROUP BY product_name
ORDER BY Incremental_Revenue_Percentage DESC
LIMIT 5;

-- ------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------

-- Store Performance Analysis

/* 1. Which are the top 10 stores in terms of Incremental Revenue (IR) generated from the promotions? */

SELECT t1.store_id, t2.city,
(SUM(`quantity_sold(after_promo)`*base_price) - SUM(`quantity_sold(before_promo)`*base_price))/1000000 AS Incremental_Revenue_In_Millions
FROM fact_events t1
JOIN dim_stores t2
ON t1.store_id = t2.store_id
GROUP BY t1.store_id
ORDER BY incremental_Revenue_In_Millions DESC 
LIMIT 10;

-- ----------------------------------------------------------------------------------------------------------------

/* 2. Which are the bottom 10 stores When it comes to Incremental Sold Units (ISU) during the promotional
      period? */
      
SELECT t1.store_id, t2.city,
SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS Incremental_Sold_Units
FROM fact_events t1
JOIN dim_stores t2
ON t1.store_id = t2.store_id
GROUP BY t1.store_id
ORDER BY incremental_Sold_Units
LIMIT 10;	

-- -----------------------------------------------------------------------------------------------------------

/* 3. How does the performance of stores vary by city? Are there any common characteristics among the top 
      performing stores that could be leveraged across other cities? */
      
SELECT t2.city,
(SUM(`quantity_sold(after_promo)`*base_price) - SUM(`quantity_sold(before_promo)`*base_price))/1000000 AS Incremental_Revenue_In_Millions
FROM fact_events t1
JOIN dim_stores t2
ON t1.store_id = t2.store_id
GROUP BY t2.city
ORDER BY incremental_Revenue_In_Millions DESC;

-- ------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------

-- Promotion Type Analysis

/* 1. What are the top 2 promotion types that are resulted in the highest Incremental Revenue? */

SELECT promo_type,
(SUM(`quantity_sold(after_promo)`*base_price) - SUM(`quantity_sold(before_promo)`*base_price))/1000000 AS IR_in_millions 
FROM fact_events
GROUP BY promo_type
ORDER BY IR_in_millions DESC
LIMIT 2;

-- ----------------------------------------------------------------------------------------------------------------

/* 2. What are the bottom 2 promotion types in terms of their impact on Incremental Sold Units? */

SELECT promo_type,
SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS ISU
FROM fact_events
GROUP BY promo_type
ORDER BY ISU
LIMIT 2;

-- ----------------------------------------------------------------------------------------------------------

/* 3. Is there significant difference in the performance of discount-based promotions versus BOGOF (Buy 1 Get 
	  1 Free) or cashback promotions? */

SELECT 
CASE 
	WHEN promo_type = '25% OFF' OR promo_type = '33% OFF' OR promo_type = '50% OFF' THEN 'Discount Based Promotion'
	WHEN promo_type = 'BOGOF' THEN 'Buy 1 Get 1 Free'
    	WHEN promo_type = '500 Cashback' THEN 'Cashback Promotion'
END AS promo_category,
(SUM(`quantity_sold(after_promo)`*base_price) - SUM(`quantity_sold(before_promo)`*base_price))/1000000 AS IR_in_millions
FROM fact_events
GROUP BY promo_category
ORDER BY IR_in_millions DESC;

-- --------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------

-- Product and Category Analysis

/* 1. Which product categories saw significant lift in sales from the promotions? */

SELECT t2.category, t1.promo_type,
SUM(`quantity_sold(before_promo)`) AS Quantity_Sold_Before_Promo,
SUM(`quantity_sold(after_promo)`) AS Quantity_Sold_After_Promo,
SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS ISU
FROM fact_events t1
JOIN dim_products t2
ON t1.product_code = t2.product_code
GROUP BY t2.category, t1.promo_type
ORDER BY ISU DESC;

-- -------------------------------------------------------------------------------------------------------------

/* 2. Are there specific products that respond exceptionally well or poor to promotions? */

SELECT t2.product_name, t1.promo_type,
SUM(`quantity_sold(before_promo)`) AS Quantity_Sold_Before_Promo,
SUM(`quantity_sold(after_promo)`) AS Quantity_Sold_After_Promo,
SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS ISU
FROM fact_events t1
JOIN dim_products t2
ON t1.product_code = t2.product_code
GROUP BY t2.product_name, t1.promo_type
HAVING ISU > 0
ORDER BY ISU DESC;

SELECT t2.product_name, t1.promo_type,
SUM(`quantity_sold(before_promo)`) AS Quantity_Sold_Before_Promo,
SUM(`quantity_sold(after_promo)`) AS Quantity_Sold_After_Promo,
SUM(`quantity_sold(after_promo)`) - SUM(`quantity_sold(before_promo)`) AS ISU
FROM fact_events t1
JOIN dim_products t2
ON t1.product_code = t2.product_code
GROUP BY t2.product_name, t1.promo_type
HAVING ISU < 0
ORDER BY ISU
