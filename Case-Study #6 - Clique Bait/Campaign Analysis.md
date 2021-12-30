--------------------------------------Campaigns Analysis--------------------------------------
 
Generate a table that has 1 single row for every unique visit_id record and has the following columns:

- user_id
- visit_id
- visit_start_time: the earliest event_time for each visit
- page_views: count of page views for each visit
- cart_adds: count of product cart add events for each visit
- purchase: 1/0 flag if a purchase event exists for each visit
- campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
- impression: count of ad impressions for each visit
- click: count of ad clicks for each visit
- (Optional column) cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

```sql
with CTE as (
select u.user_id, e.visit_id, min(e.event_time) as visit_start_time, date_part('year', min(e.event_time)) as year,
date_part('month', min(e.event_time)) as month,
date_part('day', min(e.event_time)) as day, 
date_part('hour', min(e.event_time)) as hour,
count(case when e.event_type = 1 then visit_id else null end) as page_views,
count(case when e.event_type = 2 then visit_id else null end) as cart_adds,
count(case when e.event_type = 3 then visit_id else null end) as purchase, 
ci.campaign_name, 
count(case when e.event_type = 4 then visit_id else null end) as impression, 
count(case when e.event_type = 5 then visit_id else null end) as click, 
string_agg(case when ph.product_id is not null and e.event_type = 2 then ph.page_name else null end, ', ' order by e.sequence_number) as cart_products
from clique_bait.events e
join clique_bait.users u on e.cookie_id = u.cookie_id 
left join clique_bait.campaign_identifier ci on e.event_time between ci.start_date and ci.end_date
left join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
group by u.user_id, e.visit_id, ci.campaign_name
), 

cte2 as (
select *, case when cart_products is not null and cart_products = 'Salmon' then 1 else 0 end as Salmon, 
case when cart_products is not null and cart_products like '%Kingfish%' then 1 else 0 end as Kingfish,
case when cart_products is not null and cart_products like '%Tuna%' then 1 else 0 end as Tuna, 
case when cart_products is not null and cart_products like '%Russian Caviar%' then 1 else 0 end as Russian_Caviar, 
case when cart_products is not null and cart_products like '%Black Truffle%' then 1 else 0 end as Black_Truffle, 
case when cart_products is not null and cart_products like '%Abalone%' then 1 else 0 end as Abalone,
case when cart_products is not null and cart_products like '%Lobster%' then 1 else 0 end as Lobster,
case when cart_products is not null and cart_products like '%Crab%' then 1 else 0 end as Crab,
case when cart_products is not null and cart_products like '%Oyster%' then 1 else 0 end as Oyster
from CTE
)
```
Use the subsequent dataset to generate at least 5 insights for the Clique Bait team - bonus: prepare a single A4 infographic that the team can use for their management reporting sessions, be sure to emphasise the most important points from your findings.

Some ideas you might want to investigate further include:

- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event
- Does clicking on an impression lead to higher purchase rates?
- What is the uplift in purchase rate when comparing users who click on a campaign impression versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?
- What metrics can you use to quantify the success or failure of each campaign compared to each other?
 
-- Identifying users who have received impressions during each campaign period and comparing each metric with other users who did not have an impression event

