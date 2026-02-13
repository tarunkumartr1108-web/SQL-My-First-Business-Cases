Business Case – Target SQL



Data type of all columns in the "customers" table

select column_name,data_type from `evident-syntax-452811-b5.Business_case_1.INFORMATION_SCHEMA.COLUMNS` WHERE TABLE_NAME="customers"


 
Get the time range between which the orders were placed.

select min(order_purchase_timestamp) as start_date,max(order_purchase_timestamp) as end_date
from `Business_case_1.orders`;


Count the Cities & States of customers who ordered during the given period.

select count(distinct(customer_city)) as total_cities , count(distinct(customer_state)) as total_states from `Business_case_1.customers`


In-depth Exploration:

Is there a growing trend in the no. of orders placed over the past years?

select Extract(year from order_purchase_timestamp) as order_year , count(*) as total_orders from `Business_case_1.orders`
group by order_year        
order by total_orders;
 

Can we see some kind of monthly seasonality in terms of the no. of orders being placed?

select FORMAT_DATE('%B',order_purchase_timestamp) as month, count(*) as total_orders  from 
`Business_case_1.orders`
  group by month
  order by total_orders desc;

During what time of the day, do the Brazilian customers mostly place their orders? (Dawn, Morning, Afternoon or Night)
o	0-6 hrs : Dawn
o	7-12 hrs : Mornings
o	13-18 hrs : Afternoon
o	19-23 hrs : Night

 with final as(
(select 1 ,customer_id,order_purchase_timestamp, extract(hour from order_purchase_timestamp) as hr, 
case  when extract(hour from order_purchase_timestamp) between 0 and 6 then "Dawn"
          when extract(hour from order_purchase_timestamp) between 7 and 12 then "Mornings"
           when extract(hour from order_purchase_timestamp) between 13 and 18 then "Evening"
           when extract(hour from order_purchase_timestamp) between 19 and 23 then "Night"
           else null end as time_of_the_day from `Business_case_1.orders` ))
  select time_of_the_day,count(time_of_the_day) as total_orders from final 
         group by time_of_the_day
         order by 1;



         
Evolution of E-commerce orders in the Brazil region:

Get the month on month no. of orders placed in each state.

with final as(
(select o.customer_id ,c.customer_state ,o.order_purchase_timestamp,
        extract(month from o.order_purchase_timestamp) as month,
        extract(year from o.order_purchase_timestamp) as year,
        row_number() over(order by order_purchase_timestamp) as row_num
        from `Business_case_1.orders` o  inner join `Business_case_1.customers` c 
        on c.customer_id = o.customer_id))

select customer_state , year , month, count(row_num) as total_orders 
           from final 
           group by 1,2,3 order by 1;

How are the customers distributed across all the states?

select   customer_state , 
          count(distinct(customer_id)) as total_customers 
         from `Business_case_1.customers`  
         group by customer_state
         order by 1;

Impact on Economy: Analyse the money movement by e-commerce by looking at order prices, freight and others.

Get the % increase in the cost of orders from year 2017 to 2018 (include months between Jan to Aug only).
with final as(
select  extract(year from o.order_purchase_timestamp) as year,
        extract(month from o.order_purchase_timestamp) as month,
        p.payment_value
        from `Business_case_1.orders` o inner join `Business_case_1.payments` p 
        on o.order_id = p. order_id
        where extract(year from o.order_purchase_timestamp)  between 2017 and 2018 and extract(month from o.order_purchase_timestamp) between 1 and 8),

old_ttl as(
select year ,sum(payment_value) as total_2017 from final where year = 2017 group by year),

new_ttl as(
  select year ,sum(payment_value) as total_2018 from final where year = 2018 group by year)

select total_2017,total_2018,round(((total_2018 - total_2017  )/o.total_2017)*100,2) as percen_increase from old_ttl o join new_ttl n on o.year!=n.year;


 Calculate the Total & Average value of order price for each state
select c.customer_state, round(sum(p.payment_value),2) as              total_payment,round(avg(p.payment_value),2) as avrg_payment

from `Business_case_1.customers` c left join `Business_case_1.orders` o on c.customer_id=o.customer_id
left join `Business_case_1.payments` p on p.order_id=o.order_id
group by 1 
order by 1;
 Calculate the Total & Average value of order freight for each state.
