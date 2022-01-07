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

![image](https://user-images.githubusercontent.com/87967846/148582632-8b4916f1-ece9-4ff1-a314-2aac7b92e75b.png)

- Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months, which total_months value passes the 90% cumulative percentage value?

```sql
with cte as (
select *, row_number() over (partition by interest_id) as rn
from fresh_segments.interest_metrics
)

,cte2 as (
select rn, count(rn) as count
from cte 
group by rn
order by rn desc
)


, 
cte3 as (
select *, round(cast(count as numeric)/ (select count from cte2 where rn = 1),2) as cumsum
from cte2 
) 
select * from cte3
```
![image](https://user-images.githubusercontent.com/87967846/148582740-05c65c03-363c-4a81-8b9b-38368637c5d9.png)

- From here we can tell that rn 14 has a total of 480 interest_ids 
- The cutoff for the 90% is rn = 6 

- If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?

```sql
with cte as (
select *, row_number() over (partition by interest_id) as rn
from fresh_segments.interest_metrics
)

, id_to_keep as (
select distinct interest_id
from cte where rn > 6  
) 

, id_not_to_keep as (
select distinct interest_id 
from cte 
where interest_id not in (select * from id_to_keep)
)


select count(*) - (select count(*) from cte where interest_id not in (select * from id_not_to_keep)) as rows_to_delete
from fresh_segments.interest_metrics
```

![image](https://user-images.githubusercontent.com/87967846/148582877-c3a98c1c-d614-44f3-887b-ffddd5e0d90d.png)

- Does this decision make sense to remove these data points from a business perspective? 
- Use an example where there are all 14 months present to a removed interest example for your arguments. Think about what it means to have less months present from a segment perspective.

The idea of removing these data points is to remove the interest_ids that are not performing as well. The business metrics used to measure if the business metrics of interest_id is the occurence of the interest_ids over the months. Hence the bottom 10% of the interest_id that occured less frequently is being removed. 
However, we have to understand that as time passes, it might be possible that a particular interest_id interaction might wane down. 
For example, during campaign seasons, the interest_id related to the campaigns might perform exceptionally well, but as time passes the interaction wanes down as the campaign ends. This does not necessary mean that the particular interest_id is a poor performing interest_id, since it does performed well during the initial phase of the campaign. 
More importantly, metrics like composition and index_value needs to be considered before removing the interest_ids. 


- After removing these interests - how many unique interests are there for each month?
```sql
with cte as (
select *, row_number() over (partition by interest_id) as rn
from fresh_segments.interest_metrics
)

, id_to_keep as (
select distinct interest_id
from cte where rn > 6  
) 

, id_not_to_keep as (
select distinct interest_id 
from cte 
where interest_id not in (select * from id_to_keep)
)

select month_year, count (distinct interest_id) as unique_count
from fresh_segments.interest_metrics
where interest_id not in (select * from id_not_to_keep) 
group by 1 
```
![image](https://user-images.githubusercontent.com/87967846/148583139-b8c93c37-c975-4bb3-bc76-8dea981861c5.png)

