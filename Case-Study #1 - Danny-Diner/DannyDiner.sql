CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  SELECT *
  FROM sales
  
  SELECT * 
  FROM members 
  
  SELECT * 
  FROM menu
  
  ---- 1. What is the total amount each customer spent at the restaurant?--
  
  SELECT s.customer_id, SUM(m.price) AS Total_Spent 
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  GROUP BY 1
  ORDER BY 1 
  
  -- 2. How many days has each customer visited the restaurant?--
  SELECT customer_id, COUNT(Distinct order_date)
  FROM sales 
  GROUP BY 1 
  ORDER BY 1 
 
 -- 3. What was the first item from the menu purchased by each customer?
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

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

-------- Identifying which item is the most purchased on the menu----------------------- 
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

--------- Identifying how many times it was purchased by all the customers--------------------------
SELECT * FROM 
(
  SELECT m.product_name, count(m.product_name) AS count_of_item_purchased
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  GROUP BY product_name
 ) AS alias 
 ORDER BY count_of_item_purchased desc 
 
 -- 5. Which item was the most popular for each customer?
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

---- OR use the CTE Method ----- 
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

-- 6. Which item was purchased first by the customer after they became a member?

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
	
---- Using CTE ----- 
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

-- 7. Which item was purchased just before the customer became a member?

SELECT * 
FROM
(
	SELECT s.customer_id, m.product_name,
	dense_rank() over (partition by s.customer_id order by s.order_date desc) as rn
	FROM sales s 
	JOIN menu m 
	ON s.product_id = m.product_id
	JOIN members a
	ON s.customer_id = a.customer_id
	WHERE a.join_date > s.order_date
) AS product_before_member
WHERE rn = 1; 

---- Using CTE ---- 
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

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(Distinct m.product_name) AS unique_items,
SUM(m.price) AS Total_spent
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
JOIN members a
ON s.customer_id = a.customer_id
WHERE a.join_date > s.order_date
GROUP BY s.customer_id
	
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id, 
SUM(CASE WHEN m.product_name NOT IN ('sushi') THEN m.price*10 ELSE m.price*20 END) AS points
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY 1

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

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

---- Using SubQuery ---- 
SELECT s.customer_id, 
SUM(CASE WHEN s.order_date BETWEEN a.join_date AND a.special_date THEN m.price*20 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name NOT IN ('sushi') THEN m.price*10 
WHEN s.order_date NOT BETWEEN a.join_date AND a.special_date AND m.product_name IN ('sushi') THEN m.price*20 
ELSE NULL END) AS special_points
FROM 
(
	SELECT *, a.join_date + INTERVAL '1 week' AS special_date
	FROM members a
) AS a
JOIN sales s
ON s.customer_id = a.customer_id
JOIN menu m 
ON m.product_id = s.product_id
GROUP BY 1

-----Bonus Question------ 

--The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
--Recreate the following table output using the available data -> (with member (Y/N))

SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN a.join_date > s.order_date THEN 'N' ELSE 'Y' END AS "member"
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members a 
ON s.customer_id = a.customer_id
ORDER BY s.customer_id ASC, s.order_date ASC, m.product_name ASC


-----Bonus Question 2 ------ 

--Danny also requires further information about the ranking of customer products,
--but he purposely does not need the ranking for non-member purchases so he expects 
--null ranking values for the records when customers are not yet part of the loyalty 
--program.
SELECT *, CASE WHEN member = 'N' THEN NULL ELSE dense_rank() over (partition by customer_id, member ORDER BY order_date) END AS ranking
FROM 
(
SELECT s.customer_id, s.order_date, m.product_name, m.price, 
CASE WHEN a.join_date > s.order_date THEN 'N' ELSE 'Y' END AS "member"
FROM sales s 
JOIN menu m 
ON s.product_id = m.product_id
LEFT JOIN members a 
ON s.customer_id = a.customer_id
ORDER BY s.customer_id ASC, s.order_date ASC, m.product_name ASC
) as t2

---- using CTE ---- 

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


