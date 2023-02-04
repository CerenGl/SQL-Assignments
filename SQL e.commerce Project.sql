SELECT *
FROM e_commerce_data;

--Analyzing the data

1)
SELECT TOP 3 Customer_Name, Order_Quantity
FROM e_commerce_data
ORDER BY Order_Quantity DESC;


2)
SELECT TOP 1 Customer_Name,
	DATEDIFF(DAY, Order_Date, Ship_Date) AS shipping_duration
FROM e_commerce_data
ORDER BY shipping_duration DESC;

3)
--a
SELECT COUNT(DISTINCT Customer_Name)
FROM e_commerce_data
WHERE MONTH(Order_Date) = 01;
--b
WITH CTE AS
(
	SELECT DISTINCT Customer_Name,
		   COUNT (DATEPART(MONTH, Order_Date)) OVER(PARTITION BY Customer_Name) AS total
	FROM e_commerce_data
	WHERE YEAR(Order_Date) = 2011
)
SELECT Customer_Name  
FROM CTE
WHERE total >11

INTERSECT

SELECT Customer_Name
FROM e_commerce_data
WHERE MONTH(Order_Date) = 01;

4)
WITH CTE1 AS
(
SELECT Cust_ID, Order_Date, MIN(Order_Date) AS Purchase_Date, 
ROW_NUMBER() OVER (PARTITION BY Cust_ID ORDER BY Order_Date) AS row_number
FROM e_commerce_data
GROUP BY Cust_ID, Order_Date
) 
SELECT Cust_ID, 
	   MIN(Order_Date) AS First_Purchase_Date,
	   MIN(CASE WHEN row_number = 3 THEN Order_Date END) AS Third_Purchase_Date,
	   DATEDIFF(DAY, MIN(Order_Date),  MIN(CASE WHEN row_number = 3 THEN Order_Date END)) AS Elapsed_Time
FROM CTE1
GROUP BY Cust_ID

5)
SELECT A.Customer_Name, A.partial_total, B.final_total,
	ROUND(CONVERT(DECIMAL(5,2), A.partial_total) / B.final_total * 100, 2)  AS ratio     
FROM
(
SELECT DISTINCT Customer_Name, 
	SUM(total) OVER(PARTITION BY Customer_Name) partial_total
FROM
(
SELECT Customer_Name, Prod_ID, total, 
       COUNT(Prod_ID) OVER(PARTITION BY Customer_Name) quantity
FROM
	(SELECT Customer_Name, Prod_ID,
		 SUM(Order_Quantity) AS total
	FROM e_commerce_data
	GROUP BY Customer_Name, Prod_ID
) AS t1
WHERE Prod_ID  IN ('Prod_11' , 'Prod_14' )
) AS t2
WHERE quantity = 2
) AS A
INNER JOIN
(
SELECT DISTINCT Customer_Name,
     SUM(Order_Quantity) OVER(PARTITION BY Customer_Name) final_total
FROM e_commerce_data
) AS B ON A.Customer_Name = B.Customer_Name

---Customer Segmentation

SELECT *
FROM e_commerce_data;

1)
CREATE VIEW customer_visits AS

SELECT Cust_ID,  
	   YEAR(Order_Date) AS year, 
	   MONTH(Order_Date) AS month
FROM e_commerce_data

2)
CREATE VIEW monthly_visits AS
SELECT Cust_ID,  
	   YEAR(Order_Date) AS year, 
	   MONTH(Order_Date) AS month,
	   COUNT(*) AS visits
FROM e_commerce_data
GROUP BY Cust_ID, Order_Date

3)
CREATE VIEW customer_visits_next_month AS
SELECT Cust_ID,  
	   YEAR(Order_Date) AS year, 
	   MONTH(Order_Date) AS month,
	   DATEADD(MONTH, 1, Order_Date) AS next_month
FROM e_commerce_data
GROUP BY Cust_ID, Order_Date

4)

CREATE VIEW customer_monthly_gap AS

SELECT a.Cust_ID, a.year, a.month,
       DATEDIFF(MONTH, b.Order_Date, a.Order_Date) AS gap
FROM 
(
      SELECT Cust_ID, Order_Date,
             YEAR(Order_Date) AS year, MONTH(Order_Date) AS month
      FROM e_commerce_data
) AS a
JOIN
(
      SELECT Cust_ID, Order_Date,
             YEAR(Order_Date) AS year, MONTH(Order_Date) AS month
      FROM e_commerce_data
) AS b
ON a.Cust_ID = b.Cust_ID AND a.Order_Date > b.Order_Date

5)

SELECT Cust_ID, 
	   AVG(gap) AS avg_gap,
       CASE
           WHEN AVG(gap) >= 1 THEN 'Churn'
           WHEN AVG(gap) < 1 THEN 'Regular'
       END AS category
FROM customer_monthly_gap
GROUP BY Cust_ID
