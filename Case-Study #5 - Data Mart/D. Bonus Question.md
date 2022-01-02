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


- The worst affected on average is year, followed by demographic at 2.01%. 

/* we can also look into each business metrics individually.*/ 
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
 -- Asia is affected the most, at 3.26% 
 
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
-- Retail is affected the most, at 2.43%, but shopify gained a total of 7.18%! 

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

-- all age group decreased, after the change in packaging, with the most affected being the unknowns, and middle-aged. 

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

-- all demographics decreased, after the change in packaging, with the most affected being the unknowns, followed by families. 

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

-- the worst affected is Guest, at 3%. 
