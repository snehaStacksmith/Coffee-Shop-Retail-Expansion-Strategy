SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;
--1 Coffee Consumers
SELECT 
	city_name,
	ROUND((population * 0.25)/1000000,2) AS coffee_consumer_in_M,
	city_rank
	
FROM city
ORDER BY 2 DESC;

--2 Total revenue from coffee sales in last quarter

SELECT
	ci.city_name,
	SUM(s.total) AS revenue

FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON c.city_id = ci.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date)=2023
	AND
	EXTRACT(QUARTER FROM s.sale_date)=4
GROUP BY ci.city_name
ORDER BY revenue DESC;


--3 Sales Count For Each product
SELECT
	p.product_name,
	COUNT(s.sale_id)
FROM products p
JOIN sales s
ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

--4 Average sales amount per customer in each city
SELECT
	ci.city_name,
	SUM(s.total) AS total_city_sales,
	COUNT(DISTINCT c.customer_id) AS customer_count,
	ROUND(SUM(s.total)::NUMERIC/COUNT(DISTINCT c.customer_id),2) AS Avg_sales_per_customer
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON c.city_id = ci.city_id
GROUP BY ci.city_name
ORDER BY Avg_sales_per_customer DESC;

--5 List of cities, their estimated customers(25% of population) nd unique customers
WITH city_table AS(

SELECT city_name,
		ROUND(((population * 0.25)/1000000),2) AS coffee_consumers_in_millions
FROM city

),

customers_table AS(
SELECT 
	ci.city_name,
	COUNT(DISTINCT s.customer_id) AS unique_customers

FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY 2 DESC

)
SELECT 
	city_table.city_name,
	city_table.coffee_consumers_in_millions,
	customers_table.unique_customers
FROM city_table 
JOIN customers_table 
ON city_table.city_name = customers_table.city_name

ORDER BY 2 DESC;

-- 6 Top 3 selling products in each city

SELECT *
FROM
	(SELECT
		 ci.city_name,
		 p.product_name,
		 COUNT(s.sale_id) as total_sales,
		 DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC ) as rank
	FROM products p
	JOIN sales s
	ON p.product_id= s.product_id
	JOIN customers c
	ON s.customer_id = c.customer_id
	JOIN city ci
	ON c.city_id = ci.city_id
	GROUP BY 1,2
	)as t1
WHERE rank<=3;

--7 Customer Segmentation List of customers for each city who purchased coffee products

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customers
FROM city ci
JOIN customers c
ON ci.city_id = c.city_id
JOIN sales s
ON c.customer_id = s.customer_id
WHERE s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
GROUP BY  1;

--8 for each city, avg sales per customer vs avg rent per customer
WITH sales_table AS
(SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT( DISTINCT s.customer_id) as unique_customers,
	ROUND((SUM(s.total)::numeric/COUNT( DISTINCT s.customer_id)),2) as avg_sales_per_customer
	
FROM city ci
JOIN customers c
ON ci.city_id = c.city_id
JOIN sales s
ON c.customer_id = s.customer_id
GROUP BY 1
ORDER BY 2 DESC),

rent_table AS
(
SELECT 
	ci.city_name,
	ci.estimated_rent
FROM city ci
)

SELECT 
	rt.city_name,
	st.total_revenue,
	st.unique_customers,
	st.avg_sales_per_customer,
	rt.estimated_rent,
	ROUND((rt.estimated_rent::numeric/st.unique_customers::numeric),2) as avg_rent_per_customers
FROM sales_table st
JOIN rent_table rt
ON st.city_name = rt.city_name
order by 4 desc;

--9 Sales growth/decline rate for each city monthly
WITH monthly_sales as

(SELECT 
	ci.city_name,
	EXTRACT(month from sale_date) as month,
	EXTRACT(year from sale_date) as year,
	SUM(s.total) as total_sales
FROM sales s
JOIN customers c
ON s.customer_id = c.customer_id
JOIN city ci
ON ci.city_id = c.city_id
GROUP BY 1, 2,3
ORDER BY 1,3,2
),
growth_table AS

(SELECT 
	city_name,
	month,
	year,
	total_sales as cr_month_sales,
	LAG(total_sales, 1) OVER (PARTITION BY city_name ORDER BY year,month) as last_month_sales
FROM monthly_sales
)

SELECT city_name,
		month,
		year,
		cr_month_sales,
		last_month_sales,
		ROUND(((cr_month_sales - last_month_sales)::numeric/last_month_sales::numeric)*100,2) as growth_ratio

FROM growth_table;


--10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH sales_table AS
(SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT( DISTINCT s.customer_id) as unique_customers,
	ROUND((SUM(s.total)::numeric/COUNT( DISTINCT s.customer_id)),2) as avg_sales_per_customer
	
FROM city ci
JOIN customers c
ON ci.city_id = c.city_id
JOIN sales s
ON c.customer_id = s.customer_id
GROUP BY 1
ORDER BY 2 DESC),

rent_table AS
(
SELECT 
	city_name,
	estimated_rent,
	ROUND (((population * 0.25)/1000000),2) as estimated_coffee_consumers_in_M
FROM city 
)

SELECT 
	rt.city_name,
	st.total_revenue,
	rt.estimated_rent as total_rent,
	st.unique_customers,
	estimated_coffee_consumers_in_M,
	st.avg_sales_per_customer,
	
	ROUND((rt.estimated_rent::numeric/st.unique_customers::numeric),2) as avg_rent_per_customers
FROM sales_table st
JOIN rent_table rt
ON st.city_name = rt.city_name
order by 2 desc;


/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
*/