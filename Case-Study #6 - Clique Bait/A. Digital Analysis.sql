 /* Part A. Digital Analysis 
How many users are there?
How many cookies does each user have on average?
What is the unique number of visits by all users per month?
What is the number of events for each event type?
What is the percentage of visits which have a purchase event?
What is the percentage of visits which view the checkout page but do not have a purchase event?
What are the top 3 pages by number of views?
What is the number of views and cart adds for each product category?
What are the top 3 products by purchases? */

-- How many users are there?
select count (distinct user_id) as count_of_users
from clique_bait.users 

-- Ans: 500 

--How many cookies does each user have on average?
with temp as (
select cast(count (distinct user_id) as numeric) as count_of_users, cast(count (cookie_id) as numeric) as count_cookie
from clique_bait.users
) 
select round(count_cookie / count_of_users, 2) as average_cookie_each_user
from temp 

--Ans: 3.56

--What is the unique number of visits by all users per month?
Select extract(month from event_time), count(distinct visit_id) as unique_visits
from clique_bait.events e
inner join clique_bait.users u on e.cookie_id = u.cookie_id
group by 1

-- What is the number of events for each event type?
select e.event_type, i.event_name, count(e.event_type) as Count_of_event
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type
group by 1, 2 

--What is the percentage of visits which have a purchase event? 
select round(cast(count(case when i.event_name = 'Purchase' then e.visit_id end)as numeric) / cast(count( distinct e.visit_id) as numeric) * 100, 2) as pct_visits_purchase
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type

-- What is the percentage of visits which view the checkout page but do not have a purchase event?

select  round(1 - cast(count(case when i.event_name = 'Purchase' then e.visit_id end) as numeric) / cast(count(case when i.event_name = 'Page View' AND e.page_id = 12 then e.visit_id end)as numeric),3) * 100 as see_but_no_buy
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type

select  (1 - cast(count(case when i.event_name = 'Purchase' then e.visit_id end) as numeric)) / cast(count(case when i.event_name = 'Page View' AND e.page_id = 12 then e.visit_id end)as numeric) * 100 as see_but_no_buy
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type

-- the logic here is such that, we first find out how many visit_ids when event_name = 'purchases' (A)
-- we also find out how many visit_ids when event_name = page_view AND page_id = 12 (B) ie. user who viewed the check out page. 
-- we then do a 1 - (A/B) = to find out those that did not purchase / B 

-- What are the top 3 pages by number of views?

Select ph.page_name, count(e.visit_id) as count_
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
group by 1 
order by 2 desc
limit 3 

-- What is the number of views and cart adds for each product category?
select ph.product_category,
count(case when i.event_name = 'Page View' then e.visit_id end) as no_of_views,
count(case when i.event_name = 'Add to Cart' then e.visit_id end) as cart_adds
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type
where ph.product_category is not null 
group by 1 

--What are the top 3 products by purchases?
with visit_with_purchase as (
select visit_id 
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where i.event_name = 'Purchase'
)


select ph.page_name, count(visit_id) as count_
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type 
where e.visit_id in (select * from visit_with_purchase)
and i.event_name = 'Add to Cart' or i.event_name = 'Purchase'
and ph.page_name != 'Confirmation'
group by 1 
order by 2 desc
limit 3
