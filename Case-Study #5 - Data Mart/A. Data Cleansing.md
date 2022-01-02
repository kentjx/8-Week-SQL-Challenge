In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

- Convert the week_date to a DATE format.
- Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc.
- Add a month_number with the calendar month for each week_date value as the 3rd column.
- Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values.
- Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value.
- Add a new demographic column using the following mapping for the first letter in the segment values:

![image](https://user-images.githubusercontent.com/87967846/147878071-a34172cc-ef6e-43c5-9e46-11db7117f51a.png)

- Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
- Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

# Data Cleansing Steps
```sql
DROP TABLE IF EXISTS data_mart.weekly_sales2;
CREATE TABLE data_mart.weekly_sales2 AS 
SELECT *, TO_DATE(week_date, 'DD/MM/YY') as date, extract(month from TO_DATE(week_date, 'DD/MM/YY')) as month_number, 
extract(week from TO_DATE(week_date, 'DD/MM/YY')) as week_number, 
extract(day from TO_DATE(week_date, 'DD/MM/YY')) as day_number,
extract(year from TO_DATE(week_date, 'DD/MM/YY')) as year_number,
case when segment LIKE '%1' then 'Young Adults' when segment LIKE '%2' then 'Middle Aged' when segment LIKE '%3' OR segment LIKE '%4' then 'Retirees' else 'unknown' end as age_band,
case when segment LIKE 'C%' then 'Couples' when segment LIKE 'F%' then 'Families' else 'unknown' end as demographic,
round(cast(sales as numeric)/ cast(transactions as numeric), 2) as avg_transaction,
case when TO_DATE(week_date, 'DD/MM/YY') >= date'2020-06-15' then 'after' else 'before' end as before_or_after
FROM 
data_mart.weekly_sales 

select * 
from data_mart.weekly_sales2
```
![image](https://user-images.githubusercontent.com/87967846/147878144-10fb381b-fd9a-454e-9aa8-df487d1ffb83.png)


