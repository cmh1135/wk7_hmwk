--CH week 7 homework
--1.	Create a new column called “status” in the rental table (yes, add a permanent column) that uses a case statement to indicate if a film was returned late, early, or on time. 
ALTER TABLE rental --alllows add, drop, modify of table 
ADD status varchar(40); --column to add + datatype variable character(catch all) length (max character len)
UPDATE rental SET status= --committing the added column based on data from case statement
CASE -- add conditions 
WHEN rental_duration >DATE_PART('day', return_date - rental_date) THEN 'returned early'
WHEN rental_duration <DATE_PART('day', return_date - rental_date) THEN 'returned late'
ELSE 'returned on time' -- if when not true 
END -- stops cond 
FROM film; --table to pull date, duration from 
SELECT r.status, film.title --columns needed for question 
FROM film --using this table to start a join with rental through inventory 
INNER JOIN inventory AS i 
ON film.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
GROUP BY 1, film.title ORDER BY 2; 
/* used question from homework 6 as a base with the needed joins. Used inner joins, but could have used left or right join.
Added status col using alter table.*/

--2.	Show the total payment amounts for people who live in Kansas City or Saint Louis. 
SELECT city, SUM(amount) as total_payment_amt --gets the total spent
FROM payment as pa
INNER JOIN customer as cu		
ON pa.customer_id = cu.customer_id
INNER JOIN address as a 
ON cu.address_id = a.address_id 
INNER JOIN city 
ON a.city_id = city.city_id 
WHERE city ='Kansas City'  OR --or to ge the amount for both cities 
city ='Saint Louis' 
GROUP BY city ORDER BY total_payment_amt;
/* add payment amounts to get total with limit of 
the requested cities through OR operator. Joined payment,
customer, address and city to get city and amount columns. */

--3.	How many films are in each category? Why do you think there is a table for category and a table for film category?
SELECT name AS category, COUNT(film_id) AS num_films --used film id to count  but cat id would return the same result though not as appropriate per question 
FROM category AS c
INNER JOIN film_category as fc --join category to film categorm to use name and film id
ON c.category_id = fc.category_id
Group by category ORDER BY num_films DESC; --ordered just cause 

/* The category table contains minimal information making it easy to add 
/change/updated. The film_category table has a many-to-many
relationship with category meaning as a category is 
updated in the category table a new row is created with
film and category in the film_category table. per */

--4.	Show a roster for the staff that includes their email, address, city, and country (not ids)
SELECT concat(first_name, ' ', last_name) --combine names with space between
AS employee_name, email, address, city, country 
FROM staff AS st
LEFT JOIN address AS a
ON st.address_id = a.address_id
LEFT JOIN city AS c
ON a.city_id = c.city_id 
LEFT JOIN country AS co
ON c.country_id = co.country_id 
GROUP BY employee_name, email, address, city, country 
ORDER BY employee_name;
/* used concat to join staff first and last names. Used left join 
to combine staff, address, city, country to get all roster inputs for each staff member*/

--5.	Show the film_id, title, and length for the movies that were returned from May 15 to 31, 2005
SELECT f.film_id, title, length 
FROM film AS f
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
WHERE return_date > '2005/05/15' and --limits returned dates to between these pts
return_date < '2005/05/31';
--joined film, inventory and rental to get return dates. 

--6.	Write a subquery to show which movies are rented below the average price for all movies. 
SELECT title, rental_rate
From film
GROUP BY title, rental_rate
HAVING rental_rate < (select AVG(rental_rate) from film)-- used having to handle agg function but where could be used since this is a subquery
Order by rental_rate;
/* used a nested/sub query to get the result for the avg rental rate as putting avg 
in the select statment will not run due to order of execution. In this case the subquery runs first 
then allowing for comparisson of the expression to the result of the firsst SELECT statement to determine 
the answer. having or where statement to get the < condition result */  

--7.	Write a join statement to show which movies are rented below the average price for all movies.
--Used self join 1st attempt doesnt work as it gives rental rate not average 
--could make this work by adding the subquery back in 
SELECT f.title, f1.rental_rate
FROM film as f, film as f1
GROUP BY f.title, f.rental_rate, f1.rental_rate 
HAVING f.rental_rate < AVG(f1.rental_rate) 
Order by f1.rental_rate;

--correct answer adding inner, right or left join to perform the self join 
SELECT f.title, f.rental_rate
FROM film as f 
INNER JOIN film as f1
ON f.film_id  <>  f1.film_id
GROUP BY f.title, f.rental_rate
HAVING f.rental_rate < AVG(f1.rental_rate) 
Order by f.rental_rate;
/*self joined the film table. Added a stipulation 
not to match film id to itself as that would be false 
and return no results rest of the code is from the previous ans*/

--8.	Perform an explain plan on 6 and 7, and describe what you’re seeing and important ways they differ.

EXPLAIN ANALYZE SELECT title, rental_rate
From film
GROUP BY title, rental_rate
HAVING rental_rate < (select AVG(rental_rate) from film)-- used having to handle agg function but where could be used since this is a subquery
Order by rental_rate;
/* execution time of 7.6ms, both loops through film are 
low cost / resource use at 0, seq sca on film 1 take 
longer then on film. The agg function takes slightly
less time but at a greater cost */

--#6 runs faster and uses less resources 
EXPLAIN ANALYZE SELECT f.title, f.rental_rate
FROM film as f 
INNER JOIN film as f1
ON f.film_id  <>  f1.film_id
GROUP BY f.title, f.rental_rate
HAVING f.rental_rate < AVG(f1.rental_rate) 
Order by f.rental_rate;

/* execution time of 1276.4ms, this answer performs more operations for the quesry to run
both loops through film are low cost / resource use at 0, 
seq scan take less time to run on f/f1 in this query. The agg function 
is hashed and takes takes slightly significantly 
longer to run at a much greater cost */

--9.	With a window function, write a query that shows the film, its duration, and what percentile the duration fits into. This may help https://mode.com/sql-tutorial/sql-window-functions/#rank-and-dense_rank 

/*Window functions  perform calculations across a 
set of rows that are related to the current row without grouping output in to one row */

SELECT film_id, title, length, 
NTILE(100) --distributes rows in to equal groups / partitions / buckets based on the argument
OVER --allows the use of aggregate functions without using a group by clause  
(ORDER BY length DESC) AS percentile -- controls the order that the rows are evaluated by the function
FROM film
ORDER BY percentile;
--Partition By  when used in function partitions the agg function over rows

--10.	In under 100 words, explain what the difference is between set-based and procedural programming. Be sure to specify which sql and python are. 

/* procedural programming the programmer is telling the system / coding how to perform an opertion.
Set based you tell the system what operations to perform over a set; ex. column vs a row 
and the system determines to the how to. 
Python is procedural, SQL is set based */


--Bonus: Find the relationship that is wrong in the data model. Explain why it’s wrong. 
