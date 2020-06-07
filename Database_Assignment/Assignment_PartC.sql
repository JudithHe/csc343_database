/***********************************************
** File: Assignment2-PartC.sql
** Desc: Combining Data, Nested Queries, Views and Indexes, Transforming Data
** Author: Bingqian Lu
** Date: May 4, 2020
************************************************/
######## QUESTION 1 ######## – { 20 Points }
# a) List the actors (firstName, lastName) who acted in more than 25 movies.
	# Note: Also show the count of movies against each actor
SELECT a.first_name, a.last_name, COUNT(f.film_id) FROM film_actor AS f
	INNER JOIN actor AS a ON f.actor_id = a.actor_id GROUP BY a.actor_id HAVING COUNT(f.film_id) > 25;
# b) List the actors who have worked in the German language movies.
	# Note: Please execute the below SQL before answering this question.
SET SQL_SAFE_UPDATES=0;
UPDATE film SET language_id=6 WHERE title LIKE "%ACADEMY%";
SELECT a.first_name, a.last_name, f.language_id FROM film_actor AS fa 
	INNER JOIN film AS f ON f.film_id = fa.film_id
    INNER JOIN actor AS a ON fa.actor_id = a.actor_id
	WHERE f.language_id = 6;
# c) List the actors who acted in horror movies.
	# Note: Show the count of movies against each actor in the result set.	
SELECT * FROM category; # Horror movies: category_id = 11 
SELECT a.first_name, a.last_name, fc.category_id, COUNT(a.actor_id) FROM film_actor AS fa 
	INNER JOIN actor AS a ON a.actor_id = fa.actor_id
    INNER JOIN film_category AS fc ON fa.film_id = fc.film_id
    WHERE fc.category_id = 11 GROUP BY a.actor_id; 
# d) List all customers who rented more than 3 horror movies.
SELECT c.first_name, c.last_name, COUNT(c.customer_id) FROM customer c
	RIGHT outer JOIN rental r ON r.customer_id = c.customer_id 
    RIGHT outer JOIN inventory i ON i.inventory_id = r.inventory_id
    RIGHT outer JOIN film_category fc ON fc.film_id = i.film_id
    WHERE fc.category_id = 11 GROUP BY(c.customer_id) HAVING COUNT(c.customer_id) > 3;
    
# e) List all customers who rented the movie which starred SCARLETT BENING
SELECT actor_id  FROM actor WHERE first_name LIKE 'SCARLETT' AND last_name LIKE 'BENING'; # SCARLETT BENING: actor_id = 124
SELECT c.first_name, c.last_name, fa.actor_id FROM customer c 
	INNER JOIN rental r ON r.customer_id = c.customer_id 
    INNER JOIN inventory i ON i.inventory_id = r.inventory_id
    INNER JOIN film_actor fa ON fa.film_id = i.film_id
    WHERE fa.actor_id = 124;
# f) Which customers residing at postal code 62703 rented movies that were Documentaries.
SELECT c.first_name, c.last_name, ad.postal_code, ca.name FROM customer c
	INNER JOIN address ad ON ad.address_id = c.address_id 
	INNER JOIN rental r ON r.customer_id = c.customer_id 
    INNER JOIN inventory i ON i.inventory_id = r.inventory_id
    INNER JOIN film_category fc ON fc.film_id = i.film_id
    INNER JOIN category ca ON ca.category_id = fc.category_id
    WHERE ad.postal_code = 62703 AND ca.name = 'Documentary';
# g) Find all the addresses where the second address line is not empty (i.e., contains some text), and return these second addresses sorted.
SELECT address2 FROM address WHERE address2 != '' AND address2 IS NOT NULL order by address2 desc;
# There is no such address
# h) How many films involve a “Crocodile” and a “Shark” based on film description ?
SELECT COUNT(film_id) FROM film WHERE description LIKE '%shark%' AND description LIKE '%crocodile%';
# i) List the actors who played in a film involving a “Crocodile” and a “Shark”, along with the release year of the movie, sorted by the actors’ last names.
SELECT a.first_name, a.last_name, f.title, f.release_year FROM actor a 
	INNER JOIN film_actor fa ON fa.actor_id = a.actor_id
    INNER JOIN film f ON f.film_id = fa.film_id
    WHERE f.description LIKE '%shark%' AND description LIKE '%crocodile%'
    ORDER BY a.last_name ASC;
