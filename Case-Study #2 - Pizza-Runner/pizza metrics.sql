CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" TIMESTAMP
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  SELECT * 
  FROM runners 
  
  SELECT * 
  FROM customer_orders 
  
  SELECT * 
  FROM runner_orders 
  
  SELECT * 
  FROM pizza_names 
  
  SELECT * 
  FROM pizza_recipes 

  SELECT * 
  FROM pizza_toppings 
  
  ------------ Data Cleaning ------------ 
 -- 1st Table to be cleaned -> customer_orders table. In the customer_orders Table, the exclusion and extras column, 
 -- there are missing/blank spaces and null values. 

 -- 2nd Table to be cleaned -> runner_orders. In the runner_orders Table, the pickup_time contained 'null' values. 
 -- distance contained units which ideally should be interger, duration should also remove units, lastly, cancellation contain 'null' values and [null] values. 
 
DROP TABLE IF EXISTS customer_orders2;
CREATE TEMP TABLE customer_orders2 AS 
(
    SELECT order_id, customer_id, pizza_id,
        CASE WHEN exclusions = '' THEN NULL 
		WHEN exclusions = 'null' THEN NULL ELSE exclusions END as exclusions,
        CASE WHEN extras = '' THEN NULL WHEN extras = 'null' THEN NULL ELSE extras END as extras,
        order_time
    FROM customer_orders
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
    FROM runner_orders
)
SELECT order_id, runner_id, pickup_time,
    CAST(regexp_replace(distance, '[a-z]+', '') AS FLOAT) AS distance,
    CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
    cancellation
FROM CTE;

SELECT * FROM 
runner_orders2
 ----------------PIZZA METRICS---------------- 
 -- 1. How many pizzas were ordered?
 
 SELECT COUNT(order_id) AS Total_pizza_ordered 
 FROM customer_orders2
 
 --Note: Distinct should not be applied here since the question asked for how many pizzas were ordered. 
 --If we treat each order were able to order more than 1 pizza, (eg, order_id 3 has 2 (pizza_id: 1 & pizza_id: 2) pizzas ordered )
 
 -- 2. How many unique customer orders were made?
 SELECT customer_id, COUNT(order_id) AS unique_customer_order
 FROM customer_orders2
 GROUP BY customer_id
 
 -- 3. How many successful orders were delivered by each runner?
 SELECT runner_id, COUNT(order_id) AS successful_orders
 FROM runner_orders2
 WHERE cancellation IS NULL 
 GROUP BY runner_id
 
 --4. How many of each type of pizza was delivered?
 SELECT pizza_id, COUNT(c.order_id) AS pizza_delivered
 FROM customer_orders2 c
 LEFT JOIN runner_orders2 r
 ON c.order_id = r.order_id
 WHERE cancellation IS NULL
 GROUP BY pizza_id
 
 --5. How many Vegetarian and Meatlovers were ordered by each customer?
 SELECT c.customer_id, COUNT(CASE WHEN p.pizza_name = 'Meatlovers' THEN p.pizza_name ELSE NULL END) AS Meatlovers_count,
 COUNT(CASE WHEN p.pizza_name = 'Vegetarian' THEN p.pizza_name ELSE NULL END) AS vegetarian_count
 FROM customer_orders2 c 
 JOIN pizza_names p 
 ON c.pizza_id = p.pizza_id
 GROUP BY 1
 ORDER BY 1

-- 6. What was the maximum number of pizzas delivered in a single order?
---- Method 1 ---- 
-- Using window functions and CTE/subquery returns the max number of pizzas delivered  
WITH CTE AS 
(
SELECT c.order_id, r.pickup_time, row_number() over (partition by c.order_id) AS Count_delivered  
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r
ON c.order_id = r.order_id 
) 
SELECT MAX(count_delivered) AS highest_delivered
FROM CTE 
---- Method 2---- 
-- Using Subquery and and LIMIT 1 to get the max pizzas delivered together with the order_id 
SELECT * 
FROM 
(
SELECT c.order_id, r.pickup_time, COUNT(c.order_id) AS Count_delivered  
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r
ON c.order_id = r.order_id 
GROUP BY 1,2 
ORDER BY 3 desc
) as alias2 
LIMIT 1

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT c.customer_id, COUNT(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN c.order_id ELSE NULL END) AS Change, 
COUNT(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN c.order_id ELSE NULL END) AS No_change
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r 
on c.order_id = r.order_id
WHERE cancellation IS NULL 
GROUP BY 1

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(CASE WHEN c.exclusions IS NOT NULL AND c.extras IS NOT NULL THEN c.order_id ELSE NULL END) AS both_change
FROM customer_orders2 c 
LEFT JOIN runner_orders2 r 
on c.order_id = r.order_id 
WHERE cancellation IS NULL 

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT DATE_PART('hour', order_time) AS HOUR, COUNT(order_id) AS Volume_of_order,ROUND(count(order_id) * 100.0/ sum(count(order_id)) over (), 2) as volume_percent
FROM customer_orders2 
GROUP BY 1
ORDER BY 1

-- 10. What was the volume of orders for each day of the week? 

SELECT DATE_TRUNC('day', order_time) AS TIME, COUNT(order_id) AS volume, ROUND(count(order_id) * 100.0/ sum(count(order_id)) over (), 2) as volume_percent
FROM customer_orders2 
GROUP BY 1
ORDER BY 1 



