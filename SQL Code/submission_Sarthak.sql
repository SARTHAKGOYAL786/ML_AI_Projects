/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
     
-- Ans 1. This query retrieves the number of customers per state from the customer table

SELECT state as 'STATE', COUNT(customer_id) AS 'Number_Of_Customers' 
FROM customer_t 
GROUP BY state;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

-- Ans 2.
-- Common Table Expression (CTE) to assign ratings based on customer feedback
WITH RatedOrders AS (
    SELECT quarter_number,
        CASE 
            WHEN customer_feedback = 'Very Bad' THEN 1
            WHEN customer_feedback = 'Bad' THEN 2
            WHEN customer_feedback = 'Okay' THEN 3
            WHEN customer_feedback = 'Good' THEN 4
            WHEN customer_feedback = 'Very Good' THEN 5 
            ELSE 0
        END AS Rating 
    FROM order_t
)
-- Main query to calculate the average rating per yearly quarter
SELECT quarter_number AS Yearly_Quarter, AVG(Rating) AS Average_Rating 
FROM RatedOrders
GROUP BY quarter_number 
ORDER BY quarter_number;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.*/
 
-- Ans 3.
-- Common Table Expression (CTE) to calculate the counts of each type of customer feedback per quarter
WITH FeedbackCounts AS (
    SELECT quarter_number, 
           customer_feedback, 
           COUNT(customer_feedback) AS count_of_customer_feedback,
           SUM(COUNT(customer_feedback)) OVER (PARTITION BY quarter_number) AS total_feedback_per_quarter
    FROM order_t 
    GROUP BY quarter_number, customer_feedback
)
-- Main query to calculate the percentage of different types of customer feedback in each quarter
SELECT quarter_number, 
       customer_feedback, 
       (count_of_customer_feedback / total_feedback_per_quarter) * 100.0 AS percentage 
FROM FeedbackCounts 
ORDER BY quarter_number, customer_feedback;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- Ans 4.
SELECT p.vehicle_maker AS Vehicle_Makers,
       COUNT(o.customer_id) AS Number_Of_Orders 
FROM product_t p 
JOIN order_t o ON p.product_id = o.product_id 
GROUP BY p.vehicle_maker 
ORDER BY Number_Of_Orders DESC 
LIMIT 5;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- Ans 5.
SELECT state, vehicle_maker,Count_of_customer
FROM (
    SELECT 
        c.state,
        p.vehicle_maker,count(c.customer_id) as Count_of_customer,
        RANK() OVER (PARTITION BY c.state ORDER BY count(c.customer_id) DESC) AS rnk
    FROM 
        product_t p 
        JOIN order_t o ON p.product_id = o.product_id 
        JOIN customer_t c ON o.customer_id = c.customer_id 
    GROUP BY 1, 2
    ORDER BY 1, 3  -- Ordering by state and rank for clarity
) x 
WHERE rnk = 1 ;  -- Selecting only the top-ranked vehicle maker in each state

-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- Ans 6.
SELECT Quarter_number,
       COUNT(order_id) AS Orders_Per_Quarter 
FROM order_t 
GROUP BY Quarter_number 
ORDER BY Quarter_number;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
-- Ans 7.     
   WITH RevenuePerQuarter AS (
    SELECT
        YEAR(order_date) AS order_year,
        QUARTER(order_date) AS order_quarter,
        SUM((vehicle_price * quantity) * (1 - discount/100)) AS total_revenue
    FROM
        order_t
    GROUP BY
        YEAR(order_date),
        QUARTER(order_date)
),
QuarterlyRevenueChange AS (
    SELECT
        order_year,
        order_quarter,
        total_revenue,
        LAG(total_revenue, 1) OVER (ORDER BY order_year, order_quarter) AS prev_quarter_revenue,
        (total_revenue - LAG(total_revenue, 1) OVER (ORDER BY order_year, order_quarter)) / LAG(total_revenue, 1) OVER (ORDER BY order_year, order_quarter) * 100 AS qoq_percentage_change
    FROM
        RevenuePerQuarter
)
SELECT
    order_year,
    order_quarter,
    total_revenue,
    prev_quarter_revenue,
    qoq_percentage_change
FROM
    QuarterlyRevenueChange;   

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/
-- Ans 8.
-- This query calculates the number of orders and revenue per quarter, considering the discount applied to each order
SELECT Quarter_number,
       COUNT(order_id) AS OrdersPerQuarter,
       SUM(vehicle_price * quantity * (1 - discount / 100)) AS RevenuePerQuarter 
FROM order_t 
GROUP BY Quarter_number 
ORDER BY Quarter_number;
-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

-- Ans 9.
SELECT c.credit_card_type, 
       AVG(o.discount) AS AverageDiscount 
FROM customer_t c 
JOIN order_t o ON c.customer_id = o.customer_id 
GROUP BY c.credit_card_type 
ORDER BY AverageDiscount;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/
-- Ans 10.
-- This query calculates the average shipping time for each yearly quarter
SELECT quarter_number AS Yearly_Quarter, 
       AVG(DATEDIFF(ship_date, order_date)) AS Shipping_AverageTime 
FROM order_t 
GROUP BY quarter_number 
ORDER BY quarter_number;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



