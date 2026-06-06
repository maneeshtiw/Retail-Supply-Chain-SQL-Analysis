
---------------------------------------------------------------------------------------------
-- Step 1: Create Database
CREATE DATABASE retail_supply_chain;

-- Step2: Select Database name
USE retail_supply_chain;

-- Step 3: Create Table
CREATE TABLE retail_orders (
    row_id INT, order_id VARCHAR(50), order_date DATE, ship_date DATE, ship_mode VARCHAR(50),
    customer_id VARCHAR(50), customer_name VARCHAR(100), segment VARCHAR(50), city VARCHAR(100),
    state VARCHAR(100), country VARCHAR(100), region VARCHAR(50), product_id VARCHAR(50),
    category VARCHAR(50), sub_category VARCHAR(50), product_name VARCHAR(255), sales DECIMAL(10,2),
    quantity INT, discount DECIMAL(5,2), profit DECIMAL(10,2), returned VARCHAR(20), retail_sales_people VARCHAR(100)
);

-- Step 4: Import CSV Using Workbench
-- Table Data Import Wizard


-- Step 5: Fix Columns name:
ALTER TABLE retail_orders
RENAME COLUMN `Order ID` TO Order_id,
RENAME COLUMN `Order Date` TO Order_date,
RENAME COLUMN `Ship Date` TO Ship_date,
RENAME COLUMN `Customer ID` TO Customer_ID,
RENAME COLUMN `Customer Name` TO Customer_name,
RENAME COLUMN `Product ID` TO Product_ID,
RENAME COLUMN `Product Name` TO Product_Name,
RENAME COLUMN `Ship Mode` TO Ship_Mode,
RENAME COLUMN `Retail Sales People` TO Retail_Sales_People,
RENAME COLUMN `Sub-Category` TO Sub_Category;

-- Step 6: Before Solving Businees Problems first i remove Unwanted columns. E.g: Remove Country and Postal Code:
ALTER TABLE retail_orders
DROP COLUMN `ï»¿Row ID`,
DROP COLUMN `Postal Code`,
DROP COLUMN `Country`;

-- Step 7: Verify Import data
SELECT COUNT(*) AS Total_Count FROM retail_orders;

-- Again show data;
SELECT * FROM retail_orders;

-- Start Solving Business Problems:
-- Question 1: Top 10 Customers by Sales OR Which customers generated the highest revenue?
SELECT
    Customer_ID,
    Customer_Name,
    ROUND(SUM(Sales),2) AS Total_Sales
FROM retail_orders
GROUP BY Customer_ID, Customer_Name
ORDER BY Total_Sales DESC
LIMIT 10;

-- Question 2: Find the top 5 customers by sales within each region.
WITH customer_sales AS (
    SELECT
        Region, Customer_Name,
        SUM(Sales) AS Total_Sales,
        DENSE_RANK() OVER(PARTITION BY Region ORDER BY SUM(Sales) DESC) AS rn
    FROM retail_orders
    GROUP BY Region, Customer_Name
)
SELECT *
FROM customer_sales
WHERE rn <= 5;

-- Question 3: Identify repeat customers and one-time buyers.
SELECT
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Orders_Count,
    CASE
        WHEN COUNT(DISTINCT Order_ID) = 1
	    THEN 'One-Time Buyer'
        ELSE 'Repeat Customer'
    END AS Customer_Type
FROM retail_orders
GROUP BY Customer_Name;

-- Question 4: Find the best-selling product within every category.
WITH product_sales AS (
    SELECT
        Category, Product_Name, SUM(Sales) AS Revenue, 
        ROW_NUMBER() OVER(PARTITION BY Category ORDER BY SUM(Sales) DESC) AS rn
    FROM retail_orders
    GROUP BY Category, Product_Name
)
SELECT *
FROM product_sales
WHERE rn = 1;

 -- Question 5: Track monthly sales performance.
SELECT
    Month(Order_Date) AS month,
    SUM(Sales) AS Revenue
FROM retail_orders
GROUP BY Month(Order_Date);

-- Question 6: Calculate sales growth compared to previous month.
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(Order_date, '%Y-%m') AS Month,
        SUM(Sales) AS Revenue
    FROM retail_orders
    GROUP BY DATE_FORMAT(Order_date, '%Y-%m')
)
SELECT
    Month, Revenue,
    LAG(Revenue) OVER (ORDER BY Month) AS Prev_Revenue,
    ROUND(((Revenue - LAG(Revenue) OVER (ORDER BY Month)) / LAG(Revenue) OVER (ORDER BY Month)) * 100, 2) AS Growth_Percentage
FROM monthly_sales;

-- Question 7: Rank salespeople based on total sales.
SELECT
    Retail_Sales_People,
    Round(SUM(Sales),2) AS Revenue,
    RANK() OVER(ORDER BY SUM(Sales) DESC) AS Sales_Rank
FROM retail_orders
GROUP BY Retail_Sales_People;

