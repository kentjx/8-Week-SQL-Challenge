# Data Exploration

- What day of the week is used for each week_date value?
- What range of week numbers are missing from the dataset?
- How many total transactions were there for each year in the dataset?
- What is the total sales for each region for each month?
- What is the total count of transactions for each platform
- What is the percentage of sales for Retail vs Shopify for each month?
- What is the percentage of sales by demographic for each year in the dataset?
- Which age_band and demographic values contribute the most to Retail sales?
- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

1. What day of the week is used for each week_date value?

```sql
select to_char(date, 'Day'), count(to_char(date, 'Day')) as count_
from data_mart.weekly_sales2
group by 1 
``` 

![image](https://user-images.githubusercontent.com/87967846/147879146-95e19299-a305-408a-a5a5-5c5d635945c8.png)

2. What range of week numbers are missing from the dataset?

```sql
select week_number, count(week_number) as count_of_week_number
from data_mart.weekly_sales2
group by 1 
order by 1 
```
![image](https://user-images.githubusercontent.com/87967846/147879199-c12e34a8-a79b-4919-8983-a3acd5d7911c.png)

-- week 1 to week 12 and week 37 to week 52 is missing.

4. How many total transactions were there for each year in the dataset?

```sql
select year_number, count(transactions) as count_transactions 
from data_mart.weekly_sales2
group by 1 
order by 1 
```
![image](https://user-images.githubusercontent.com/87967846/147879245-ae50d1db-e4b3-4cdb-90a4-07115b1b9e14.png)


6. What is the total sales for each region for each month?

```sql
select region, sum(sales) as total_sales
from data_mart.weekly_sales2
group by 1 
```

![image](https://user-images.githubusercontent.com/87967846/147879249-122f4bd8-cf13-4495-9a13-19323e44ecc6.png)

7. What is the total count of transactions for each platform

```sql
select platform, count(transactions) as count_transactions
from data_mart.weekly_sales2 
group by 1 
```
![image](https://user-images.githubusercontent.com/87967846/147879260-ab0afaf6-b9de-4e10-b733-b7a7ba3c0ea2.png)


8. What is the percentage of sales for Retail vs Shopify for each month?

```sql
with temp as (
select year_number, month_number, cast(sum(case when platform = 'Retail' then sales end) as numeric) as Retail_sales, 
cast(sum(case when platform = 'Shopify' then sales end) as numeric) as Shopify_sales, cast(sum(sales) as numeric) as total_sales 
from data_mart.weekly_sales2
group by 1, 2
order by 1, 2 
)  

select *, round(retail_sales / total_sales ,2) as pct_retail, 
round(shopify_sales / total_sales, 2) as pct_shopify 
from temp 
```
![image](https://user-images.githubusercontent.com/87967846/147879289-c18b119c-6d2a-4cec-880d-ac6f2ef3e9ae.png)


9. What is the percentage of sales by demographic for each year in the dataset?

```sql
with cte as (
select year_number, demographic, sum(sales) as total_sales
from data_mart.weekly_sales2 
group by 1, 2
order by 1 
) , 

cte2 as (
select *, sum(total_sales) over (partition by year_number) as yearly_sales
from cte 
)
select *, round(total_sales/ yearly_sales, 2) as pct_demographic 
from cte2 
```

![image](https://user-images.githubusercontent.com/87967846/147879308-f4ecdaf0-526a-4e8d-855d-3a63b42a5e45.png)


10. Which age_band and demographic values contribute the most to Retail sales?

```sql
select demographic, sum(sales) as total_sales 
from data_mart.weekly_sales2
where platform = 'Retail'
and demographic != 'unknown'
group by 1 
order by 2 desc 
-- Families 

![image](https://user-images.githubusercontent.com/87967846/147879478-3d7d3765-d6e8-40c0-8fdb-cdd2bdc610d8.png)



select age_band, sum(sales) as total_sales 
from data_mart.weekly_sales2
where platform = 'Retail'
and demographic != 'unknown'
group by 1 
order by 2 desc 
-- retires 
```

![image](https://user-images.githubusercontent.com/87967846/147879389-a4908d37-0c75-419f-9c7e-efbfcff8be7e.png)


11. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

select year_number, platform, round(avg(avg_transaction),2) as avg_transaction, round( SUM(sales) / SUM(transactions) ,2) as average_transactions
from data_mart.weekly_sales2
group by 1, 2
order by 1, 2 

![image](https://user-images.githubusercontent.com/87967846/147879407-b8eb135a-5701-4d14-86a0-a0f01c0d6b16.png)

- Column average_transactions here will be more accurate as it sums the entire sales and divide by the sum of total transactions to get the average_transactions. 
- Column avg_transaction is the average of each rows sales/transaction (which is supposingly an average already). Hence the average_transaction is more accurate. 
