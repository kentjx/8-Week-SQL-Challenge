/* 3. Product Funnel Analysis
Using a single SQL query - create a new output table which has the following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
Additionally, create another table which further aggregates the data for the above points but this time for each product category instead of individual products.

Use your 2 new output tables - answer the following questions:

Which product had the most views, cart adds and purchases?
Which product was most likely to be abandoned?
Which product had the highest view to purchase percentage?
What is the average conversion rate from view to cart add?
What is the average conversion rate from cart add to purchase? */ 


With product_view as (
select ph.page_name, count(visit_id) as count_view
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where i.event_name = 'Page View'
group by 1  -- straight forward, this returns the aggregation of products who had viewed the page 
),

add_to_cart as (
select ph.page_name, count(visit_id) as count_add_to_cart
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where i.event_name = 'Add to Cart' 
group by 1 -- same as above, condition is add to cart. 
), 

list_visitid_purchase as ( 
select e.visit_id
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where i.event_name = 'Purchase' -- this turns a list of users who had made a purchase 
), 

add_to_cart_no_purchase as (
select ph.page_name, count(visit_id) as count_add_to_cart_no_purchase 
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where i.event_name = 'Add to Cart'
and e.visit_id not in (select * from list_visitid_purchase) -- we want to minus away the list of user who have made the purchase, to find out those that viewed cart but did not make purchase 
group by 1
),

purchase as ( 
select ph.page_name, count(visit_id) as count_purchased
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where e.visit_id in (select * from list_visitid_purchase)
and i.event_name = 'Add to Cart' or i.event_name = 'Purchase'
group by 1 
),

temp_table as (
select ph.product_category, v.page_name,v.count_view, c.count_add_to_cart, np.count_add_to_cart_no_purchase, p.count_purchased
from product_view v
join add_to_cart c on v.page_name = c.page_name
join add_to_cart_no_purchase np on v.page_name = np.page_name
join purchase p on v.page_name = p.page_name
join clique_bait.page_hierarchy ph on v.page_name = ph.page_name
), 

temp_table2 as (
select product_category, sum(count_view) as count_view, sum(count_add_to_cart) as count_add_to_cart, sum(count_add_to_cart_no_purchase) as count_add_to_cart_no_purchase, 
sum(count_purchased) as count_purchased
from temp_table 
group by 1 
) 

--select * from 
--temp_table 

--select * from 
--temp_table2 

--Which product had the most views, cart adds and purchases?
select page_name, count_view
from 
temp_table 
order by 2 desc 
limit 1 

--Oyster: 1568 

select page_name, count_add_to_cart 
from temp_table
order by 2 desc
limit 1 

-- Lobster: 968 

select page_name, count_purchased 
from temp_table 
order by 2 desc
limit 1 

-- Lobster: 754 

--Which product was most likely to be abandoned? 

select page_name, count_add_to_cart_no_purchase
from temp_table 
order by 2 desc
limit 1 

-- Russian Caviar: 249 

--Which product had the highest view to purchase percentage? 

select page_name, round(cast(count_purchased as decimal(10,2))/cast(count_view as decimal(10,2)) * 100,2)  as pct_view_to_purchase 
from temp_table
order by 2 desc
limit 1

-- lobster: 48.74%

--What is the average conversion rate from view to cart add? 
--What is the average conversion rate from cart add to purchase? 
select round(avg(cast(count_add_to_cart as decimal(10,2))/cast(count_view as decimal(10,2)) * 100),2) as average_conversion_view2cart , 
round(avg(cast(count_purchased as decimal(10,2))/cast(count_add_to_cart as decimal(10,2)) * 100),2) as average_converison_cart2purchase
from temp_table 

-- average conversion rate from view to cart add: 60.95% 
-- average conversion rate from cart add to purchase: 75.93% 