# j) Find all the film categories in which there are between 55 and 65 films. 
	# Return the names of categories and the number of films per category, sorted from highest to lowest by the number of films.
SELECT ca.name, COUNT(fc.category_id) FROM film_category fc 
	INNER JOIN category ca ON ca.category_id = fc.category_id
	INNER JOIN film f ON f.film_id = fc.film_id
    GROUP BY fc.category_id ORDER BY COUNT(fc.category_id) DESC;
# k) In which of the film categories is the average difference between the film replacement cost and the rental rate larger than 17$?
SELECT ca.name, AVG(replacement_cost-rental_rate) FROM film_category fc 
	INNER JOIN category ca ON ca.category_id = fc.category_id
    INNER JOIN film f ON f.film_id = fc.film_id
    GROUP BY fc.category_id HAVING AVG(replacement_cost-rental_rate) > 17;
# l) Many DVD stores produce a daily list of overdue rentals so that customers can be contacted and asked to return their overdue DVDs. 
	# To create such a list, search the rental table for films 
	# with a return date that is NULL and where the rental date is further in the past than the rental duration specified in the film table. 
    # If so, the film is overdue and we should produce the name of the film along with the customer name and phone number.
CREATE VIEW overdue_rental AS 
	SELECT r.rental_id, c.first_name, c.last_name, ad.phone, r.return_date, datediff(CURDATE(),r.rental_date) AS datediff FROM rental r
	INNER JOIN customer c ON c.customer_id = r.customer_id 
	INNER JOIN address ad ON ad.address_id = c.address_id
	INNER JOIN inventory i ON i.inventory_id = r.inventory_id
	INNER JOIN film f ON f.film_id = i.film_id
	WHERE r.return_date IS NULL AND datediff(CURDATE(),r.rental_date) > f.rental_duration;
SELECT rental_id, first_name, last_name, phone, return_date, datediff FROM overdue_rental;
# m) Find the list of all customers and staff given a store id
	# Note : use a set operator, do not remove duplicates 
SELECT * FROM customer c 
LEFT JOIN staff s ON s.store_id = c.store_id
UNION ALL
SELECT * FROM staff s
RIGHT JOIN customer c ON c.store_id = s.store_id;


######## QUESTION 2 ######## – { 10 Points }
# a) List actors and customers whose first name is the same as the first name of the actor with ID 8.
SELECT a.actor_id, a.first_name act_firstName, a.last_name act_lastName, c.first_name cus_firstName, c.last_name cus_lastName FROM actor a
LEFT JOIN customer c ON c.first_name = a.first_name WHERE a.actor_id = 8;
# b) List customers and payment amounts, with payments greater than average the payment amount
# Not sure about what 'Average' in the question refers to. 2 ways of calculation are provided here:  
# Way 1 - Customers who spent more than the average amount of all customers are selected. (AVG=112.5484307)
CREATE VIEW payment_per_customer AS
    SELECT 
        c.first_name, c.last_name, SUM(p.amount) amt
    FROM
        customer c
            INNER JOIN
        payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id;
SELECT AVG(amt) FROM payment_per_customer; 
    # 112.5484307
SELECT first_name, last_name, amt FROM payment_per_customer WHERE amt > 112.5484307;
# Way 2 - Each payment more than the average is selected. (AVG=4.200667)
SELECT avg(amount) FROM payment;
SELECT 
    p.rental_id,
    p.customer_id,
    c.first_name,
    c.last_name,
    p.amount
FROM
    payment p
        INNER JOIN
    customer c ON c.customer_id = p.customer_id
WHERE
    p.amount > (SELECT 
            AVG(payment.amount)
        FROM
            payment);

# c) List customers who have rented movies at least once
	# Note: use IN clause