```sql
select campaign_name, 
impression, 
count(distinct user_id) as unique_users, 
count(visit_id) as count_visits, 
round(avg(page_views),2) as page_views_avg, 
round(avg(cart_adds),2) as cart_adds_avg, 
round(avg(purchase),2) as avg_purchase, 
round(avg(click),2) as click_avg
from cte 
where campaign_name is not null
group by 1,2 
```
![image](https://user-images.githubusercontent.com/87967846/147763407-44cbfae3-ab2d-436b-8a0c-93994c62a05a.png)

```sql
select campaign_name, click, ROUND(AVG(purchase),2) AS avg_purchase
from cte 
where campaign_name is not null 
group by 1, 2
order by 1 
```

![image](https://user-images.githubusercontent.com/87967846/147763484-54ac7855-860b-4a37-96da-88d60647eaad.png)

```sql
select c.campaign_name, 
case when c.campaign_name is not null then extract('day' from ci.end_date) - extract('day' from ci.start_date) else extract(day from max(c.visit_start_time) - min(c.visit_start_time)) end as compaign_days, 
sum(page_views) as total_page_views, sum(cart_adds) as total_cart_adds, sum(purchase) as total_purchases,
case when c.campaign_name is not null then round(sum(page_views) / (extract('day' from ci.end_date) - extract('day' from ci.start_date)),2) else round(sum(page_views)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) end as avg_page_views,
case when c.campaign_name is not null then round(sum(cart_adds) / (extract('day' from ci.end_date) - extract('day' from ci.start_date)),2) else round(sum(cart_adds)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) end as avg_cart_adds,
case when c.campaign_name is not null then round(sum(purchase) / (extract('day' from ci.end_date) - extract('day' from ci.start_date)),2) else round(sum(purchase)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) end as avg_purchases
from cte2 c
left join clique_bait.campaign_identifier ci on c.campaign_name = ci.campaign_name
group by c.campaign_name, ci.start_date, ci.end_date 
order by 1 
```

![image](https://user-images.githubusercontent.com/87967846/147763555-8abc0672-3a02-494e-b723-64fa2154e8e3.png)

- There is a few assumptions in this analysis. In the query output, campaigns days are the total number of days that the campaign has ran. When during days when there is no compaigns, the 
difference between the max and min of visit_start_time is assumed. Follow which, this last 3 columns will provide a more accurate post-campaign analysis. Firstly, it is evident that having 
campaigns will definitely boost the page_views, cart adds and purchases. The most effective campaign is Half Off - Treat your Shellf(ish). By taking their business metrics and divide by their respective 
campaign days, we will have a deeper insights on the campaign results. For example, it is a more useful comparison to know that during lull periods (where there is no campaigns), the average metrics is much 
lower compared to days with campaigns. 

- Analyze the specific impact of the campaign (Spike Analysis)
- Half off - treat your shellf(ish) - shellfish 
- 25% off Living the lux Life - Luxury products 
- BOGOF - Fishing for Compliments */

- To understand the demand for each of the category products, we need to break down the data by category type, and know what is the lull period (without any campaigns) business metrics. 

```sql
with CTE as (
select u.user_id, e.visit_id, min(e.event_time) as visit_start_time, date_part('year', min(e.event_time)) as year,
date_part('month', min(e.event_time)) as month,
date_part('day', min(e.event_time)) as day, 
date_part('hour', min(e.event_time)) as hour,
count(case when e.event_type = 1 then visit_id else null end) as page_views,
count(case when e.event_type = 2 then visit_id else null end) as cart_adds,
count(case when e.event_type = 3 then visit_id else null end) as purchase, 
ci.campaign_name, 
count(case when e.event_type = 4 then visit_id else null end) as impression, 
count(case when e.event_type = 5 then visit_id else null end) as click, 
string_agg(case when ph.product_id is not null and e.event_type = 2 then ph.page_name else null end, ', ' order by e.sequence_number) as cart_products
from clique_bait.events e
join clique_bait.users u on e.cookie_id = u.cookie_id 
left join clique_bait.campaign_identifier ci on e.event_time between ci.start_date and ci.end_date
left join clique_bait.page_hierarchy ph on e.page_id = ph.page_id
group by u.user_id, e.visit_id, ci.campaign_name
), 

cte2 as (
select *, case when cart_products is not null and cart_products = 'Salmon' then 1 else 0 end as Salmon, 
case when cart_products is not null and cart_products like '%Kingfish%' then 1 else 0 end as Kingfish,
case when cart_products is not null and cart_products like '%Tuna%' then 1 else 0 end as Tuna, 
case when cart_products is not null and cart_products like '%Russian Caviar%' then 1 else 0 end as Russian_Caviar, 
case when cart_products is not null and cart_products like '%Black Truffle%' then 1 else 0 end as Black_Truffle, 
case when cart_products is not null and cart_products like '%Abalone%' then 1 else 0 end as Abalone,
case when cart_products is not null and cart_products like '%Lobster%' then 1 else 0 end as Lobster,
case when cart_products is not null and cart_products like '%Crab%' then 1 else 0 end as Crab,
case when cart_products is not null and cart_products like '%Oyster%' then 1 else 0 end as Oyster
from CTE
)
, lull as (
select c.campaign_name, 
extract(day from max(c.visit_start_time) - min(c.visit_start_time)) as campaign_days,
round(sum(salmon)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2)  as salmon, 
round(sum(kingfish)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as kingfish, 
round(sum(tuna)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as tuna, 
round(sum(russian_caviar)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as russian_caviar, 
round(sum(black_truffle)/ (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as black_truffle, 
round(sum(abalone) / (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as abalone, 
round(sum(lobster) / (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as lobster, 
round(sum(crab) / (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as crab, 
round(sum(oyster) / (extract(day from max(c.visit_start_time) - min(c.visit_start_time))),2) as oyster from 
cte2 c
left join clique_bait.campaign_identifier ci on c.campaign_name = ci.campaign_name
where c.campaign_name is null 
and c.purchase = 1 
group by 1 
) 

, 

shellfish as (
select c.campaign_name, 
extract(day from (ci.end_date) - (ci.start_date)) as campaign_days,
round(sum(salmon)/ (extract(day from (ci.end_date) - (ci.start_date))),2)  as salmon, 
round(sum(kingfish)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as kingfish, 
round(sum(tuna)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as tuna, 
round(sum(russian_caviar)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as russian_caviar, 
round(sum(black_truffle)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as black_truffle, 
round(sum(abalone) / (extract(day from (ci.end_date) - (ci.start_date))),2) as abalone, 
round(sum(lobster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as lobster, 
round(sum(crab) / (extract(day from (ci.end_date) - (ci.start_date))),2) as crab, 
round(sum(oyster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as oyster from 
cte2 c
left join clique_bait.campaign_identifier ci on c.campaign_name = ci.campaign_name
where c.campaign_name = 'Half Off - Treat Your Shellf(ish)'
and c.purchase = 1 
group by c.campaign_name, ci.end_date, ci.start_date
)


,

fish as (
select c.campaign_name, 
extract(day from (ci.end_date) - (ci.start_date)) as campaign_days,
round(sum(salmon)/ (extract(day from (ci.end_date) - (ci.start_date))),2)  as salmon, 
round(sum(kingfish)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as kingfish, 
round(sum(tuna)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as tuna, 
round(sum(russian_caviar)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as russian_caviar, 
round(sum(black_truffle)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as black_truffle, 
round(sum(abalone) / (extract(day from (ci.end_date) - (ci.start_date))),2) as abalone, 
round(sum(lobster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as lobster, 
round(sum(crab) / (extract(day from (ci.end_date) - (ci.start_date))),2) as crab, 
round(sum(oyster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as oyster from 
cte2 c
left join clique_bait.campaign_identifier ci on c.campaign_name = ci.campaign_name
where c.campaign_name = 'BOGOF - Fishing For Compliments'
and c.purchase = 1 
group by c.campaign_name, ci.end_date, ci.start_date
)

,

luxury as ( 
select c.campaign_name, 
extract(day from (ci.end_date) - (ci.start_date)) as campaign_days,
round(sum(salmon)/ (extract(day from (ci.end_date) - (ci.start_date))),2)  as salmon, 
round(sum(kingfish)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as kingfish, 
round(sum(tuna)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as tuna, 
round(sum(russian_caviar)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as russian_caviar, 
round(sum(black_truffle)/ (extract(day from (ci.end_date) - (ci.start_date))),2) as black_truffle, 
round(sum(abalone) / (extract(day from (ci.end_date) - (ci.start_date))),2) as abalone, 
round(sum(lobster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as lobster, 
round(sum(crab) / (extract(day from (ci.end_date) - (ci.start_date))),2) as crab, 
round(sum(oyster) / (extract(day from (ci.end_date) - (ci.start_date))),2) as oyster from 
cte2 c
left join clique_bait.campaign_identifier ci on c.campaign_name = ci.campaign_name
where c.campaign_name = '25% Off - Living The Lux Life'
and c.purchase = 1 
group by c.campaign_name, ci.end_date, ci.start_date
)

select * from shellfish 
UNION ALL 
select * from fish
UNION ALL 
select * from luxury 
UNION ALL 
select * from lull 
```

![image](https://user-images.githubusercontent.com/87967846/147763865-2991ad2c-dd4d-4e5d-b8b9-16da2b59942e.png)