select c.customer_state , 
round(sum(freight_value),2) as total_freight_price ,
                          round(avg(freight_value),2) as avrg_freight_price
                          from `Business_case_1.customers` c left join `Business_case_1.orders` o
                          on c.customer_id = o.customer_id
                          left join `Business_case_1.orders_items` t 
                          on t.order_id = o.order_id
                          group by 1
                          order by 2,3;

Analysis based on sales, freight and delivery time.
Find the no. of days taken to deliver each order from the order’s purchase date as delivery time.
Also, calculate the difference (in days) between the estimated & actual delivery date of an order.

SELECT 
  order_purchase_timestamp,
  order_estimated_delivery_date,
  order_delivered_customer_date,
  DATE_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY) AS time_to_deliver,
  DATE_DIFF(order_delivered_customer_date, order_estimated_delivery_date, DAY) AS diff_estimated_delivery 
FROM `Business_case_1.orders` WHERE order_delivered_customer_date IS NOT NULL;


Find out the top 5 states with the highest & lowest average freight value.

WITH avrg AS (
  SELECT 
    c.customer_state, 
    AVG(freight_value) AS avrg_freight_price
  FROM `Business_case_1.customers` c 
  LEFT JOIN `Business_case_1.orders` o ON c.customer_id = o.customer_id
  LEFT JOIN `Business_case_1.orders_items` t ON t.order_id = o.order_id
  GROUP BY c.customer_state
),
rnk AS (
  SELECT 
    customer_state, 
    avrg_freight_price, 
    ROW_NUMBER() OVER(ORDER BY avrg_freight_price DESC) AS highest_val,
    ROW_NUMBER() OVER(ORDER BY avrg_freight_price ASC) AS lowest_val
  FROM avrg
),
lowest_avg AS (
  SELECT 
    customer_state AS lowest_state,
    avrg_freight_price AS lowest_average,
    ROW_NUMBER() OVER () AS rn
  FROM rnk 
  WHERE lowest_val BETWEEN 1 AND 5
),
highest_avg AS (
  SELECT customer_state AS highest_state,
         avrg_freight_price AS highest_average,
    ROW_NUMBER() OVER () AS rn
  FROM rnk 
  WHERE highest_val BETWEEN 1 AND 5
)
SELECT lowest_state,lowest_average,highest_state,highest_average FROM lowest_avg JOIN highest_avg USING (rn);

 


Find out the top 5 states with the highest & lowest average delivery time.

(select c.customer_state,round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,DAY)),2) as avg_delivery_time,
       "Highest" as Category
from `Business_case_1.customers` c inner join `Business_case_1.orders` o on c.customer_id=o.customer_id
where o.order_delivered_customer_date is not null and o.order_purchase_timestamp is not null
group by c.customer_state
order by avg_delivery_time desc limit 5)

union all

(select c.customer_state,round(avg(date_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,DAY)),2) as avg_delivery_time,
       "Lowest" as Category
from `Business_case_1.customers` c inner join `Business_case_1.orders` o on c.customer_id=o.customer_id
where o.order_delivered_customer_date is not null and o.order_purchase_timestamp is not null
group by c.customer_state
order by avg_delivery_time asc limit 5)


Find out the top 5 states where the order delivery is really fast as compared to the estimated date of delivery.

select c.customer_state,round(avg(date_diff(o.order_estimated_delivery_date,o.order_delivered_customer_date,DAY)),2) as delivery_speed

from `Business_case_1.customers` c inner join `Business_case_1.orders` o on c.customer_id=o.customer_id
where o.order_delivered_customer_date is not null and o.order_estimated_delivery_date is not null and date_diff(o.order_estimated_delivery_date,o.order_delivered_customer_date,DAY)>0
group by c.customer_state
order by delivery_speed desc limit 5



Analysis based on the payments

Find the month on month no. of orders placed using different payment types.

SELECT 
  FORMAT_DATE('%Y-%m', o.order_purchase_timestamp) AS order_month,
  p.payment_type,
  COUNT(DISTINCT o.order_id) AS total_orders
FROM 
  `Business_case_1.orders` o
JOIN 
  `Business_case_1.payments` p
ON 
  o.order_id = p.order_id
GROUP BY 
  order_month, p.payment_type
ORDER BY 
  order_month, p.payment_type;


Find the no. of orders placed on the basis of the payment installments that have been paid.
select payment_installments,
       count(distinct(order_id)) as total_orders 
       from `Business_case_1.payments` 
       group by 1 order by 1,2



