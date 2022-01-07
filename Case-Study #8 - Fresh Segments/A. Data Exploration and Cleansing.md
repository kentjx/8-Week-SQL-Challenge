# Data Exploration and Cleansing
- Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
- What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
- What do you think we should do with these null values in the fresh_segments.interest_metrics
- How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
- Summarise the id values in the fresh_segments.interest_map by its total record count in this table
- What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.
- Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why? */ 

- Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month

```sql
ALTER TABLE fresh_segments.interest_metrics ALTER COLUMN month_year TYPE DATE 
using to_date(month_year, 'MM-YYYY');
```

- What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?

```sql
select month_year, count(*) as count_
from fresh_segments.interest_metrics
group by 1
order by month_year is null desc, month_year
```
![image](https://user-images.githubusercontent.com/87967846/148581124-e0b3876c-9c38-4798-9322-2e5729b96d71.png)

-  What do you think we should do with these null values in the fresh_segments.interest_metrics

```sql
select * from 
fresh_segments.interest_metrics
WHERE _month is null 
or _year is null 
or month_year is null 
or interest_id is null 
or composition is null 
or index_value is null 
or ranking is null 
or percentile_ranking is null 
```

- The null values comes from the columns _month, _year, month_year and interest_id. Wihtout the interest_id, there is no meaning to the dataset hence I will drop the null values. 
However, lets first take a look the total number of nulls.

```sql
select round(cast(count(case when interest_id is null then percentile_ranking end) as numeric) / cast(count(percentile_ranking) as numeric),3) * 100 as null_pct 
from fresh_segments.interest_metrics 
```

- Approximately 8.4% is nulls. 
```sql
DELETE FROM fresh_segments.interest_metrics
WHERE interest_id IS NULL;
```
- How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?

```sql
select me.interest_id, ma.interest_name
from fresh_segments.interest_metrics me
left join fresh_segments.interest_map ma on cast(me.interest_id as integer) = ma.id
where ma.interest_name is null
```
![image](https://user-images.githubusercontent.com/87967846/148581516-5bdc821a-331d-47c6-9029-d8d4966f3f6d.png)

-- 0 

```sql
select me.interest_id, ma.interest_name
from fresh_segments.interest_metrics me
right join fresh_segments.interest_map ma on cast(me.interest_id as integer) = ma.id
where cast(me.interest_id as integer) is null
```
![image](https://user-images.githubusercontent.com/87967846/148581572-68efbb1d-1c06-4a70-b73e-4939cf511327.png)

- 7 interest_id is exist in fresh_segments.interest_map but not interest_metrics table. 

- Summarise the id values in the fresh_segments.interest_map by its total record count in this table

- I am not exactly sure what this question is looking for. But the solution seems to be 

```sql
select count(id) as count_id 
from fresh_segments.interest_map
```
![image](https://user-images.githubusercontent.com/87967846/148581724-f128064c-c522-4953-8faa-0c3eb2262e04.png)

- What sort of table join should we perform for our analysis and why? 
- Check your logic by checking the rows where 'interest_id = 21246' in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

```sql
select * 
from fresh_segments.interest_map ma 
join fresh_segments.interest_metrics me on ma.id = cast(me.interest_id as integer)
where cast(me.interest_id as integer) = 21246
```
![image](https://user-images.githubusercontent.com/87967846/148581876-aaa700be-4f4d-46dd-b97e-1718ed3b9cb6.png)

-- inner join 

- Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

```sql
with cte as (select *
from fresh_segments.interest_map ma 
join fresh_segments.interest_metrics me on ma.id = cast(me.interest_id as integer)
where me.month_year < ma.created_at 
) 
-- 188 records. This is because month_year was only set to the first day of the month. 
select count(*) 
from cte
where extract(month from created_at) != extract(month from month_year)
```
![image](https://user-images.githubusercontent.com/87967846/148582195-08fca1f9-cd01-4222-a83a-c2b2f8ff802c.png)

- 0 records, this shows that the created_at was all created within the same month as month_year. Hence the records are valid. 