SELECT first_name, last_name FROM customer WHERE customer_id IN 
	(SELECT 
            customer_id
        FROM
            rental);
# d) Find the floor of the maximum, minimum and average payment amount
SELECT FLOOR(MAX(amount)), FLOOR(MIN(amount)), FLOOR(AVG(amount)) FROM payment;


######## QUESTION 3 ######## – { 5 Points }
# a) Create a view called actors_portfolio which contains information about actors and films ( including titles and category).
CREATE VIEW actors_portfolio AS
    SELECT 
        a.first_name, a.last_name,f.title film, c.name category
    FROM
        actor a
            INNER JOIN
        film_actor fa ON fa.actor_id = a.actor_id
            INNER JOIN
        film f ON f.film_id = fa.film_id
            INNER JOIN
        film_category fc ON fc.film_id = f.film_id
            INNER JOIN
        category c ON c.category_id = fc.category_id;
SELECT * FROM actors_portfolio;

# b) Describe the structure of the view and query the view to get information on the actor ADAM GRANT
DESCRIBE actors_portfolio;
SELECT * FROM actors_portfolio WHERE first_name LIKE 'ADAM' AND last_name LIKE 'GRANT';

# c) Insert a new movie titled Data Hero in Sci-Fi Category starring ADAM GRANT
# Error Code 1393: cannot modify more than one base through a join view.
 INSERT INTO `actors_portfolio`(`first_name`, `last_name`, `film`,`category`)
 values('ADAM', 'GRANT','Data Hero','Sci-Fi'); 
 SELECT * FROM actors_portfolio WHERE category= 'Sci-Fi';





######## QUESTION 4 ######## – { 5 Points }
# a) Extract the street number (characters 1 through 4) from customer addressLine1
select * from address;
select substring(address,1,4) AS addressLine1 from address;
# b) Find out actors whose last name starts with character A, B or C.
SELECT last_name, first_name FROM actor
WHERE last_name LIKE 'A%' or last_name LIKE 'B%' or last_name LIKE 'C%';

# c) Find film titles that contains exactly 10 characters
SELECT title FROM film WHERE title REGEXP '^.{10}$';    
# d) Format a payment_date using the following format e.g "22/1/2016"
SELECT DATE_FORMAT(CURDATE(), '%d/%m/%Y');
# e) Find the number of days between two date values rental_date & return_date
SELECT return_date,rental_date, DATEDIFF(return_date, rental_date) AS difference FROM rental;


######## QUESTION 5 ######## – { 20 Points }
# Provide 5 additional queries and indicate the specific business use cases they address.
# 1.The most unpopular film in store
CREATE VIEW Least_popular AS
SELECT 
	f.title film, COUNT(f.film_id) rent_times, f.rental_rate rental_rate
FROM
    film f
        INNER JOIN
    inventory i ON i.film_id = f.film_id
        INNER JOIN
    rental r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id
ORDER BY COUNT(f.film_id) asc LIMIT 1;
SELECT * FROM Least_popular;

# 2.Averge rental rate from film rental
SELECT 
    AVG(p.amount) averge_money
FROM
    payment p
        INNER JOIN
    rental r ON r.rental_id = p.rental_id;
    
# 3.The Customer who has spent most in stores 
SELECT c.customer_id, c.first_name, c.last_name,  SUM(p.amount) accum_amt
FROM
	customer c
		INNER JOIN
	payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id order by SUM(p.amount) desc limit 1;

# 4.The rental id which was rented for the least amount of time 
SELECT rental_id,return_date, rental_date, DATEDIFF(return_date, rental_date) AS difference 
FROM rental
where return_date is not null
Order by difference Asc
Limit 1;



# 5.The most popular category for movies
SELECT ca.name most_popular_category, count(fc.film_id) 
FROM 
    film_category fc 
	INNER JOIN 
		category ca ON ca.category_id = fc.category_id
	INNER JOIN 
		film f ON f.film_id = fc.film_id
GROUP BY fc.category_id 
ORDER By count(fc.film_id) DESC
Limit 1;
