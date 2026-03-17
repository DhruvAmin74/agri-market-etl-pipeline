-- =============================================
-- Agricultural Market Price Intelligence Pipeline
-- Advanced SQL Analytical Queries (20 total)
-- =============================================

-- ==================================================
-- Q1:  High-Volatility Markets
-- ==================================================
-- Q1: High-Volatility Markets
SELECT l.State, l.Market,
       ROUND(AVG(f.Max_Price - f.Min_Price), 2) AS Avg_Price_Spread
FROM   Fact_Market_Price f
JOIN   Dim_Location l ON f.Location_ID = l.Location_ID
GROUP  BY l.State, l.Market
HAVING AVG(f.Max_Price - f.Min_Price) > 500
ORDER  BY Avg_Price_Spread DESC;

-- ==================================================
-- Q2:  Trading Volume by State & Commodity
-- ==================================================
-- Q2: Multi-Level Commodity Trading Volume
SELECT l.State, c.Commodity_Name, COUNT(f.Price_ID) AS Transaction_Count
FROM   Fact_Market_Price f
JOIN   Dim_Location  l ON f.Location_ID  = l.Location_ID
JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
GROUP  BY l.State, c.Commodity_Name
ORDER  BY l.State, Transaction_Count DESC;

-- ==================================================
-- Q3:  Monthly Average Price per Crop
-- ==================================================
-- Q3: Monthly Average Pricing per Crop
SELECT strftime('%Y-%m', f.Arrival_Date) AS Trading_Month,
       c.Commodity_Name,
       ROUND(AVG(f.Modal_Price), 2)      AS Avg_Monthly_Price
FROM   Fact_Market_Price f
JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
GROUP  BY Trading_Month, c.Commodity_Name
ORDER  BY Trading_Month ASC;

-- ==================================================
-- Q4:  Premium Grade Commodities
-- ==================================================
-- Q4: Premium Grade Commodities
SELECT c.Commodity_Name, c.Variety,
       MAX(f.Modal_Price) AS Peak_Price
FROM   Fact_Market_Price f
JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
WHERE  c.Grade NOT IN ('Faq', 'Other')
GROUP  BY c.Commodity_Name, c.Variety;

-- ==================================================
-- Q5:  Cross-State Price Comparison (Onion)
-- ==================================================
-- Q5: Cross-State Commodity Price Comparison (Onion)
WITH State_Prices AS (
    SELECT f.Arrival_Date, l.State, f.Modal_Price
    FROM   Fact_Market_Price f
    JOIN   Dim_Location  l ON f.Location_ID  = l.Location_ID
    JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
    WHERE  c.Commodity_Name = 'Onion'
)
SELECT m.Arrival_Date,
       ROUND(AVG(m.Modal_Price), 2) AS MH_Avg_Price,
       ROUND(AVG(u.Modal_Price), 2) AS Other_State_Avg
FROM   State_Prices m
JOIN   State_Prices u ON m.Arrival_Date = u.Arrival_Date
WHERE  m.State = 'Maharashtra'
  AND  u.State != 'Maharashtra'
GROUP  BY m.Arrival_Date;

-- ==================================================
-- Q6:  Market vs National Average
-- ==================================================
-- Q6: Market vs National Average Price
SELECT l.Market,
       ROUND(AVG(f.Modal_Price), 2)                          AS Market_Avg,
       ROUND((SELECT AVG(Modal_Price) FROM Fact_Market_Price), 2) AS National_Avg
FROM   Fact_Market_Price f
JOIN   Dim_Location l ON f.Location_ID = l.Location_ID
GROUP  BY l.Market
ORDER  BY Market_Avg DESC;

-- ==================================================
-- Q7:  Commodities With No Price Records
-- ==================================================
-- Q7: Commodities With No Price Records
SELECT c.Commodity_Name, c.Variety
FROM   Dim_Commodity c
LEFT   JOIN Fact_Market_Price f ON c.Commodity_ID = f.Commodity_ID
WHERE  f.Price_ID IS NULL;

