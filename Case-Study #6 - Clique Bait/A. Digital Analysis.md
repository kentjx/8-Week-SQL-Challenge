 Part A. Digital Analysis 

--How many users are there?
```sql
select count (distinct user_id) as count_of_users
from clique_bait.users 
```
![image](https://user-images.githubusercontent.com/87967846/147761106-14e38d7b-fa74-44e7-97d9-cbacbe42b393.png)


```sql
with temp as (
select cast(count (distinct user_id) as numeric) as count_of_users, cast(count (cookie_id) as numeric) as count_cookie
from clique_bait.users
) 
select round(count_cookie / count_of_users, 2) as average_cookie_each_user
from temp 
```
![image](https://user-images.githubusercontent.com/87967846/147761132-968dbe36-55ee-41ee-b466-67520438e723.png)



--What is the unique number of visits by all users per month?
```sql
Select extract(month from event_time), count(distinct visit_id) as unique_visits
from clique_bait.events e
inner join clique_bait.users u on e.cookie_id = u.cookie_id
group by 1
```
![image](https://user-images.githubusercontent.com/87967846/147761425-1df1a6cc-504f-440b-9c59-613a4502075b.png)



-- What is the number of events for each event type?
```sql
select e.event_type, i.event_name, count(e.event_type) as Count_of_event
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type
group by 1, 2 
```
![image](https://user-images.githubusercontent.com/87967846/147761474-3790b183-42fc-4194-966f-9ad7b7bf78eb.png)


--What is the percentage of visits which have a purchase event? 
```sql
select round(cast(count(case when i.event_name = 'Purchase' then e.visit_id end)as numeric) / cast(count( distinct e.visit_id) as numeric) * 100, 2) as pct_visits_purchase
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type
```
![image](https://user-images.githubusercontent.com/87967846/147761526-bc1c4f9a-65af-4565-bfe5-3c184b0e4b18.png)


-- What is the percentage of visits which view the checkout page but do not have a purchase event?
```sql
select  round(1 - cast(count(case when i.event_name = 'Purchase' then e.visit_id end) as numeric) / cast(count(case when i.event_name = 'Page View' AND e.page_id = 12 then e.visit_id end)as numeric),3) * 100 as see_but_no_buy
from clique_bait.events e 
join clique_bait.event_identifier i on e.event_type = i.event_type
```
![image](https://user-images.githubusercontent.com/87967846/147761671-dd3980ae-0b07-4efd-b505-64d1836d9748.png)


-- the logic here is such that, we first find out how many visit_ids when event_name = 'purchases' (A)
-- we also find out how many visit_ids when event_name = page_view AND page_id = 12 (B) ie. user who viewed the check out page. 
-- we then do a 1 - (A/B) = to find out those that did not purchase / B 

-- What are the top 3 pages by number of views?
```sql
Select ph.page_name, count(e.visit_id) as count_
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
group by 1 
order by 2 desc
limit 3 
```
![image](https://user-images.githubusercontent.com/87967846/147761733-086504b4-72fa-41c2-b1f9-8f602fd4a376.png)


-- What is the number of views and cart adds for each product category?
```sql
select ph.product_category,
count(case when i.event_name = 'Page View' then e.visit_id end) as no_of_views,
count(case when i.event_name = 'Add to Cart' then e.visit_id end) as cart_adds
from clique_bait.events e
join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
join clique_bait.event_identifier i on e.event_type = i.event_type
where ph.product_category is not null 
group by 1 
```
![image](https://user-images.githubusercontent.com/87967846/147761751-484edeac-b76f-46a6-9d0e-65d63abcbe37.png)

--What are the top 3 products by purchases?
```sql
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
```
![image](https://user-images.githubusercontent.com/87967846/147761782-91999851-b1ab-4081-a980-c879176151db.png)
