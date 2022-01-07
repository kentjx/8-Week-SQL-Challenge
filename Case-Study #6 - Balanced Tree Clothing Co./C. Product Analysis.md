# Product Analysis
- What are the top 3 products by total revenue before discount?
- What is the total quantity, revenue and discount for each segment?
- What is the top selling product for each segment?
- What is the total quantity, revenue and discount for each category?
- What is the top selling product for each category?
- What is the percentage split of revenue by product for each segment?
- What is the percentage split of revenue by segment for each category?
- What is the percentage split of total revenue by category?
- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction? 

- What are the top 3 products by total revenue before discount?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
)

select prod_id as top3 
from rev 
group by prod_id 
order by sum(rev) desc 
limit 3 
```



- What is the total quantity, revenue and discount for each segment?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
)

, product_group as (
select prod_id, sum(qty) as product_count, sum(rev) as total_rev, sum(discount_value) as total_discount 
from rev 
group by prod_id
)

, segment_group as (
select pd.segment_name, sum(pg.product_count) as product_count, 
sum(pg.total_rev) as total_rev, sum(pg.total_discount) as total_discount
from product_group pg 
join balanced_tree.product_details pd 
on pg.prod_id = pd.product_id 
group by 1
order by 1 
)

select * from segment_group
```
- What is the top selling product for each segment?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
)

, product_group as (
select prod_id, sum(qty) as product_count, sum(rev) as total_rev, sum(discount_value) as total_discount 
from rev 
group by prod_id
)

, segment_group as (
select pd.segment_name, pd.product_name, sum(pg.product_count) as product_count, 
sum(pg.total_rev) as total_rev, sum(pg.total_discount) as total_discount
from product_group pg 
join balanced_tree.product_details pd 
on pg.prod_id = pd.product_id 
group by 1, 2
order by 1 
)

, segment_top as (
select *, rank() over (partition by segment_name order by product_count desc) as rank  
from segment_group
) 

select * from 
segment_top 
where rank = 1 
```
- What is the percentage split of revenue by product for each segment?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
)

, product_group as (
select prod_id, sum(qty) as product_count, sum(rev) as total_rev, sum(discount_value) as total_discount 
from rev 
group by prod_id
)

, segment_group as (
select pd.segment_name, 
sum(pg.total_rev) as total_rev
from product_group pg 
join balanced_tree.product_details pd 
on pg.prod_id = pd.product_id 
group by 1
)

, segment_group_1 as (
select * , sum (total_rev) over () as sum_rev
from segment_group 
) 
select *, round(total_rev / sum_rev,2) as pct 
from segment_group_1

```
- What is the percentage split of revenue by segment for each category?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
)

, product_group as (
select prod_id, sum(qty) as product_count, sum(rev) as total_rev, sum(discount_value) as total_discount 
from rev 
group by prod_id
)

, category_group as (
select pd.category_name, 
sum(pg.total_rev) as total_rev
from product_group pg 
join balanced_tree.product_details pd 
on pg.prod_id = pd.product_id 
group by 1
)

, category_group_1 as (
select * , sum (total_rev) over () as sum_rev
from category_group 
) 
select *, round(total_rev / sum_rev,2) as pct 
from category_group_1
```
- What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

```sql
with txn_count as (
select count(distinct txn_id) as count_of_txn 
from balanced_tree.sales --2500 
) 

select prod_id, count(prod_id) as count_prod_id, round(cast(count(prod_id) as numeric) / (select * from txn_count),2) as pct
from balanced_tree.sales
group by 1 
```
- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?

WIP 
