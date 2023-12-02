--List of actors ordered by film appearances
SELECT 
	a.actor_id,
	a.first_name,
	a.last_name,
	COUNT(a.actor_id) "number of films"
FROM actor a
JOIN film_actor fa ON a.actor_id=fa.actor_id
GROUP BY a.actor_id
ORDER BY COUNT(a.actor_id) DESC;

--Actors who have not participated in any films yet
SELECT 
	a.actor_id,
	a.first_name,
	a.last_name,
	fa.film_id
FROM actor a
LEFT JOIN film_actor fa ON a.actor_id=fa.actor_id
WHERE film_id IS NULL;

--Ratings ordered by the most number of films
SELECT 
	rating,
	COUNT(rating) "number of films"
FROM film
GROUP BY rating
ORDER BY COUNT(rating) DESC;

--The average length of films released each year
SELECT
	ROUND(AVG(length),2)||' min' AS "Average movie time"
FROM film;

----Film categories and the number of films in each category
SELECT 
	c.name,
	COUNT(c.name) "number of films"
FROM category c
LEFT JOIN film_category fc ON c.category_id=fc.category_id
GROUP BY c.name
ORDER BY COUNT(c.name) DESC;

--Categories with the fewest films
SELECT 
	c.name,
	COUNT(c.name) "number of films"
FROM category c
LEFT JOIN film_category fc ON c.category_id=fc.category_id
GROUP BY c.name
ORDER BY COUNT(c.name) LIMIT 10;

--The store with the highest total revenue
SELECT
	c.store_id,
	SUM(p.amount) "total revenue"
FROM payment p
JOIN customer c ON p.customer_id = c.customer_id
GROUP BY (c.store_id);

--the staff member with the most transactions
SELECT
	s.first_name,
	s.last_name,
	SUM(p.amount) "total transactions"
FROM staff s JOIN payment p ON s.staff_id=p.staff_id
GROUP BY s.staff_id
ORDER BY SUM(p.amount) DESC;

--Films that are currently not in stock
SELECT 
	f.title
FROM inventory i
RIGHT JOIN film f ON i.film_id=f.film_id
WHERE i.film_id IS NULL
;

--The most rented films from the inventory
SELECT
	f.title,
	COUNT(r.rental_id) AS "number of rentals"
FROM film f
JOIN inventory i ON f.film_id=i.film_id
JOIN rental r ON i.inventory_id=r.inventory_id
GROUP BY f.title
ORDER BY COUNT(r.rental_id) DESC;

--Popular rental months in order
SELECT 
	TO_CHAR(rental_date, 'YYYY-MM'),
	COUNT(rental_id) "number of rentals"
FROM rental
GROUP BY TO_CHAR(rental_date, 'YYYY-MM')
ORDER BY COUNT(rental_id) DESC; 

--Top 10 customers with most rentals
SELECT 
	c.first_name||' '||c.last_name AS "full name",
	COUNT(payment_id) AS "number of rentals"
FROM customer c
LEFT JOIN payment p on c.customer_id=p.customer_id
GROUP BY c.first_name||' '||c.last_name
ORDER BY COUNT(payment_id) DESC
LIMIT 10;

--Top 10 customers with least rentals
SELECT 
	c.first_name||' '||c.last_name AS "full name",
	COUNT(payment_id) AS "number of rentals"
FROM customer c
LEFT JOIN payment p on c.customer_id=p.customer_id
GROUP BY c.first_name||' '||c.last_name
ORDER BY COUNT(payment_id) 
LIMIT 10;

--Total revenue generated from payments
SELECT 
	SUM(amount)||' $' AS total_revenue
FROM payment;

--Customers with the highest total payment amounts
SELECT 
	c.first_name||' '||c.last_name AS "full name",
	COUNT(payment_id) AS "number of rentals",
	SUM(amount) AS "total amount"
FROM customer c
LEFT JOIN payment p on c.customer_id=p.customer_id
GROUP BY c.first_name||' '||c.last_name
ORDER BY SUM(amount) DESC
LIMIT 10;

--Pairs of actors who have appeared together in more than one film
SELECT 
	fa1.actor_id actor1_id,
	a1.first_name||' '||a1.last_name actor1_full_name,
	fa2.actor_id actor2_id,
	a2.first_name||' '||a2.last_name actor2_full_name,
	COUNT(DISTINCT(fa1.film_id)) AS number_of_collaborations
FROM film_actor fa1
JOIN 
	film_actor fa2 ON fa1.film_id=fa2.film_id AND fa1.actor_id<>fa2.actor_id
JOIN
	film f ON fa1.film_id=f.film_id
JOIN 
	actor a1 ON fa1.actor_id=a1.actor_id
JOIN 
	actor a2 ON fa2.actor_id=a2.actor_id
GROUP BY 
	actor1_id,
	actor1_full_name,
	actor2_id,
	actor2_full_name
HAVING COUNT(DISTINCT(fa1.film_id)) > 1
ORDER BY 
	number_of_collaborations DESC;
	
--Films that belong to multiple categories and list those categories

SELECT 
	f.film_id,
	f.title,
	COUNT(c.category_id) category_count,
	STRING_AGG(c.name, ', ' ORDER BY c.name) AS categories_list
FROM film f
JOIN
	film_category fc ON f.film_id=fc.film_id
JOIN 
	category c ON fc.category_id=c.category_id
