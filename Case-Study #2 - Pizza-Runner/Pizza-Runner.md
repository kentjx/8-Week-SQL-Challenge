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

----------------PIZZA METRICS---------------- 
 1. How many pizzas were ordered?
 ```sql 
 SELECT COUNT(order_id) AS Total_pizza_ordered 
 FROM customer_orders2
 
 - Note: Distinct should not be applied here since the question asked for how many pizzas were ordered. 
 - If we treat each order were able to order more than 1 pizza, (eg, order_id 3 has 2 (pizza_id: 1 & pizza_id: 2) pizzas ordered )
 
 
 
 2. How many unique customer orders were made?
 ```sql
 SELECT customer_id, COUNT(order_id) AS unique_customer_order
 FROM customer_orders2
 GROUP BY customer_id
 ```
 
 
 3. How many successful orders were delivered by each runner?
 ```sql
 SELECT runner_id, COUNT(order_id) AS successful_orders
 FROM runner_orders2
 WHERE cancellation IS NULL 
 GROUP BY runner_id
 ```
 
 4. How many of each type of pizza was delivered?
 ```sql
 SELECT pizza_id, COUNT(c.order_id) AS pizza_delivered
 FROM customer_orders2 c
 LEFT JOIN runner_orders2 r
 ON c.order_id = r.order_id
 WHERE cancellation IS NULL
 GROUP BY pizza_id
 ```
 5. How many Vegetarian and Meatlovers were ordered by each customer?
 ```sql
 SELECT c.customer_id, COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN p.pizza_name ELSE NULL END) AS Meatlovers_count,
 COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN p.pizza_name ELSE NULL END) AS vegetarian_count
 FROM customer_orders2 c 
 JOIN pizza_names p 
 ON c.pizza_id = p.pizza_id
 GROUP BY 1
 ORDER BY 1
```

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
