# Transaction Analysis

- How many unique transactions were there?
- What is the average unique products purchased in each transaction?
- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
- What is the average discount value per transaction?
- What is the percentage split of all transactions for members vs non-members?
- What is the average revenue for member transactions and non-member transactions?

```sql
with rev as (
select *, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value,
qty * price as rev
from balanced_tree.sales
), 

cumsum as (
select *, sum(rev) over (partition by txn_id) as cumsum 
from rev
order by cumsum 
),  

pct as (
select *, percent_rank() over (order by cumsum) as pct
from cumsum
order by pct 
) 

, temp as (
select count(distinct txn_id) as count_txn, sum(qty)/count(distinct txn_id) as avg_unique_product_count_per_txn, 
percentile_cont(0.25) within group (order by pct.cumsum) as q1_pct,
percentile_cont(0.50) within group (order by pct.cumsum) as q2_pct,
percentile_cont(0.75) within group (order by pct.cumsum) as q3_pct,
round(sum(discount_value) / count(distinct txn_id),2) as avg_discount_value_per_txn,
count(distinct case when member = 'true' then txn_id end) as member_txn_count,
count(distinct case when member = 'false' then txn_id end) as nonmember_txn_count,
round(avg(case when member = 'true' then rev end),2) as member_avg_rev,
round(avg(case when member = 'false' then rev end),2) as nonmember_avg_rev
from pct 
) 
select * from temp
``` 
