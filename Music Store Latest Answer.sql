
	/** Q1) Identify the employee holding the highest-ranking job title within the organization's hierarchy. **/

	SELECT * FROM music_store.employee order by levels desc limit 1;


	with highest_rank as (
	SELECT * , rank() over (order by levels desc) rnks FROM music_store.employee)
	select * from highest_rank where rnks=1;


	with highest_ranks as (

	select *, rank() over (order by levels_converted desc) rnks from 
	(SELECT *, cast(substring(levels,2,length(levels)-1) as UNSIGNED ) levels_converted  FROM music_store.employee) temp1)

	select * from highest_ranks where rnks=1;

	-- ------------------------------------------------------------------------------------

	/** Q2) Which countries have the most invoices? **/

	SELECT  billing_country, count(invoice_id)  invoice_count FROM music_store.invoice group by billing_country order by invoice_count desc;	

	Select distinct billing_country, count(invoice_id) over (partition by billing_country) invoice_count   from music_store.invoice order by invoice_count desc;

	Select *, count(invoice_id) over (partition by billing_country) invoice_count   from music_store.invoice order by invoice_count desc;

-- ------------------------------------------------------------------------------------

	/** Q3) What are the top 3 values of total invoice? **/

	select  total  from invoice order by total desc limit 3;

	-- find top disntinct values 
	select  distinct total  from invoice order by total desc limit 3;	

	with top as (
	select  * , dense_rank() over ( order by total desc) rnk from invoice)
	select distinct total from top where rnk <=3;

-- ------------------------------------------------------------------------------------

	/** Q4) Which city has the best customers? We would like to throw a promotional Music Festival in the city where we made the most money. 
	Write a query that returns one city that has the highest sum of invoice totals.
	 Return both the city name and sum of all invoice totals.**/
	 
	 select billing_city, sum(total) invoice_total from invoice group by billing_city order by invoice_total desc limit 1;
	 
	 with top_city as (
	 select * , rank() over (order by invoice_total desc) rnks from(
	 select billing_city, sum(total) invoice_total from invoice group by billing_city) temp)
	 
	 select billing_city,invoice_total,rnks  from top_city where rnks=1;
	 
-- ------------------------------------------------------------------------------------
	 
	/** Q5) Who is the best customer? The customer who has spent the most money will be declared the best customer. 
	Write a query that returns the person who has spent the most money. **/

	select c.customer_id, first_name, last_name , sum(total) invoice_total from customer c inner join invoice i on c.customer_id=i.customer_id 
	group by c.customer_id , first_name, last_name 
	order by invoice_total desc;

	select customer_id, (select concat(first_name," ", last_name)from customer c where c.customer_id=i.customer_id)  full_name  , 
	sum(total) invoice_total from invoice i group by customer_id order by invoice_total desc;

-- ------------------------------------------------------------------------------------

	/** Q6) Write a query to return the email, first name, last name, and genre of all Rock Music listeners. 
	Return your list ordered alphabetically by email starting with A.  **/


	select distinct c.email,c.first_name,c.last_name 
	from customer c inner join invoice i on c.customer_id = i.customer_id 
	inner join invoice_line il on i.invoice_id=il.invoice_id
	inner join track t on il.track_id= t.track_id 
	inner join genre g on t.genre_id= g.genre_id where g.name  like "%Rock%" order by email asc;

-- ------------------------------------------------------------------------------------

	/** Q7) Let's invite the artists who have written the most rock music in our dataset. 
	Write a query that returns the artist name and total track count of the top 10 rock bands.
	**/

	select art.artist_id, art.name , count(art.artist_id) track_count from artist art inner join album al on art.artist_id = al.artist_id
	inner join track t on al.album_id = t.album_id group by art.artist_id,  art.name order by track_count desc limit 10;


	With top_artist as
	(select *, dense_rank() over (order by track_count desc) rnk    from 
	(select art.artist_id, art.name , count(art.artist_id) track_count from artist art inner join album al on art.artist_id = al.artist_id
	inner join track t on al.album_id = t.album_id group by art.artist_id,  art.name order by track_count desc) temp)

	Select * from top_artist where rnk<=10;

-- ------------------------------------------------------------------------------------

	/** Q8) Return all the track names that have a song length longer than the average song length. 
	Return the name and milliseconds for each track.
	 Order by the song length with the longest songs listed first.  **/


	select name, milliseconds from track where milliseconds > (select avg(milliseconds) from track ) order by milliseconds desc;
	 
	 
-- ------------------------------------------------------------------------------------

	 /** Q9) Find the total amount spent by each customer on purchases related to the artist who has generated the highest revenue.
	 Write a query to return the customer name, artist name, and total amount spent **/
	 
	 with top_artist as (
	 select art.artist_id, art.name, sum(il.unit_price* il.quantity) price from  invoice_line il 
	 inner join track t on il.track_id =t.track_id 
	 inner join album alb on t.album_id = alb.album_id
	 inner join artist art on alb.artist_id = art.artist_id
	 group by art.artist_id, art.name order by price desc limit 1 )
	 
	 select c.first_name, c.last_name, art.name, sum(il.unit_price*quantity) total_price from customer c inner join invoice i on c.customer_id=i.customer_id
	 inner join invoice_line il on i.invoice_id =il.invoice_id 
	 inner join track t on il.track_id =t.track_id 
	 inner join album alb on t.album_id = alb.album_id
	 inner join artist art on alb.artist_id = art.artist_id  where art.artist_id= ( Select  top_artist.artist_id from top_artist)
	 group by c.first_name, c.last_name, art.name order by total_price desc;
	 
-- ------------------------------------------------------------------------------------
	 
	 /** 10) We want to find out the most popular music genre for each country. 
	 We determine the most popular genre as the genre with the highest amount of purchases. 
	 Write a query that returns each country along with the top genre. 
	 For countries where the maximum number of purchases is shared, return all genres.  **/
	 
	 with top_genre as (
	 select * , dense_rank() over (partition by billing_country order by total_count desc) rnk from (
	 select  i.billing_country, g.name , count(il.quantity) total_count from invoice i inner join invoice_line il on i.invoice_id=il.invoice_id
	 inner join track t on il.track_id=t.track_id 
	 inner join genre g on t.genre_id = g.genre_id
	 group by i.billing_country, g.name) temp)
	 
	 select billing_country, name, total_count from top_genre where rnk =1 order by billing_country;
	 
-- ------------------------------------------------------------------------------------

	 /** 11) Write a query that determines the customer that has spent the most on music for each country. 
	 Write a query that returns the country along with the top customer and how much they spent.
	 For countries where the top amount spent is shared, provide all customers who spent this amount. 
	 **/

	with top_rank_customer as(
	select * , dense_rank() over ( partition by billing_country order by total_amount desc ) rnk from( 
	select i.billing_country, c.customer_id, c.first_name,c.last_name,sum(total) total_amount from customer c inner join invoice i on c.customer_id = i.customer_id 
	group by i.billing_country, c.customer_id, c.first_name,c.last_name ) temp)

	select * from top_rank_customer where rnk=1;
	 
	 
	 
	 select  * from (
	select i.billing_country, c.customer_id, c.first_name,c.last_name,sum(total) total_amount, dense_rank() over ( partition by i.billing_country order by sum(total) desc ) rnk from customer c inner join invoice i on c.customer_id = i.customer_id 
	group by i.billing_country, c.customer_id, c.first_name,c.last_name ) temp where rnk=1;