# Before and After Anaysis 
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

Using this analysis approach - answer the following questions:

- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
- What about the entire 12 weeks before and after?
- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

```sql
with cte as ( 
select  sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '4 week'
and date < date'2020-06-15' + interval '4 week'
) 
select *, (before_sales - after_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from cte
```