GROUP BY
	f.film_id,
	f.title
HAVING 
	COUNT(c.category_id) > 1
ORDER BY
	COUNT(c.category_id) DESC;


--Monthly growth percentage
WITH mr AS(
SELECT 
	SUM(amount) monthly_revenue,
	TO_CHAR(payment_date,'YYYY-MM') "month"
FROM 
	payment
GROUP BY
	TO_CHAR(payment_date,'YYYY-MM')
ORDER BY 
	TO_CHAR(payment_date,'YYYY-MM')
)
SELECT 
	month,
	monthly_revenue,
	LAG(monthly_revenue) OVER() previous_monthly_revenue,
	ROUND((((monthly_revenue)-(LAG(monthly_revenue) OVER()))/LAG(monthly_revenue) OVER())*100,2)||' %' growth_percentage
FROM mr;

--Customers who have consistently rented films in consecutive months
WITH NoR AS(
SELECT 
	customer_id,
	TO_CHAR(rental_date, 'YYYY-MM') rental_month,
	COUNT(rental_id) number_of_rentals
FROM 
	rental
GROUP BY 
	customer_id,
	TO_CHAR(rental_date, 'YYYY-MM')
),

consec_month AS(
SELECT
customer_id,
rental_month,
LAG(rental_month) 
	OVER(PARTITION BY customer_id 
		 ORDER BY rental_month) previous_rental_month
FROM 
	NoR
ORDER BY 
	customer_id,
	rental_month
),

consecutive_customers AS(
SELECT
	cm.customer_id,
	cm.rental_month,
	previous_cm.previous_rental_month
FROM 
	consec_month cm
JOIN 
	consec_month previous_cm ON cm.customer_id=previous_cm.customer_id
	AND cm.rental_month=previous_cm.previous_rental_month
)

SELECT 
	customer_id,
	COUNT(customer_id) number_of_consecutive_months
FROM 
	consecutive_customers
GROUP BY 
	customer_id
ORDER BY
	number_of_consecutive_months DESC;


--Total rentals per film
WITH film_rating_rentals AS (
SELECT 
	f.film_id,
	f.title,
	f.rating,	
	i.inventory_id,
	r.rental_id
FROM 
	film f
JOIN
	inventory i ON f.film_id=i.film_id
JOIN 
	rental r ON i.inventory_id=r.inventory_id
)

SELECT 
	title,
	rating,
	COUNT(rental_id) number_of_film_rentals
FROM 
	film_rating_rentals
GROUP BY 
	title, rating
ORDER BY
	number_of_film_rentals DESC;

--Total rentals by rating
WITH film_rating_rentals AS (
SELECT 
	f.film_id,
	f.title,
	f.rating,	
	i.inventory_id,
	r.rental_id
FROM 
	film f
JOIN
	inventory i ON f.film_id=i.film_id
JOIN 
	rental r ON i.inventory_id=r.inventory_id
)

SELECT 
	rating,
	COUNT(rating) number_of_rating_rentals
FROM 
	film_rating_rentals
GROUP BY 
	rating, rating
ORDER BY
	number_of_rating_rentals DESC;
	
--Dynamic pricing strategy based on the popularity of films and their rental history
/*
ALTER TABLE film
ADD COLUMN dynamic_price NUMERIC(5,2);
*/

UPDATE film
SET dynamic_price =
	CASE
		WHEN NoR.number_of_rentals >=20 THEN 1.2
		WHEN NoR.number_of_rentals >=15 THEN 1.1
		ELSE film.dynamic_price
	END 
FROM (
SELECT
	f.film_id,
	COUNT(DISTINCT(r.rental_id)) number_of_rentals
FROM 
	film f
JOIN
	inventory i ON f.film_id=i.film_id
JOIN
	rental r ON r.inventory_id=i.inventory_id
JOIN
	payment p ON p.rental_id=r.rental_id
GROUP BY
	f.film_id
) AS NoR
WHERE NoR.film_id=film.film_id;

-- Number of customers per Store
WITH store_address AS(
SELECT
	s.store_id,
	s.address_id,
	ad.address,
	ct.city,
	cn.country
FROM
	store s
JOIN
	address ad ON s.address_id=ad.address_id
JOIN 
	city ct ON ad.city_id=ct.city_id
JOIN 
	country cn ON ct.country_id=cn.country_id
),
customer_address AS (
SELECT
	cst.customer_id,
	cst.store_id,
	cst.address_id,
	ad.address,
	ad.postal_code,
	ct.city,
	cn.country,
	ad.phone
FROM
	customer cst
JOIN
	address ad ON cst.address_id=ad.address_id
JOIN 
	city ct ON ad.city_id=ct.city_id
JOIN 
	country cn ON ct.country_id=cn.country_id
),
customer_store_address AS (
SELECT 
	ca.customer_id,
	sa.store_id,
	ca.address customer_address,
	ca.city customer_city,
	ca.country customer_country,
	sa.address store_address,
	sa.city store_city,
	sa.country store_country
FROM 
	store_address sa
RIGHT JOIN 
	customer_address ca ON sa.store_id=ca.store_id)
	
SELECT
	store_id store,
	store_address,
	store_city,
	store_country,
	COUNT(customer_id) number_of_customers
FROM 
	customer_store_address
GROUP BY 
	store_id,
	store_address,
	store_city,
	store_country;