-- ==================================================
-- Q8:  All-Time Max Price Location
-- ==================================================
-- Q8: Location of All-Time Maximum Price per Commodity
SELECT l.Market, c.Commodity_Name, f.Arrival_Date, f.Max_Price
FROM   Fact_Market_Price f
JOIN   Dim_Location  l ON f.Location_ID  = l.Location_ID
JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
WHERE  f.Max_Price = (
    SELECT MAX(Max_Price) FROM Fact_Market_Price
    WHERE  Commodity_ID = f.Commodity_ID
)
ORDER  BY f.Max_Price DESC;

-- ==================================================
-- Q9:  Top 5 Markets per State (DENSE_RANK)
-- ==================================================
-- Q9: Top 5 Most Expensive Markets per State (DENSE_RANK)
WITH Market_Avgs AS (
    SELECT l.State, l.Market,
           ROUND(AVG(f.Modal_Price), 2) AS Avg_Price
    FROM   Fact_Market_Price f
    JOIN   Dim_Location l ON l.Location_ID = f.Location_ID
    GROUP  BY l.State, l.Market
)
SELECT State, Market, Avg_Price, Rnk
FROM (
    SELECT State, Market, Avg_Price,
           DENSE_RANK() OVER(
               PARTITION BY State ORDER BY Avg_Price DESC
           ) AS Rnk
    FROM Market_Avgs
)
WHERE Rnk <= 5
ORDER BY State, Rnk;

-- ==================================================
-- Q10: Price Quartile Distribution
-- ==================================================
-- Q10: Price Quartile Distribution (NTILE)
SELECT c.Commodity_Name, f.Modal_Price,
       NTILE(4) OVER(
           PARTITION BY c.Commodity_ID
           ORDER BY f.Modal_Price
       ) AS Price_Quartile
FROM   Fact_Market_Price f
JOIN   Dim_Commodity c ON f.Commodity_ID = c.Commodity_ID
ORDER  BY c.Commodity_Name, Price_Quartile;

-- ==================================================
-- Q11: Cumulative Price Distribution
-- ==================================================
-- Q11: Cumulative Price Distribution (CUME_DIST)
SELECT Arrival_Date, Modal_Price,
       ROUND(CUME_DIST() OVER(ORDER BY Modal_Price), 4) AS Cumulative_Dist
FROM   Fact_Market_Price
WHERE  Commodity_ID = 1;

-- ==================================================
-- Q12: Year Open/Close Prices
-- ==================================================
-- Q12: First and Last Recorded Price of the Year
SELECT DISTINCT
       strftime('%Y', Arrival_Date) AS Year,
       Location_ID,
       FIRST_VALUE(Modal_Price) OVER(
           PARTITION BY strftime('%Y', Arrival_Date), Location_ID
           ORDER BY Arrival_Date
       ) AS Year_Open,
       LAST_VALUE(Modal_Price) OVER(
           PARTITION BY strftime('%Y', Arrival_Date), Location_ID
           ORDER BY Arrival_Date
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
       ) AS Year_Close
FROM   Fact_Market_Price;

-- ==================================================
-- Q13: 7-Day Moving Average
-- ==================================================
-- Q13: 7-Day Moving Average
SELECT Arrival_Date, Location_ID, Commodity_ID, Modal_Price,
       ROUND(AVG(Modal_Price) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ), 2) AS Moving_Avg_7D
FROM   Fact_Market_Price;

-- ==================================================
-- Q14: Day-Over-Day Price Change
-- ==================================================
-- Q14: Day-Over-Day Price Change (LAG)
SELECT Location_ID, Commodity_ID, Arrival_Date, Modal_Price,
       LAG(Modal_Price, 1) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
       ) AS Prev_Day_Price,
       (Modal_Price - LAG(Modal_Price, 1) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
       )) AS Absolute_Price_Change
FROM   Fact_Market_Price;

-- ==================================================
-- Q15: Next Day Price (LEAD)
-- ==================================================
-- Q15: Next Day Price Context (LEAD)
SELECT Location_ID, Arrival_Date, Modal_Price,
       LEAD(Modal_Price, 1) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
       ) AS Next_Day_Price
