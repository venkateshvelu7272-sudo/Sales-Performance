use ProductDataBase


--1. Gather essential fields such as product name, category, subcategory, and cost.
create view Products_Report as
with base_Query as
(
select 
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost,
s.order_number,
s.order_date,
s.customer_key,
s.sales_amount,
s.quantity
from cleaned_product_details p
left join Cleaned_Sales_Details s
on s.product_key = p.product_key
where order_date is not null
)

/* 2. Aggregates product-level metrics:
		- total orders
		- total sales
		- total quantity sold
		- total customers (unique)
		- lifespan (in months) */
, Product_Aggregation as (
select
 product_key,
 product_name,
 category,
 subcategory,
 cost,
 Count(distinct order_number) as Total_Orders,
 sum(sales_amount) as Total_Sales,
 sum(quantity) as Total_Quantity_Sold,
 count(distinct customer_key) as Total_Customer,
 datediff(month, min(order_date), max(order_date) ) as LifeSpan,
 max(order_date) as Last_OrderDate
 from base_Query
 group by
	 product_key,
	 product_name,
	 category,
	 subcategory,
	 cost
 )

-- 3 final querry combines all product result into one output
--segment products by revenue to identify high-performance, mid-range, or low-performance
select
 product_key,
 product_name,
 category,
 subcategory,
 cost,
 Total_Orders,
 Total_Sales,
 Total_Quantity_Sold,
 Total_Customer,
 LifeSpan,
 Last_OrderDate,
 case when Total_Sales > 50000 then 'HIGH Performance'
	  when Total_Sales > 25000 then 'MID-Range Performance'
	  else 'LOW Performance'
end Product_Segment,
--4. calculates valuable KPIs:
-- recency (months since last sale)
datediff(month,Last_OrderDate,getdate()) as Recency_In_Month,
-- Average Order Value 
case when Total_Orders = 0 then 0
     else Total_Sales / Total_Orders
end Avg_Ord_Revenue,
--Average Monthly Revenue 
case when LifeSpan = 0 then 0
	 else Total_Sales / LifeSpan
end Avg_Monthly_Revenue
from Product_Aggregation





select * from Products_Report