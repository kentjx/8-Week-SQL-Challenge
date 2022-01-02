# Bonus Question

Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

- region
- platform
- age_band
- demographic
- customer_type

```sql
with temp_year as ( 
select sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week' 
) 

, year as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_year
) 

, temp_region as ( 
select region, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

, region as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_region
) 

, temp_platform as ( 
select platform, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

, platform as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_platform
) 

,  temp_age_band as ( 
select age_band, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 
, age_band as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_age_band
) 

,  temp_demographic as ( 
select demographic, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

, demographic as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_demographic
) 

,  temp_customer_type as ( 
select customer_type, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

, customer_type as (
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_customer_type
) 

select 'year' as business_metrics, round(avg(pct_change),2) as avg
from year 
union 
select 'region' as business_metrics, round(avg(pct_change),2) as avg
from region 
union 
select 'platform' as business_metrics, round(avg(pct_change),2) as avg 
from platform 
union 
select 'age_band' as business_metrics, round(avg(pct_change),2) as avg 
from age_band
union 
select 'demographic' as business_metrics, round(avg(pct_change),2) as avg 
from demographic
union 
select 'customer_type' as business_metrics, round(avg(pct_change),2) as avg 
from customer_type
``` 
![image](https://user-images.githubusercontent.com/87967846/147879731-84740820-200c-4683-bb03-8f82779301ba.png)


- The worst affected on average is year, followed by demographic at 2.01%. 

 We can also look into each business metrics individually. 

```sql
with temp_region as ( 
select region, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_region
```
 
 ![image](https://user-images.githubusercontent.com/87967846/147879748-1853f7ce-5a7d-47f7-93b3-886e04acc938.png)

- Asia is affected the most, at 3.26% 

```sql
with temp_platform as ( 
select platform, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_platform
```
![image](https://user-images.githubusercontent.com/87967846/147879794-3bbb167f-529b-4e12-84f1-ae38c3c71d53.png)


- Retail is affected the most, at 2.43%, but shopify gained a total of 7.18%! 

```sql
with temp_age_band as ( 
select age_band, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_age_band
```
![image](https://user-images.githubusercontent.com/87967846/147879823-016a8135-0268-4574-9fa3-e6fe842de721.png)


- All age group decreased, after the change in packaging, with the most affected being the unknowns, and middle-aged. 

```sql
with temp_demographic as ( 
select demographic, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_demographic
```
![image](https://user-images.githubusercontent.com/87967846/147879834-3f9a9bac-b6d9-435f-9c9e-1a8667b836e7.png)


- All demographics decreased, after the change in packaging, with the most affected being the unknowns, followed by families. 

```sql
with temp_customer_type as ( 
select customer_type, sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
group by 1 
) 

select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp_customer_type
```
![image](https://user-images.githubusercontent.com/87967846/147879849-68ce7299-45a5-4cd5-b844-b6d533ca9837.png)


- The worst affected is Guest, at 3%. 
