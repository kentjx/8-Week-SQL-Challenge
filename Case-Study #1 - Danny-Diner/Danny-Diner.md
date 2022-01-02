  1. What is the total amount each customer spent at the restaurant? 
  
  ```sql
  SELECT s.customer_id, SUM(m.price) AS Total_Spent 
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  GROUP BY 1
  ORDER BY 1 
  ``` 
  ![image](https://user-images.githubusercontent.com/87967846/147865474-5e0b14cf-bb4d-4934-a44b-c3de7b90fb28.png)

  2. How many days has each customer visited the restaurant?
  
  ```sql
  SELECT customer_id, COUNT(Distinct order_date)
  FROM sales 
  GROUP BY 1 
  ORDER BY 1 
 ``` 
 
 ![image](https://user-images.githubusercontent.com/87967846/147865499-0f6dbffb-11d2-42d9-954e-cadebced7712.png)

 3. What was the first item from the menu purchased by each customer?
 ```sql
SELECT * 
FROM 
(
  SELECT s.customer_id, s.order_date, m.product_name, 
  dense_rank() over (partition by s.customer_id order by s.order_date asc) as rn
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
) as alias
WHERE rn = 1 
```
![image](https://user-images.githubusercontent.com/87967846/147865587-a653891e-c45d-4254-bbff-c039d4ce0f63.png)

4. What is the most purchased item on the menu and how many times was it purchased by all customers?

----------------------- Identifying which item is the most purchased on the menu ----------------------- 
```sql
SELECT * 
FROM
(
SELECT product_name, rank() over (ORDER BY COUNT(product_name) DESC) as rnk
FROM sales s 
JOIN menu m 
on s.product_id = m.product_id
GROUP BY product_name
) as Alias 
WHERE rnk = 1 
```
![image](https://user-images.githubusercontent.com/87967846/147865609-4a633467-0ba5-4c26-a1e3-2fd294352d24.png)

-------------------------- Identifying how many times it was purchased by all the customers --------------------------
```sql
SELECT * FROM 
(
  SELECT m.product_name, count(m.product_name) AS count_of_item_purchased
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  GROUP BY product_name
 ) AS alias 
 ORDER BY count_of_item_purchased desc 
```
![image](https://user-images.githubusercontent.com/87967846/147865619-e53dadf3-1c37-4b22-b8dd-5eeb9176d74d.png)

 5. Which item was the most popular for each customer?
```sql
SELECT * 
FROM 
(
SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS product_count, dense_rank() over (partition by s.customer_id order by COUNT(m.product_name) DESC) as RNK
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY 1, 2
) as favourites
WHERE rnk = 1 
```
![image](https://user-images.githubusercontent.com/87967846/147865639-84bdc45a-5507-4301-8351-b87781356511.png)

---- OR use the CTE Method ----- 
```sql
WITH favourites AS 
(
	SELECT s.customer_id, m.product_name, count(m.product_id) as product_count,
	dense_rank() over (partition by s.customer_id order by COUNT(m.product_name) DESC) as RNK
	FROM sales s
	JOIN menu m 
	ON s.product_id = m.product_id
	GROUP BY 1, 2
)

SELECT * 
FROM favourites 
WHERE rnk = 1;
```

6. Which item was purchased first by the customer after they became a member?

```sql
SELECT *
FROM
(
	SELECT s.customer_id, m.product_name, dense_rank() over (partition by s.customer_id order by s.order_date asc) as rn
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
	JOIN members a
	ON s.customer_id = a.customer_id
	WHERE a.join_date <= s.order_date
) as first_order
WHERE rn = 1;
```
![image](https://user-images.githubusercontent.com/87967846/147865655-4bb027a2-ff52-4eaf-8ecc-3f243b10557a.png)

----- Using CTE ----- 
```sql
WITH first_order AS 
(
	SELECT s.customer_id, m.product_name, dense_rank() over (partition by s.customer_id order by s.order_date asc) as rn
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
	JOIN members a
	ON s.customer_id = a.customer_id
	WHERE a.join_date <= s.order_date
) 

SELECT * 
FROM first_order 
WHERE rn = 1;
```
7. Which item was purchased just before the customer became a member?

```sql
WITH product_before_member AS
(
	SELECT s.customer_id, m.product_name,
	dense_rank() over (partition by s.customer_id order by s.order_date desc) as rn
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
	JOIN members a
	ON s.customer_id = a.customer_id
	WHERE a.join_date > s.order_date
)

SELECT * 
FROM product_before_member 
WHERE rn = 1;
```

![image](https://user-images.githubusercontent.com/87967846/147865668-96c3e242-d9a2-462a-9ded-07aa69ca8b53.png)


8. What is the total items and amount spent for each member before they became a member?

```sql
SELECT s.customer_id, COUNT(Distinct m.product_name) AS unique_items,
SUM(m.price) AS Total_spent
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
JOIN members a
ON s.customer_id = a.customer_id
WHERE a.join_date > s.order_date
GROUP BY s.customer_id
```

![image](https://user-images.githubusercontent.com/87967846/147865678-c42d0b4c-4b85-4f39-a51e-69aeee9f9240.png)

9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
SELECT s.customer_id, 
SUM(CASE WHEN m.product_name NOT IN ('sushi') THEN m.price*10 ELSE m.price*20 END) AS points
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147865691-e6aeea8e-838e-4503-9902-0fdbc17968dc.png)


10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
```sql
WITH CTE AS 
(
	SELECT *, a.join_date + INTERVAL '1 week' AS special_date
	FROM members a
)
SELECT s.customer_id, 
SUM(CASE WHEN s.order_date BETWEEN a.join_date AND a.special_date THEN m.price*20 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name NOT IN ('sushi') THEN m.price*10 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name IN ('sushi') THEN m.price*20 
ELSE NULL END) AS special_points
FROM CTE a
JOIN sales s
ON s.customer_id = a.customer_id
JOIN menu m 
ON m.product_id = s.product_id
GROUP BY 1
```
![image](https://user-images.githubusercontent.com/87967846/147865707-0ab2df2b-11ec-4de4-bbda-8c8742a98d7d.png)

-----Bonus Question------ 

The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
Recreate the following table output using the available data -> (with member (Y/N))

```sql
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN a.join_date > s.order_date THEN 'N' ELSE 'Y' END AS "member"
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members a 
ON s.customer_id = a.customer_id
ORDER BY s.customer_id ASC, s.order_date ASC, m.product_name ASC
```
![image](https://user-images.githubusercontent.com/87967846/147865731-4b559f1f-c341-4339-846f-bd8aff6556a5.png)

-----Bonus Question 2 ------ 

Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects 
null ranking values for the records when customers are not yet part of the loyalty program.

```sql
WITH CTE2 AS
(
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN a.join_date > s.order_date THEN 'N' ELSE 'Y' END AS "member"
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members a 
ON s.customer_id = a.customer_id
ORDER BY s.customer_id ASC, s.order_date ASC, m.product_name ASC
)

SELECT *, CASE WHEN member = 'N' THEN NULL ELSE dense_rank() over (partition by customer_id, member ORDER BY order_date) END AS ranking
FROM CTE2
```

![image](https://user-images.githubusercontent.com/87967846/147865893-64387ef6-2e83-41f0-960a-4989000b824b.png)