FROM   Fact_Market_Price;

-- ==================================================
-- Q16: Year-Over-Year Growth
-- ==================================================
-- Q16: Year-Over-Year Monthly Growth
WITH MonthlyData AS (
    SELECT strftime('%m', Arrival_Date) AS Month,
           strftime('%Y', Arrival_Date) AS Year,
           Commodity_ID,
           ROUND(AVG(Modal_Price), 2)   AS Avg_Price
    FROM   Fact_Market_Price
    GROUP  BY 1, 2, 3
)
SELECT Year, Month, Commodity_ID, Avg_Price,
       LAG(Avg_Price, 1) OVER(
           PARTITION BY Month, Commodity_ID ORDER BY Year
       ) AS Prev_Year_Price,
       ROUND(
           (Avg_Price - LAG(Avg_Price,1) OVER(
               PARTITION BY Month, Commodity_ID ORDER BY Year)
           ) / NULLIF(LAG(Avg_Price,1) OVER(
               PARTITION BY Month, Commodity_ID ORDER BY Year), 0) * 100
       , 2) AS YoY_Growth_Pct
FROM   MonthlyData;

-- ==================================================
-- Q17: Duplicate Entry Detection
-- ==================================================
-- Q17: Detect Duplicate Transaction Entries
SELECT Location_ID, Commodity_ID, Arrival_Date, Entry_Count
FROM (
    SELECT Location_ID, Commodity_ID, Arrival_Date,
           COUNT(*) OVER(
               PARTITION BY Location_ID, Commodity_ID, Arrival_Date
           ) AS Entry_Count
    FROM Fact_Market_Price
)
WHERE Entry_Count > 1;

-- ==================================================
-- Q18: Missing Trading Days
-- ==================================================
-- Q18: Identify Missing Trading Days
SELECT Location_ID, Arrival_Date, Prev_Date,
       CAST(julianday(Arrival_Date) - julianday(Prev_Date) AS INTEGER)
           AS Days_Between_Reports
FROM (
    SELECT Location_ID, Arrival_Date,
           LAG(Arrival_Date) OVER(
               PARTITION BY Location_ID ORDER BY Arrival_Date
           ) AS Prev_Date
    FROM Fact_Market_Price
)
WHERE Days_Between_Reports > 1;

-- ==================================================
-- Q19: Outlier Detection
-- ==================================================
-- Q19: Outlier Detection via Z-Score Approximation
WITH Stats AS (
    SELECT Location_ID, Commodity_ID,
           AVG(Modal_Price) AS Mean_Price,
           AVG(Modal_Price * Modal_Price) -
               (AVG(Modal_Price) * AVG(Modal_Price)) AS Variance
    FROM   Fact_Market_Price
    GROUP  BY Location_ID, Commodity_ID
)
SELECT f.Arrival_Date, f.Location_ID, f.Modal_Price,
       ROUND(s.Mean_Price, 2) AS Mean_Price,
       ROUND(ABS(f.Modal_Price - s.Mean_Price), 2) AS Abs_Deviation
FROM   Fact_Market_Price f
JOIN   Stats s ON f.Location_ID  = s.Location_ID
               AND f.Commodity_ID = s.Commodity_ID
WHERE  ABS(f.Modal_Price - s.Mean_Price) > (s.Mean_Price * 0.5)
ORDER  BY Abs_Deviation DESC;

-- ==================================================
-- Q20: ML Feature Matrix
-- ==================================================
-- Q20: ML Feature Matrix (Lag + Rolling Mean)
SELECT Location_ID, Commodity_ID, Arrival_Date, Modal_Price,
       LAG(Modal_Price, 1) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date) AS Lag_1,
       LAG(Modal_Price, 3) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date) AS Lag_3,
       ROUND(AVG(Modal_Price) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
           ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING), 2) AS Rolling_Mean_7D
FROM   Fact_Market_Price
WHERE  Commodity_ID = 1 AND Location_ID = 1;

