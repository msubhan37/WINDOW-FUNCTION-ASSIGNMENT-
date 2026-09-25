--7.1 - Assign a sequential row number to each product ordered by list_price descending.
--Then assign a second row number partitioned by category_id, resetting within each category.

select
	product_name,
	category_id,
	list_price,
		row_number() over ( order by list_price desc ) as overall_rank,
		row_number() over ( partition by category_id order by list_price desc ) as rank_with_category
from production.products
order by category_id, list_price desc;

--7.2 - Write a query that returns each product with its RANK() and DENSE_RANK() by list_price descending within its category.
--Show a product where the two rankings differ.

select 
	product_name,
	category_id,
	list_price,
	 rank() over ( partition by category_id order by list_price desc ) as its_rank,
	 dense_rank() over ( partition by category_id order by list_price desc ) as its_dense_rank
from production.products;

--7.3 - Use LAG() to calculate the month-over-month revenue change for each store. Show the current month revenue,
--the previous month revenue, and the difference.

with monthly_revenue as (
	select 
	o.store_id,
	DATEFROMPARTS( year(o.order_date), month(o.order_date), 1) as revenue_month,
	sum ( oi.quantity * oi.list_price * (1 - oi.discount)) as revenue 
	from sales.orders as o 
	join sales.order_items as oi 
	on o.order_id = oi.order_id

	group by 
	o.store_id,
	DATEFROMPARTS ( year(o.order_date) , month(o.order_date) , 1)
)

	select 
		store_id,
		revenue_month,
		revenue as current_month_revenue,
		lag(revenue) over ( partition by store_id order by revenue_month ) as previous_month_revenue,
		revenue - lag(revenue) over ( partition by store_id order by revenue_month ) as revenue_changed
	from monthly_revenue
	order by store_id, revenue_month;
		

--7.4 - Use NTILE(5) to divide all products into five price bands. Return the product name, price, and band number.

select 
	product_name,
	list_price,
		ntile(5) over (order by list_price) as band_number
from production.products;

--7.5 - Write a query that shows each order with a running total of revenue ordered by order_date.
--Use ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW.

select 
	o.order_id,
	o.order_date,
	--oi.list_price,
	--oi.discount,
	--oi.quantity,
		sum(oi.quantity * oi.list_price * ( 1 - oi.discount)) as order_revenue,
		sum (sum(oi.quantity * oi.list_price * ( 1 - oi.discount))) 
			over (order by o.order_date  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as runnig_total
from sales.orders as o
join sales.order_items as oi
on o.order_id = oi.order_id
group by o.order_id, o.order_date;

--7.6 - Think About It: Why does LAST_VALUE() require RANGE BETWEEN UNBOUNDED PRECEDING
--AND UNBOUNDED FOLLOWING to return the actual last value in the partition,
--while FIRST_VALUE() works correctly with the default frame? What is the default window frame when ORDER BY is specified,
--and how does that explain the behavior?

select
	order_id,
	order_status,
	order_date,
		first_value(order_status) over (
			partition by customer_id order by order_date )
		as first_status,

		last_value(order_status) over ( 
			partition by customer_id order by order_date 
		ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING )
		as last_status
from sales.orders;