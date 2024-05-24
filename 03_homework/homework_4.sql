-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT product_name || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

Select customer_id, market_date, ROW_NUMBER() over win1 as visit_id
From customer_purchases
Group By customer_id, market_date
Window win1 AS (PARTITION BY customer_id ORDER BY market_date)
Order by customer_id, market_date

/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

Select * 
From (
	Select customer_id, market_date, ROW_NUMBER() over win1 as visit_id
	From customer_purchases
	Group By customer_id, market_date
	Window win1 AS (PARTITION BY customer_id ORDER BY market_date Desc)
) X 
Where visit_id = 1
Order by customer_id, market_date

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

Select *, Count() over win1 as purchased_cnt
From customer_purchases
Window win1 AS (PARTITION BY customer_id, product_id)
Order by customer_id, product_id


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

Select product_name,
	Case When INSTR(product_name, '-') > 0 Then Trim(SUBSTR(product_name, INSTR(product_name, '-') + 1)) End as description
From product

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

Select product_size
From product
Where product_size regexp '\d+'


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

-- v1
With T1 as (
	Select market_date, Sum(quantity * cost_to_customer_per_qty) as total_sales
	From customer_purchases
	Group By market_date
), W as (
	Select *,  ROW_NUMBER() over win1 as RowId
	From T1
	Window win1 AS (ORDER BY total_sales)
), B as (
	Select *,  ROW_NUMBER() over win1 as RowId
	From T1
	Window win1 AS (ORDER BY total_sales Desc)
)
Select market_date, total_sales, 'Worst' Descr From W Where RowId = 1
Union 
Select market_date, total_sales, 'Best' Descr From B Where RowId = 1


-- v2
With T1 as (
	Select market_date, Sum(quantity * cost_to_customer_per_qty) as total_sales
	From customer_purchases
	Group By market_date
), W as (
	Select market_date, total_sales, 'Worst' Descr 
	From T1 
	Order by total_sales Limit 1
), B as (
	Select market_date, total_sales, 'Best' Descr 
	From T1 
	Order by total_sales Desc Limit 1
)
Select * From W
Union 
Select * From B


