-----------------------------------------------------------------------------------------------------------------            
/* DATA PREPARATION
-----------------------------------------------------------------------------------------------------------------            
	- Creates a workspace table similar to sales_data_sample to assure raw data integrity.
	- Inserts data from sales_data_sample into the workspace table.
	- Drops unnecessary columns (ADDRESSLINE2, TERRITORY, PHONE).
	- Modifies the data type of the ORDERDATE column to DATETIME.
*/
CREATE TABLE workspace LIKE sales_data_sample;

INSERT INTO workspace
SELECT * 
FROM sales_data_sample; 

ALTER TABLE workspace
DROP COLUMN ADDRESSLINE2, DROP COLUMN TERRITORY, DROP COLUMN PHONE;

ALTER TABLE workspace
MODIFY COLUMN ORDERDATE DATETIME;

-----------------------------------------------------------------------------------------------------------------            
-- EXPLORATORY DATA ANALYSIS (EDA)
-----------------------------------------------------------------------------------------------------------------            
/* We will be covering the topics:
	-Sales Statistics: Calculation of key statistics such as mean, median, quartiles, and range of sales data.
	-Total Revenue: Calculation of the total revenue.
	-Total Revenue by Product Line: Analysis of total revenue by product line.
	-Total Revenue by Product Line and Country: Further breakdown of revenue by both product line and country.
	-Revenue for Each Year: Analysis of revenue trends over different years.
	-Percentage Growth of Revenue: Calculation of the percentage growth of revenue between each year and the prior year.
	-Total Sales Revenue for Each Month: Analysis of revenue trends over different months.
	-Top 5 Customers: Identification of the top 5 customers based on total sales revenue, country, and product line.
	-Top 10 Best Selling Products: Identification of the top 10 best-selling products.
	-Top 10 Least Sold Products by Country: Identification of the top 10 least sold products by country.
	-Average Order Quantity, Sales Amount per Order, Price, and Revenue by Country: Calculation of average order quantity, average sales amount per order, average price, and average revenue by country.
*/

-- Sales Statistics
SELECT 
    'Sales' AS Metric,
    ROUND(AVG(SALES),2) AS Mean,
    MIN(SALES) AS Min,
    MAX(SALES) AS Max,
    MAX(SALES) - MIN(SALES) AS ´Range´,
    (
        SELECT AVG(SALES)
        FROM (
            SELECT @rownum1:=@rownum1+1 AS rownum, SALES
            FROM (SELECT @rownum1:=0) r, workspace
            ORDER BY SALES
        ) AS s, (SELECT COUNT(*) AS total_rows FROM workspace) t
        WHERE s.rownum IN (FLOOR((t.total_rows + 1) / 2), FLOOR((t.total_rows + 2) / 2))
    ) AS Median,
    (
        SELECT SALES
        FROM (
            SELECT @rownum2:=@rownum2+1 AS rownum, SALES
            FROM (SELECT @rownum2:=0) r, workspace
            ORDER BY SALES
        ) AS s, (SELECT COUNT(*) AS total_rows FROM workspace) t
        WHERE s.rownum = CEIL(t.total_rows / 4)
    ) AS Q1,
    (
        SELECT SALES
        FROM (
            SELECT @rownum3:=@rownum3+1 AS rownum, SALES
            FROM (SELECT @rownum3:=0) r, workspace
            ORDER BY SALES
        ) AS s, (SELECT COUNT(*) AS total_rows FROM workspace) t
        WHERE s.rownum = CEIL(3 * t.total_rows / 4)
    ) AS Q3
FROM 
    workspace;
    
/*
CONCLUSIONS:
These statistics provide a comprehensive overview of the sales data distribution, 
highlighting key measures such as central tendency (mean, median), dispersion (range), and quartiles (Q1, Q3).

-Mean: The average sales value is $3553.89.
-Minimum (Min): The lowest recorded sales value is $482.13.
-Maximum (Max): The highest recorded sales value is $14082.80.
-Range: The range of sales values spans from the minimum to the maximum, which is $13600.67.
-Median: The median sales value, representing the middle of the dataset, is $3184.80.
-Q1 (First Quartile): 25% of the data fall below $2203.11, which is the first quartile value.
-Q3 (Third Quartile): 75% of the data fall below $4508.00, which is the third quartile value.
*/

