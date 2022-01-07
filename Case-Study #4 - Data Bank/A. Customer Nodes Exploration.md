A. Customer Nodes Exploration
- How many unique nodes are there on the Data Bank system?
- What is the number of nodes per region?
- How many customers are allocated to each region?
- How many days on average are customers reallocated to a different node?
- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

- How many unique nodes are there on the Data Bank system?

```sql 
select count(distinct node_id) as count_distinct
from data_bank.customer_nodes
```

![image](https://user-images.githubusercontent.com/87967846/148572995-568b84db-f264-464f-a627-9b802147a1f2.png)

- What is the number of nodes per region?

```sql 
select region_id, count(node_id) as node_count
from data_bank.customer_nodes
group by 1 
order by 1
```
![image](https://user-images.githubusercontent.com/87967846/148573187-1d68abd9-7820-4d49-a5f7-9163b82afa6b.png)

- How many customers are allocated to each region?

```sql 
select region_id, count(distinct customer_id) as customer_count
from data_bank.customer_nodes
group by 1 
order by 1 

```

![image](https://user-images.githubusercontent.com/87967846/148573274-f1beda2f-7d74-4edf-bf51-a8a72fa45610.png)

- How many days on average are customers reallocated to a different node?


```sql 
with date_diff as (
select *, (end_date - start_date) as date_diff
from data_bank.customer_nodes
where end_date != date'9999-12-31'
) 
select round(avg(date_diff),2) as avg
from date_diff
```

![image](https://user-images.githubusercontent.com/87967846/148573336-51f689ae-ef22-41b2-a784-2823ba09fb26.png)

--What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

```sql 
with date_diff as (
select *, (end_date - start_date) as date_diff
from data_bank.customer_nodes
where end_date != date'9999-12-31'
) 

, percentile as (
select *, percent_rank() over (partition by region_id order by date_diff) * 100 as pct_rank
from date_diff
) 

, rown as (
select region_id, date_diff, pct_rank, row_number() over (partition by region_id) as rn 
from percentile
where pct_rank >= 50 -- the 95th percentile is between 15 to 16 days.
) 
select * 
from rown
where rn = 1 
```
![image](https://user-images.githubusercontent.com/87967846/148573557-487474b9-7f83-498d-99c1-d8d97cded355.png)


```sql 
with date_diff as (
select *, (end_date - start_date) as date_diff
from data_bank.customer_nodes
where end_date != date'9999-12-31'
) 

, percentile as (
select *, percent_rank() over (partition by region_id order by date_diff) * 100 as pct_rank
from date_diff
) 

, rown as (
select region_id, date_diff, pct_rank, row_number() over (partition by region_id) as rn 
from percentile
where pct_rank >= 80 -- the 95th percentile is between 24 to 25 days.
) 
select * 
from rown
where rn = 1
```
![image](https://user-images.githubusercontent.com/87967846/148573780-f7596cd3-e902-4436-a6bd-f22ae13c566f.png)


```sql 
with date_diff as (
select *, (end_date - start_date) as date_diff
from data_bank.customer_nodes
where end_date != date'9999-12-31'
) 

, percentile as (
select *, percent_rank() over (partition by region_id order by date_diff) * 100 as pct_rank
from date_diff
) 

, rown as (
select region_id, date_diff, pct_rank, row_number() over (partition by region_id) as rn 
from percentile
where pct_rank >= 95 -- the 95th percentile is between 28 to 29 days.
) 
select * 
from rown
where rn = 1
```
![image](https://user-images.githubusercontent.com/87967846/148573828-db08e410-9027-42e6-b1fb-1e44b9d57863.png)
