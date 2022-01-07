B. Customer Transactions
What is the unique count and total amount for each transaction type?
What is the average total historical deposit counts and amounts for all customers?
For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
What is the closing balance for each customer at the end of the month?
What is the percentage of customers who increase their closing balance by more than 5%?

- What is the unique count and total amount for each transaction type?

```sql 
select txn_type, count(txn_type) as count_distinct, sum(txn_amount) as total_amount
from data_bank.customer_transactions
group by 1 
```
![image](https://user-images.githubusercontent.com/87967846/148574145-2f009ed5-9b1e-4169-8b80-b0c8c7e6f91c.png)


- What is the average total historical deposit counts and amounts for all customers?
```sql 
select round(avg(case when txn_type = 'deposit' then txn_amount end),2) as average_amount, 
count(case when txn_type = 'deposit' then txn_amount end) / count(distinct customer_id) as average_count_of_deposit
from data_bank.customer_transactions
```
![image](https://user-images.githubusercontent.com/87967846/148574214-86869da0-4952-42d4-919b-91f2f0c1d461.png)


- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

```sql 
with temp as (
select extract(month from txn_date) as month, *, row_number() over(partition by customer_id, txn_type, extract(month from txn_date)) as rn
from data_bank.customer_transactions
order by customer_id 
) 

, cte as (
select customer_id, month, SUM(CASE WHEN txn_type = 'purchase' or txn_type = 'withdrawal' THEN 1 ELSE 0 END) as cond2 
from temp
group by 1, 2
)

, more_than_1_deposit as (
select month, customer_id 
from temp 
where txn_type = 'deposit'
AND rn > 1 
) 

select a.month, count(distinct a.customer_id) as count
from cte a 
join more_than_1_deposit b on a.customer_id = b.customer_id
where cond2 >= 1
group by 1 
order by 1
```

![image](https://user-images.githubusercontent.com/87967846/148574376-a3a2113a-9df7-45e4-9eda-e7859deed63c.png)

- First we create the 2 temp tables that accomplish the criteria, 1. made more than 1 deposit and 2. transaction type = purchase or withdrawal in that particular month. 
- In this analysis, we assume that the 1st condition is a customer who had made more than 1 deposit in any of the months, it is much less stringent as compared to a customer that makes more than 1 deposit in each month. 

- Below we will show the query for the more stringent condition --> made more than 1 deposit for each month. 


```sql 
with cte as (
select customer_id, 
extract(month from txn_date) as month, 
SUM(case when txn_type = 'deposit' then 1 else 0 end) as cond1, 
SUM(CASE WHEN txn_type = 'purchase' or txn_type = 'withdrawal' THEN 1 ELSE 0 END) as cond2
from data_bank.customer_transactions
group by 1, 2
)
SELECT
month,
COUNT(DISTINCT customer_id) AS customer_count
FROM cte
WHERE cond1 >= 2 
AND cond2 >= 1 
GROUP BY 1
ORDER BY 1;
```
![image](https://user-images.githubusercontent.com/87967846/148574750-79bd71a5-b4b7-4bbf-8238-a02ea5de758c.png)

- What is the closing balance for each customer at the end of the month?

```sql 
-- CTE 1 - To identify transaction amount as an inflow (+) or outflow (-) and create closing month
with monthly_transaction as (
select customer_id,
date_trunc('month', txn_date) + INTERVAL '1 month - 1 Day' as closing_month, 
txn_date, txn_type, txn_amount, 
sum(case when txn_type = 'deposit' then txn_amount else -(txn_amount) end) as monthly_transactions
from data_bank.customer_transactions
group by customer_id, txn_date, txn_type, txn_amount
order by 1, 2
)

-- CTE 2 - To generate txn_date as a series of last day of month for each customer
, last_day as (
select distinct customer_id, (date'2020-01-31' + GENERATE_SERIES(0,3) * INTERVAL '1 MONTH') as ending_month 
from data_bank.customer_transactions
order by 1 
)

-- CTE 3 - Create closing balance for each month using Window function SUM() to add changes during the month
-- CTE 4 - Use Window function ROW_NUMBER() to rank transactions within each month 
, solution_t1 as (
select ld.customer_id, ld.ending_month, coalesce(mt.monthly_transactions, 0) as monthly_transaction,
sum(monthly_transactions) over (partition by ld.customer_id order by ld.ending_month rows between unbounded preceding and current row) as monthly_balance, 
row_number() over (partition by ld.customer_id, ld.ending_month order by ld.ending_month) as rn
from last_day ld
left join monthly_transaction mt on ld.customer_id = mt.customer_id and ld.ending_month = mt.closing_month
)

, 
-- CTE 5 - Use Window function LEAD() to query value in next row and retrieve NULL for last row
solution_t2 as (
select *,  lead(rn) over (partition by customer_id, ending_month order by ending_month) as lead_no
from solution_t1
)

select customer_id, ending_month, monthly_transaction, monthly_balance
from solution_t2
where lead_no IS NULL 

```
![image](https://user-images.githubusercontent.com/87967846/148574921-3a018832-6389-4328-9456-dc5affa16ce2.png)


- What is the percentage of customers who increase their closing balance by more than 5%?



```sql 
with monthly_transaction as (
select customer_id,
date_trunc('month', txn_date) + INTERVAL '1 month - 1 Day' as closing_month, 
txn_date, txn_type, txn_amount, 
sum(case when txn_type = 'deposit' then txn_amount else -(txn_amount) end) as monthly_transactions
from data_bank.customer_transactions
group by customer_id, txn_date, txn_type, txn_amount
order by 1, 2
)

-- CTE 2 - To generate txn_date as a series of last day of month for each customer
, last_day as (
select distinct customer_id, (date'2020-01-31' + GENERATE_SERIES(0,3) * INTERVAL '1 MONTH') as ending_month 
from data_bank.customer_transactions
order by 1 
)

-- CTE 3 - Create closing balance for each month using Window function SUM() to add changes during the month
-- CTE 4 - Use Window function ROW_NUMBER() to rank transactions within each month 
, solution_t1 as (
select ld.customer_id, ld.ending_month, coalesce(mt.monthly_transactions, 0) as monthly_transaction,
sum(monthly_transactions) over (partition by ld.customer_id order by ld.ending_month rows between unbounded preceding and current row) as monthly_balance, 
row_number() over (partition by ld.customer_id, ld.ending_month order by ld.ending_month) as rn
from last_day ld
left join monthly_transaction mt on ld.customer_id = mt.customer_id and ld.ending_month = mt.closing_month
)

, 
-- CTE 5 - Use Window function LEAD() to query value in next row and retrieve NULL for last row
solution_t2 as (
select *,  lead(rn) over (partition by customer_id, ending_month order by ending_month) as lead_no
from solution_t1
)

, solution_t3 as (select customer_id, ending_month, monthly_transaction, monthly_balance, row_number() over (partition by customer_id order by ending_month) as rn 
from solution_t2
where lead_no IS NULL
) 

, solution_t4 as (
select *, lead(monthly_balance) over (partition by customer_id order by ending_month) as lead from 
solution_t3
where rn = 1 or rn = 4 
) 


select sum(case when (lead - monthly_balance)/ monthly_balance > 0.05 then 1 else 0 end) as count_that_increased, count(distinct customer_id) as count_total_customer,
round(cast(sum(case when (lead - monthly_balance)/ monthly_balance > 0.05 then 1 else 0 end) as numeric)/ (cast(count(distinct customer_id) as numeric)) , 2) as pct 
from solution_t4
```
![image](https://user-images.githubusercontent.com/87967846/148575114-e485919b-0baf-49ee-b6bc-f234c75923e3.png)

-- now we attempt to find out the business metrics, by the months

```sql 
with monthly_transaction as (
select customer_id,
date_trunc('month', txn_date) + INTERVAL '1 month - 1 Day' as closing_month, 
txn_date, txn_type, txn_amount, 
SUM(CASE WHEN txn_type = 'withdrawal' OR txn_type = 'purchase' THEN (-txn_amount) ELSE txn_amount END) as monthly_transactions
from data_bank.customer_transactions
group by customer_id, txn_date, txn_type, txn_amount
order by 1, 2
)



-- CTE 2 - To generate txn_date as a series of last day of month for each customer
, last_day as (
select distinct customer_id, (date'2020-01-31' + GENERATE_SERIES(0,3) * INTERVAL '1 MONTH') as ending_month 
from data_bank.customer_transactions
order by 1 
)

-- CTE 3 - Create closing balance for each month using Window function SUM() to add changes during the month
-- CTE 4 - Use Window function ROW_NUMBER() to rank transactions within each month 
, solution_t1 as (
select ld.customer_id, ld.ending_month, coalesce(mt.monthly_transactions, 0) as monthly_transaction,
sum(monthly_transactions) over (partition by ld.customer_id order by ld.ending_month rows between unbounded preceding and current row) as monthly_balance, 
row_number() over (partition by ld.customer_id, ld.ending_month order by ld.ending_month) as rn
from last_day ld
left join monthly_transaction mt on ld.customer_id = mt.customer_id and ld.ending_month = mt.closing_month
)

, 
-- CTE 5 - Use Window function LEAD() to query value in next row and retrieve NULL for last row
solution_t2 as (
select *,  lead(rn) over (partition by customer_id, ending_month order by ending_month) as lead_no
from solution_t1
)

, solution_t3 as (select customer_id, ending_month, monthly_transaction, monthly_balance, row_number() over (partition by customer_id order by ending_month) as rn 
from solution_t2
where lead_no IS NULL
) 

, solution_t4 as (
select *, lead(monthly_balance) over (partition by customer_id order by ending_month) as lead from 
solution_t3
) 

select ending_month, sum(case when (lead - monthly_balance)/ monthly_balance > 0.05 then 1 else 0 end) as count_that_increased, count(distinct customer_id) as count_total_customer,
round(cast(sum(case when (lead - monthly_balance)/ monthly_balance > 0.05 then 1 else 0 end) as numeric)/ (cast(count(distinct customer_id) as numeric)) , 2) as pct 
from solution_t4
where monthly_balance != 0 
group by 1 
```

![image](https://user-images.githubusercontent.com/87967846/148575270-5ebfd9c4-87a8-4c17-9afe-d3bf74a108cb.png)

phew. Kudos to @katiehuangx for the solutions for the last 2 questions. I took reference from her solution. It is indeed a challenging one! 
