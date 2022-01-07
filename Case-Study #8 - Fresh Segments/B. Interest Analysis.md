# Interest Analysis 

- Which interests have been present in all month_year dates in our dataset?
- Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
- Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.
- After removing these interests - how many unique interests are there for each month?

- Which interests have been present in all month_year dates in our dataset? 

```sql
with cte as (
select *, row_number() over (partition by interest_id) as rn 
from fresh_segments.interest_metrics
) 
select interest_id, ma.interest_name
from cte me
join fresh_segments.interest_map ma on cast(me.interest_id as integer) = ma.id 
where me.rn = (select count(distinct month_year) 
from fresh_segments.interest_metrics)
```