-- Total Revenue calculation
SELECT SUM(SALES) as TotalRevenue
FROM workspace;

-- Total revenue by product line
SELECT 
    PRODUCTLINE,
    ROUND(SUM(SALES), 2) AS TotalRevenue
FROM 
    workspace
GROUP BY 
    PRODUCTLINE
ORDER BY
    TotalRevenue DESC;

-- Total revenue by productline and country
SELECT 
    COUNTRY, PRODUCTLINE,
    ROUND(SUM(SALES), 2) AS TotalRevenue
FROM 
    workspace
GROUP BY 
    COUNTRY,
    PRODUCTLINE
ORDER BY 
    TotalRevenue DESC;

-- Revenue for each year
SELECT 
    YEAR_ID,
    ROUND(SUM(SALES), 2) AS TotalRevenue
FROM 
    workspace
GROUP BY 
    YEAR_ID;

-- Calculate the percentage growth of revenue between each year and the prior year
SELECT 
    current_year.YEAR_ID AS Year,
    ROUND(current_year.TotalRevenue,2) AS Revenue_CurrentYear,
    ROUND(COALESCE((current_year.TotalRevenue - prior_year.TotalRevenue),2) / prior_year.TotalRevenue * 100, 0) AS Revenue_Growth_Percentage
FROM 
    (SELECT 
         YEAR_ID,
         SUM(SALES) AS TotalRevenue
     FROM 
         workspace
     GROUP BY 
         YEAR_ID) AS current_year
LEFT JOIN 
    (SELECT 
         YEAR_ID,
         SUM(SALES) AS TotalRevenue
     FROM 
         workspace
     GROUP BY 
         YEAR_ID) AS prior_year ON current_year.YEAR_ID = prior_year.YEAR_ID + 1;

-- Total sales revenue for each month
SELECT 
    YEAR(ORDERDATE) AS Year,
    MONTH(ORDERDATE) AS Month,
    ROUND(SUM(TotalRevenue), 2) AS MonthlySalesRevenue
FROM 
    workspace
GROUP BY 
    YEAR(ORDERDATE),
    MONTH(ORDERDATE)
ORDER BY 
    Year, Month;


-- Top 5 customers based on total sales revenue, country and productline
SELECT 
    CUSTOMERNAME,
	PRODUCTLINE, 
    COUNTRY,
    ROUND(SUM(SALES), 2) AS TotalRevenue
FROM 
    workspace
GROUP BY 
    CUSTOMERNAME, PRODUCTLINE, COUNTRY
ORDER BY 
    TotalRevenue DESC
LIMIT 5;

-- Top 10 Best Selling Products 
SELECT 
    PRODUCTCODE, PRODUCTLINE,
    ROUND(SUM(SALES), 2) AS TotalRevenue
FROM 
    workspace
GROUP BY 
    PRODUCTCODE, PRODUCTLINE
ORDER BY 
    TotalRevenue DESC
LIMIT 10;

-- Top 10 Least Sold Products by Country
SELECT 
    COUNTRY, 
    PRODUCTLINE,
    PRODUCTCODE,
    SUM(QUANTITYORDERED) AS TotalQuantitySold,
    SALES AS TotalRevenue
FROM 
    workspace
GROUP BY 
    PRODUCTLINE,
    PRODUCTCODE,
    COUNTRY,
    SALES
ORDER BY 
    TotalQuantitySold ASC
LIMIT 10;

-- Average order quantity, sales amount per order, price, and revenue by country
SELECT 
	COUNTRY,
	ROUND(AVG(QUANTITYORDERED)) AS AvgOrderQuantity,
    ROUND(AVG(PRICEEACH),2) AS AvgPriceEach,
    ROUND(AVG(SALES),2) AS AvgSales
FROM 
    workspace
GROUP BY COUNTRY
ORDER BY AvgSales DESC;


    