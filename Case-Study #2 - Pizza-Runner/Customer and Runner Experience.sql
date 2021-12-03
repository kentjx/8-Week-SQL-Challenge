----- B. Runner and Customer Experience ----- 

-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT date_trunc('week', registration_date), count(runner_id)
FROM runners
GROUP BY 1

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT ro.runner_id , AVG(ro.pickup_time - c.order_time) AS avg_difference  
FROM customer_orders2 c
JOIN runner_orders2 ro
ON c.order_id = ro.order_id
WHERE ro.cancellation IS NULL 
GROUP BY 1

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
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

--------OR----------
SELECT corr(no_pizza_ordered, time_to_pickup)
FROM prepare_time
-- There seem to be some positive correlations, but sample size is too small to determine any correlations. 

-- 4. What was the average distance travelled for each customer?

SELECT c.customer_id, ROUND(CAST(AVG(r.distance) as numeric), 2) AS avg_dist
FROM customer_orders2 c
JOIN runner_orders2 r
ON c.order_id = r.order_id
WHERE r.cancellation IS NULL 
GROUP BY 1
ORDER BY 1 

--5. What was the difference between the longest and shortest delivery times for all orders?
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

--6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
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

-- Interestingly, there is a -0.34 correlation with number of pizza ordered and the runner speed. 

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

-- From here, we can tell runner 2 has the fastest average speed at 62.90km/hr and runner 3 has the slowest average speed at 40km/hr 
-- No doubt, the sample size is really small here to make any substantial conclusions. 

-- What is the successful delivery percentage for each runner? 
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