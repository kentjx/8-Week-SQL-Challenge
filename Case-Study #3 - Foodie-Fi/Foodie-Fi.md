# Foodie-Fi 

- Based off the 8 sample customers provided in the sample from the subscriptions table, 
- write a brief description about each customer’s onboarding journey.
  
  ```sql
  SELECT * 
  FROM subscriptions s 
  JOIN plans p 
  ON s.plan_id = p.plan_id
  WHERE customer_id IN ('1', '2', '11', '13', '15', '16', '18', '19')
  ```
 ## Data Analysis Questions
  
 1. How many customers has Foodie-Fi ever had?
 
  ```sql
 SELECT COUNT(distinct customer_id) As Total_Customers
 FROM subscriptions s
 ```
 ![image](https://user-images.githubusercontent.com/87967846/147866939-36b66e29-e7de-4ce5-a6d5-53b5e66f6100.png)

 
 2. What is the monthly distribution of trial plan start_date values for our dataset? Use the start of the month as the group by value 
  ```sql
 SELECT date_part('month', start_date) ,to_char(start_date, 'month') As month, 
 count(CASE WHEN plan_id = 0 THEN plan_id ELSE NULL END) AS count_of_trial
 FROM subscriptions
 GROUP BY 1, 2
 ORDER BY 1
 ```
 ![image](https://user-images.githubusercontent.com/87967846/147866943-8d24d178-2dc8-4e86-852b-903e5459d626.png)


3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name 
 ```sql
SELECT p.plan_id, p.plan_name, COUNT(CASE WHEN date_part('year', s.start_date) = 2020 THEN s.customer_id ELSE NULL END) AS Event_2020, 
COUNT(CASE WHEN date_part('year', s.start_date) = 2021 THEN s.customer_id ELSE NULL END) AS event_2021 	
FROM subscriptions s 
JOIN plans p 
ON s.plan_id = p.plan_id
GROUP BY 1, 2
ORDER BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147866958-815ff41a-14a3-473b-8faf-fca9cbd4a10c.png)


4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
 ```sql
WITH CTE AS 
(
SELECT COUNT(distinct s.customer_id) AS total_customer_count,
COUNT(distinct CASE WHEN p.plan_id = 4 THEN customer_id ELSE NULL END) AS churned_count
FROM subscriptions s 
LEFT JOIN plans p
ON s.plan_id = p.plan_id
) 
SELECT *, ROUND(CAST(CTE.churned_count as numeric)/ CAST(CTE.total_customer_count as numeric) * 100,1) AS percentage
FROM CTE 
```

5. How many customers have churned straight after their initial free trial? What percentage is this rounded to the nearest whole number?

 ```sql
WITH CTE2 AS 
(
	WITH CTE AS 
	(
		SELECT s.customer_id, p.plan_name, LEAD(plan_name, 1) OVER (order by customer_id, start_date) as subsequent
		FROM subscriptions s 
		LEFT JOIN plans p
		ON s.plan_id = p.plan_id
		ORDER BY s.customer_id, s.start_date
	) 
	SELECT COUNT(distinct CASE WHEN plan_name = 'trial' AND subsequent = 'churn' THEN customer_id END) AS total_count
	FROM CTE
) 
SELECT *, ROUND(cast((total_count) as numeric)/1000 * 100, 1) AS percentage
FROM CTE2
```
![image](https://user-images.githubusercontent.com/87967846/147866988-88bdc7bb-aa31-4dcb-b480-725227e943fe.png)


6. What is the number and percentage of customer plans after their initial free trial?
 ```sql
WITH CTE2 AS 
(
	WITH CTE AS 
	(
		SELECT s.plan_id, s.customer_id, p.plan_name, LEAD(plan_name, 1) OVER (order by customer_id, start_date) as subsequent
		FROM subscriptions s 
		LEFT JOIN plans p
		ON s.plan_id = p.plan_id
		ORDER BY s.customer_id, s.start_date
	) 
	SELECT COUNT(distinct CASE WHEN plan_name = 'trial' AND subsequent = 'basic monthly' THEN customer_id END) AS total_basic,
	COUNT(distinct CASE WHEN plan_name = 'trial' AND subsequent = 'pro monthly' THEN customer_id END) AS total_pro, 
	COUNT(distinct CASE WHEN plan_name = 'trial' AND subsequent = 'pro annual' THEN customer_id END) AS total_annual,
	COUNT(distinct CASE WHEN plan_name = 'trial' AND subsequent = 'churn' THEN customer_id END) AS total_churn
	FROM CTE
) 
SELECT *, ROUND(cast((total_basic) as numeric)/1000 * 100, 0) AS basic_pct, 
ROUND(cast((total_pro) as numeric)/1000 * 100, 0) AS pro_pct, 
ROUND(cast((total_annual) as numeric)/1000 * 100, 0) AS annual_pct,
ROUND(cast((total_churn) as numeric)/1000 * 100, 0) AS churn_pct
FROM CTE2
```
![image](https://user-images.githubusercontent.com/87967846/147867021-4ee96efd-5f37-48b6-8154-81af9d4c6d40.png)


7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31? 
 ```sql
WITH CTE AS 
(
	SELECT *, row_number() over (partition by customer_id order by customer_id asc, start_date desc) as RN 
	FROM subscriptions s 
	LEFT JOIN plans p
	ON s.plan_id = p.plan_id
	WHERE s.start_date <= '2020-12-31'
) 
SELECT plan_name, COUNT(CASE WHEN rn = 1 THEN customer_id END) AS customer_count, ROUND(COUNT(*):: numeric  * 100 / (SELECT COUNT(distinct customer_id) 
													 FROM subscriptions), 2)
FROM CTE 
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147867028-6bc021a7-c18a-4f48-915b-12724ab9c981.png)


8. How many customers have upgraded to an annual plan in 2020?
 ```sql
WITH CTE AS 
(
		SELECT s.plan_id, s.customer_id, p.plan_name, LEAD(plan_name, 1) OVER (order by customer_id, start_date) as subsequent
		FROM subscriptions s 
		LEFT JOIN plans p
		ON s.plan_id = p.plan_id
		WHERE s.start_date <= '2020-12-31'
		ORDER BY s.customer_id, s.start_date
) 
SELECT COUNT(DISTINCT CASE WHEN subsequent = 'pro annual' THEN customer_id END) AS count_annual 
FROM CTE
```

![image](https://user-images.githubusercontent.com/87967846/147867037-56d7bce6-a596-4c4f-b8d2-ceff648d9fbb.png)

9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
 ```sql
WITH trial AS 
( 
SELECT customer_id, plan_id, start_date AS trial_date
FROM subscriptions
WHERE plan_id = 0 
), 
annual AS 
(
SELECT customer_id, plan_id, start_date AS annual_date
FROM subscriptions 
WHERE plan_id = 3 
)
SELECT ROUND(AVG(annual_date - trial_date),0) AS difference 
FROM trial t 
JOIN annual a 
ON t.customer_id = a.customer_id 
```
![image](https://user-images.githubusercontent.com/87967846/147867052-9dcfb1b2-c24e-49c7-8172-fac39ec1f26b.png)


-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

 ```sql
WITH customer_time AS
(
SELECT s.customer_id, MAX(start_date) - (SELECT MIN(start_date) FROM subscriptions WHERE customer_id = s.customer_id) AS days_diff
FROM subscriptions s
WHERE s.plan_id = 3
GROUP BY customer_id
)
SELECT MIN(days_diff), MAX(days_diff) 
FROM customer_time;
-- our range is between 7 and 346 days, hence the interval should be up till 360 days. 
-- The number of intervals required is then 12. 
SELECT s.customer_id, s.start_date - (SELECT MIN(start_date) FROM subscriptions 
									  WHERE customer_id = s.customer_id) AS c1
FROM subscriptions s
WHERE s.plan_id = 3 
GROUP BY s.customer_id, s.start_date

SELECT * FROM Subscriptions

WITH upgrade AS
(
SELECT s.customer_id, s.plan_id, s.start_date,
(WIDTH_BUCKET((s.start_date-(SELECT MIN(start_date) 
							 FROM subscriptions 
							 WHERE customer_id = s.customer_id)),0,360,12) - 1) AS bucket
FROM subscriptions s
WHERE s.plan_id = 3
)
SELECT bucket, CASE WHEN bucket = 0 THEN bucket * 30 || '-' || (bucket+1) * 30 || ' days' 
ELSE (bucket * 30) + 1 || '-' || (bucket + 1) * 30 || ' days' END AS period, 
COUNT (distinct customer_id) As count 
FROM 
upgrade 
GROUP BY bucket, period
order by bucket
```
![image](https://user-images.githubusercontent.com/87967846/147867085-446372dc-d06e-46d3-b517-1a8bbacb64d2.png)


-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
 ```sql
WITH CTE AS 
(
		SELECT s.plan_id, s.customer_id, p.plan_name, LAG(plan_name, 1) OVER (PARTITION BY s.customer_id order by customer_id, start_date) as subsequent
		FROM subscriptions s 
		LEFT JOIN plans p
		ON s.plan_id = p.plan_id
		WHERE s.start_date <= '2020-12-31'
		ORDER BY s.customer_id, s.start_date
) 
SELECT COUNT(distinct CASE WHEN plan_name = 'pro annually' AND subsequent = 'pro monthly' THEN customer_id END) AS COUNT
FROM 
CTE 
```
![image](https://user-images.githubusercontent.com/87967846/147867107-d61ec15e-fabe-4878-9a67-e17e0f64ee20.png)