-- -- Question 8: Find sales reps generating the least revenue.
SELECT
    Retail_Sales_People,
    ROUND(SUM(Sales),2) AS Revenue
FROM retail_orders
GROUP BY Retail_Sales_People
ORDER BY Revenue ASC
LIMIT 10;

-- -- Question 9: Which shipping mode delivers fastest?
SELECT
    Ship_Mode,
    AVG(DATEDIFF(Ship_Date, Order_Date)) AS Avg_Delivery_Days
FROM retail_orders
GROUP BY Ship_Mode
ORDER BY Avg_Delivery_Days;

-- Question 10: Which categories have the highest return rate?
SELECT
    Category,
    COUNT(*) AS Orders,
    SUM(CASE WHEN Returned='Returned' THEN 1 ELSE 0 END) AS Returns,
    ROUND(100.0 * SUM(CASE WHEN Returned='Returned' THEN 1 ELSE 0 END) / COUNT(*),2 ) AS Return_Rate
FROM retail_orders
GROUP BY Category;

-- Question 11: Identify products frequently returned.
SELECT
    Product_Name,
    COUNT(*) AS Return_Count
FROM retail_orders
WHERE Returned='Returned'
GROUP BY Product_Name
ORDER BY Return_Count DESC
LIMIT 10;

-- Question 12: Analyze profitability across discount ranges.
SELECT
    CASE
        WHEN Discount = 0 THEN 'No Discount'
        WHEN Discount <= 0.1 THEN '0-10%'
        WHEN Discount <= 0.2 THEN '10-20%'
        ELSE '20%+'
    END AS Discount_Bucket,
    SUM(Sales) AS Revenue,
    SUM(Profit) AS Profit
FROM retail_orders
GROUP BY Discount_Bucket;

-- Question 13: Find products with negative overall profit.
SELECT
    Product_Name,
    SUM(Sales) AS Revenue,
    SUM(Profit) AS Total_Profit
FROM retail_orders
GROUP BY Product_Name
HAVING SUM(Profit) < 0
ORDER BY Total_Profit;

-- Question 14: Rank states by profit.
SELECT
    State,
    SUM(Profit) AS Profit,
    DENSE_RANK() OVER(ORDER BY SUM(Profit) DESC) AS Profit_Rank
FROM retail_orders
GROUP BY State;

-- Question 15: Calculate cumulative sales over time.
SELECT
    Order_Date,
    SUM(Sales) AS Daily_Sales,
    SUM(SUM(Sales)) OVER(ORDER BY Order_Date) AS Running_Total
FROM retail_orders
GROUP BY Order_Date;

-- Question 16: Which customers contribute to 80% of revenue?
WITH customer_sales AS (
    SELECT
        Customer_Name,
        SUM(Sales) AS Revenue
    FROM retail_orders
    GROUP BY Customer_Name
),
sales_ranked AS (
    SELECT *,
           SUM(Revenue) OVER(ORDER BY Revenue DESC) AS Running_Revenue,
           SUM(Revenue) OVER() AS Total_Revenue
    FROM customer_sales
)
SELECT *
FROM sales_ranked
WHERE Running_Revenue <= Total_Revenue * 0.80;

-- Question 17: Which products are purchased together most often?
SELECT
    a.Product_Name AS Product1,
    b.Product_Name AS Product2,
    COUNT(*) AS Frequency
FROM retail_orders a
JOIN retail_orders b
    ON a.Order_ID = b.Order_ID AND a.Product_Name < b.Product_Name
GROUP BY Product1, Product2
ORDER BY Frequency DESC;


-- Question 18: Calculate lifetime value of customers.
SELECT
    Customer_Name,
    COUNT(DISTINCT Order_ID) AS Orders,
    SUM(Sales) AS Lifetime_Value,
    SUM(Profit) AS Lifetime_Profit
FROM retail_orders
GROUP BY Customer_Name
ORDER BY Lifetime_Value DESC;

-- Question 19: Find the highest-profit product within every sub-category.
WITH profit_rank AS (
    SELECT
        Sub_Category, Product_Name,
        SUM(Profit) AS Profit, ROW_NUMBER() OVER(PARTITION BY Sub_Category ORDER BY SUM(Profit) DESC) rn
    FROM retail_orders
    GROUP BY Sub_Category, Product_Name
)
SELECT *
FROM profit_rank
WHERE rn = 1;

-- Question 20: Classify customers as New, Active, or Lost.
WITH customer_dates AS (
    SELECT
        Customer_Name,
        MIN(Order_Date) AS First_Order,
        MAX(Order_Date) AS Last_Order
    FROM retail_orders
    GROUP BY Customer_Name
)
SELECT
    Customer_Name, First_Order, Last_Order,
    CASE
        WHEN Last_Order >= CURRENT_DATE - INTERVAL 90 DAY
        THEN 'Active'
        ELSE 'Lost'
    END AS Customer_Status
FROM customer_dates;

