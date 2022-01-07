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

