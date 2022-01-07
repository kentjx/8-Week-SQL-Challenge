The following questions can be considered key business questions and metrics that the Balanced Tree team requires for their monthly reports.

- Each question can be answered using a single query - but as you are writing the SQL to solve each individual problem, keep in mind how you would generate all of these metrics in a single SQL script which the Balanced Tree team can run each month.

- High Level Sales Analysis
- What was the total quantity sold for all products?
- What is the total generated revenue for all products before discounts?
- What was the total discount amount for all products? */ 

```sql
with discount_value as (
select *, qty * price as rev, round((cast(price as numeric) * cast(discount as numeric)/100) * qty,2) as discount_value
from balanced_tree.sales
)
select count(prod_id) as prod_count, sum(rev) as revenue_b4_disc, sum(discount_value) as total_discount_amount 
from discount_value
```
![image](https://user-images.githubusercontent.com/87967846/148576490-c4faa6af-897a-4fd5-9980-f0ec9df6976c.png)

