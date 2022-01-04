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
![image](https://user-images.githubusercontent.com/87967846/147879559-7de60c56-55b0-4a78-9870-d85dc0d77d3c.png)

- Sales dropped after new packaging 

- What about the entire 12 weeks before and after?

```sql
with temp as ( 
select  sum(case when before_or_after = 'before' then sales end) as before_sales, 
sum(case when before_or_after = 'after' then sales end) as after_sales
from data_mart.weekly_sales2
where date >= date'2020-06-15' - interval '12 week'
and date < date'2020-06-15' + interval '12 week'
) 
select *, (before_sales - after_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp
```
![image](https://user-images.githubusercontent.com/87967846/147879589-f58fc534-93bd-495f-82fd-e7b8522187ec.png)


- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019? 

```sql
select week_number, count(week_number) as count_of_week_number
from data_mart.weekly_sales2 
where date = date'2020-06-15' 
or date = date'2019-06-15' 
or date = date'2018-06-15' 
group by 1 
-- we know that month 6 and day 15 is all week 25. 
```
![image](https://user-images.githubusercontent.com/87967846/147879622-2c0336fa-e70f-4748-9282-766d81575bb3.png)

```sql
with temp2 as ( 
select year_number, sum(case when week_number < 25 then sales end) as before_sales, 
sum(case when week_number >= 25 then sales end) as after_sales
from data_mart.weekly_sales2
group by 1 
order by 1
) 
select *, (after_sales - before_sales) as difference, 
round((cast(after_sales as numeric) - cast(before_sales as numeric))/before_sales * 100,2) as pct_change
from temp2
```

![image](https://user-images.githubusercontent.com/87967846/147879627-ea539307-66e6-492f-9cb9-a112b767482e.png)

- In 2018, there was a 1.63% of increase in terms of before and after week 25 sales, in 2019, there was a 0.3% decrease in the same time period, one year later. 
Hence, there could be other factor that actually affects the fall in the sales after the implementation of different packaging in 2020, not all can be 
attributed to the change in packaging! 
