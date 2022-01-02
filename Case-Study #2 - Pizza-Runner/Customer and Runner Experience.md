# Runner and Customer Experience 

1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
SELECT date_trunc('week', registration_date), count(runner_id)
FROM pizza_runner.runners
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866475-b1a0d43f-157b-48b9-937a-16c8e0099d8b.png)


-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
SELECT ro.runner_id , AVG(ro.pickup_time - c.order_time) AS avg_difference  
FROM customer_orders2 c
JOIN runner_orders2 ro
ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL 
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866485-4ded5e00-a61a-477c-8828-48106b27c5ea.png)


3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
WITH prepare_time AS
(
SELECT c.order_id, COUNT(c.order_id) AS no_pizza_ordered, c.order_time, r.pickup_time, EXTRACT(minute from DATE_TRUNC('minute', r.pickup_time::timestamp) - DATE_TRUNC('minute', c.order_time::timestamp)) AS time_to_pickup
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT no_pizza_ordered, ROUND(AVG(time_to_pickup),2) AS avg_time_to_prepare
FROM prepare_time
GROUP BY no_pizza_ordered;
```
![image](https://user-images.githubusercontent.com/87967846/147866488-e749bf87-99ba-4c43-ab8f-30cc0649e4e8.png)


--------OR----------
```sql
WITH prepare_time AS
(
SELECT c.order_id, COUNT(c.order_id) AS no_pizza_ordered, c.order_time, r.pickup_time, EXTRACT(minute from DATE_TRUNC('minute', r.pickup_time::timestamp) - DATE_TRUNC('minute', c.order_time::timestamp)) AS time_to_pickup
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY c.order_id, c.order_time, r.pickup_time
)
SELECT corr(no_pizza_ordered, time_to_pickup)
FROM prepare_time
```
![image](https://user-images.githubusercontent.com/87967846/147866504-34350943-616f-49b2-beaa-96186fec99c8.png)


- There seem to be some positive correlations, but sample size is too small to determine any correlations. 

4. What was the average distance travelled for each customer?
```sql
SELECT c.customer_id, ROUND(CAST(AVG(r.distance) as numeric), 2) AS avg_dist
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY 1
ORDER BY 1 
```
![image](https://user-images.githubusercontent.com/87967846/147866509-7633fe80-f622-4751-af7e-eb44b7d003a4.png)

```sql
5. What was the difference between the longest and shortest delivery times for all orders?
WITH CTE AS
(
SELECT * 
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
)
SELECT MAX(duration) - MIN (duration) AS difference
FROM CTE
```
![image](https://user-images.githubusercontent.com/87967846/147866510-cf61b9cf-0d5f-4e13-98e3-f6763a1fa68a.png)


6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
```sql
WITH CTE AS 
(
SELECT c.order_id, r.runner_id, r.distance, r.duration, count(c.order_id) AS number_of_pizza, ROUND(CAST((r.distance / r.duration) * 60 as numeric),2) AS speed_kmph 
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY c.order_id, r.runner_id, r.distance, r.duration
) 
SELECT corr(number_of_pizza, speed_kmph)
FROM CTE
```
![image](https://user-images.githubusercontent.com/87967846/147866514-835977e6-eeac-4b94-9a4d-d491e74e7f6e.png)


-- Interestingly, there is a -0.34 correlation with number of pizza ordered and the runner speed. 
```sql
WITH CTE AS 
(
SELECT c.order_id, r.runner_id, r.distance, r.duration, count(c.order_id) AS number_of_pizza, ROUND(CAST((r.distance / r.duration) * 60 as numeric),2) AS speed_kmph 
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY c.order_id, r.runner_id, r.distance, r.duration
) 
SELECT runner_id, ROUND(AVG(speed_kmph), 2) AS avg_speed
FROM CTE
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866521-1339582b-a69e-47ce-b783-aafa2e9aea4d.png)


- From here, we can tell runner 2 has the fastest average speed at 62.90km/hr and runner 3 has the slowest average speed at 40km/hr 
- No doubt, the sample size is really small here to make any substantial conclusions. 

7. What is the successful delivery percentage for each runner? 
```sql
WITH CTE AS 
(
SELECT runner_id, COUNT(DISTINCT CASE WHEN r.cancellation IS NULL THEN c.order_id END) AS Successful, 
COUNT(DISTINCT CASE WHEN r.cancellation IS NOT NULL THEN c.order_id END) AS Unsuccessful
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
GROUP BY 1
ORDER BY 1
) 
SELECT *, ROUND(successful / SUM(successful + unsuccessful) * 100, 2) AS Percentage
FROM CTE
GROUP BY 1, 2, 3
ORDER BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866527-fbd1ba7d-7414-41b8-9e65-15242316fa36.png)


# INGREDIENT OPTIMIZATION

### DATA CLEANING FOR PIZZA_RECIPES TABLE

```sql
DROP TABLE IF EXISTS pizza_recipes2;
CREATE TEMP TABLE pizza_recipes2 AS 
(
SELECT pizza_id, CAST(unnest(string_to_array(toppings, ', ')) as numeric) AS toppings
	FROM pizza_runner.pizza_recipes
) 
```
1. What are the standard ingredients for each pizza? 

```sql
SELECT  n.pizza_id, n.pizza_name,  t.topping_id, t.topping_name
FROM pizza_runner.pizza_toppings t
JOIN pizza_recipes2 r 
ON t.topping_id = r.toppings
JOIN pizza_runner.pizza_names n 
ON n.pizza_id = r.pizza_id
```
![image](https://user-images.githubusercontent.com/87967846/147866547-a7106955-460b-48ef-9c17-ded062a65ac3.png)



2. What was the most commonly added extra?

```sql
DROP TABLE IF EXISTS customer_orders3;
CREATE TEMP TABLE customer_orders3 AS 
(
SELECT c1.order_id, c1.customer_id, c1.pizza_id, 
	CAST(unnest(string_to_array(c1.exclusions, ', ')) as INTEGER) AS exclusions,
	CAST(unnest(string_to_array(c1.extras, ', ')) as INTEGER) AS extras, 
	order_time
	FROM customer_orders2 c1
	ORDER BY order_id
) 

SELECT c.extras, t.topping_name, row_number() over (partition by t.topping_name) as RN
FROM customer_orders3 c
JOIN pizza_runner.pizza_toppings t
ON c.extras = t.topping_id
ORDER BY RN DESC
LIMIT 1
```
![image](https://user-images.githubusercontent.com/87967846/147866581-19be8717-e052-45c5-84a9-b2879dd8e55e.png)


3. What was the most commonly added exclusions?
```sql
SELECT c.exclusions, t.topping_name, row_number() over (partition by t.topping_name) as RN
FROM customer_orders3 c
JOIN pizza_toppings t
ON c.exclusions = t.topping_id
ORDER BY RN DESC
LIMIT 1
```
![image](https://user-images.githubusercontent.com/87967846/147866595-c716dbd8-f880-493a-b5fa-3478a5d7e05d.png)


4. Generate an order item for each record in the customers_orders table in the format of one of the following:

WIP

