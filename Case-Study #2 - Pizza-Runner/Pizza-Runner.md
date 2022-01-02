
# Data Cleaning 
 - 1st Table to be cleaned -> customer_orders table. In the customer_orders Table, the exclusion and extras column, 
 - there are missing/blank spaces and null values. 

 - 2nd Table to be cleaned -> runner_orders. In the runner_orders Table, the pickup_time contained 'null' values. 
 - distance contained units which ideally should be interger, duration should also remove units, lastly, cancellation contain 'null' values and [null] values. 
 

```sql 
DROP TABLE IF EXISTS customer_orders2;
CREATE TEMP TABLE customer_orders2 AS 
(
    SELECT order_id, customer_id, pizza_id,
        CASE WHEN exclusions = '' THEN NULL 
		WHEN exclusions = 'null' THEN NULL ELSE exclusions END as exclusions,
        CASE WHEN extras = '' THEN NULL WHEN extras = 'null' THEN NULL ELSE extras END as extras,
        order_time
    FROM pizza_runner.customer_orders
);

SELECT * 
FROM customer_orders2

DROP TABLE IF EXISTS runner_orders2;
CREATE TEMP TABLE runner_orders2 AS WITH CTE AS 
(
    SELECT order_id, runner_id,
        CAST(CASE WHEN pickup_time = 'null' THEN NULL ELSE pickup_time END AS timestamp) AS pickup_time,
        CASE WHEN distance = '' THEN NULL WHEN distance = 'null' THEN NULL ELSE distance END as distance,
        CASE WHEN duration = '' THEN NULL WHEN duration = 'null' THEN NULL ELSE duration END as duration,
        CASE WHEN cancellation = '' THEN NULL WHEN cancellation = 'null' THEN NULL ELSE cancellation END as cancellation
    FROM pizza_runner.runner_orders
)
SELECT order_id, runner_id, pickup_time,
    CAST(regexp_replace(distance, '[a-z]+', '') AS FLOAT) AS distance,
    CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
    cancellation
FROM CTE;

SELECT * FROM 
runner_orders2
```

# Pizza Metrics
 1. How many pizzas were ordered?
 ```sql 
 SELECT COUNT(order_id) AS Total_pizza_ordered 
 FROM customer_orders2
 
 - Note: Distinct should not be applied here since the question asked for how many pizzas were ordered. 
 - If we treat each order were able to order more than 1 pizza, (eg, order_id 3 has 2 (pizza_id: 1 & pizza_id: 2) pizzas ordered )
 
 ![image](https://user-images.githubusercontent.com/87967846/147866303-e4d249e8-5932-4373-967d-ada36148acc0.png)

 
 2. How many unique customer orders were made?
 ```sql
 SELECT customer_id, COUNT(order_id) AS unique_customer_order
 FROM customer_orders2
 GROUP BY customer_id
 ```
 ![image](https://user-images.githubusercontent.com/87967846/147866306-0ed23ad3-445c-4014-8041-2cb2fcbc9853.png)

 
 3. How many successful orders were delivered by each runner?
 ```sql
 SELECT runner_id, COUNT(order_id) AS successful_orders
 FROM runner_orders2
 WHERE cancellation IS NULL 
 GROUP BY runner_id
 ```
 ![image](https://user-images.githubusercontent.com/87967846/147866311-496f8689-7a86-4169-b9e5-b48e97168a99.png)

 
 
 4. How many of each type of pizza was delivered?
 ```sql
 SELECT pizza_id, COUNT(c.order_id) AS pizza_delivered
 FROM customer_orders2 c
 LEFT JOIN runner_orders2 r
 ON c.order_id = r.order_id
 WHERE cancellation IS NULL
 GROUP BY pizza_id
 ```
 ![image](https://user-images.githubusercontent.com/87967846/147866316-cb041aca-f461-42fd-a7bf-311bd290fcf8.png)

 
 5. How many Vegetarian and Meatlovers were ordered by each customer?
 ```sql
 SELECT c.customer_id, COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN p.pizza_name ELSE NULL END) AS Meatlovers_count,
 COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN p.pizza_name ELSE NULL END) AS vegetarian_count
 FROM customer_orders2 c 
 JOIN pizza_runner.pizza_names p 
 ON c.pizza_id = p.pizza_id
 GROUP BY 1
 ORDER BY 1
```

![image](https://user-images.githubusercontent.com/87967846/147866340-6afca710-6cc9-4e42-b38d-085ad2492c29.png)


6. What was the maximum number of pizzas delivered in a single order?

- Using window functions and CTE/subquery returns the max number of pizzas delivered  
```sql
WITH CTE AS 
(
SELECT c.order_id, r.pickup_time, row_number() over (partition by c.order_id) AS Count_delivered  
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r
ON c.order_id = r.order_id 
) 
SELECT MAX(count_delivered) AS highest_delivered
FROM CTE 
```
![image](https://user-images.githubusercontent.com/87967846/147866348-bdf49676-f417-4461-b962-ebd38a916df5.png)

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT c.customer_id, COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN c.order_id ELSE NULL END) AS Change, 
COUNT(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN c.order_id ELSE NULL END) AS No_change
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r 
on c.order_id = r.order_id
WHERE cancellation IS NULL 
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866373-8b910ffd-e806-4a27-a305-5fb154340353.png)


8. How many pizzas were delivered that had both exclusions and extras?
```sql
SELECT COUNT(CASE WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN c.order_id ELSE NULL END) AS both_change
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r 
on c.order_id = r.order_id 
WHERE cancellation IS NULL 
```

![image](https://user-images.githubusercontent.com/87967846/147866381-1e1ba4bc-2c48-41be-87dd-5bed88433ff1.png)


9. What was the total volume of pizzas ordered for each hour of the day?
```sql
SELECT DATE_PART('hour', order_time) AS HOUR, COUNT(order_id) AS Volume_of_order,ROUND(count(order_id) * 100.0/ sum(count(order_id)) over (), 2) as volume_percent
FROM customer_orders2 
GROUP BY 1
ORDER BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866390-95fdd9ee-6033-4df3-82c4-0989688a680e.png)


10. What was the volume of orders for each day of the week? 

```sql
SELECT DATE_TRUNC('day', order_time) AS TIME, COUNT(order_id) AS volume, ROUND(count(order_id) * 100.0/ sum(count(order_id)) over (), 2) as volume_percent
FROM customer_orders2 
GROUP BY 1
ORDER BY 1 
```
![image](https://user-images.githubusercontent.com/87967846/147866402-a89abd83-87c9-401e-a241-e30ea23ffc4e.png)

