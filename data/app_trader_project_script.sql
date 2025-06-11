select *
from app_store_apps

select *
from play_store_apps


---MVP
--(A)RECOMMENDATIONS:
	--PRICE RANGE: $0-$3 has most reviews so perhaps more popular 
	--GENRE: games, entertainment 
	--AUDIENCE: 4+/Everyone, Teen
	
	--(NOTES)
	
	--then get counts of genre with reviews greater than 3.5 

	
--- THE FOLLOWING QUERY WILL SHOW THE APP NAME, RATING, GENRE, PRICE, RVW_COUNT, AND CONTENT RATING FOR 
	---RATING 4.0+
	---PRICE BETWEEN $0-$3
	---(p.s.) ignored the google play price altogether because its considered text
	
SELECT  DISTINCT aps.name AS apple_apps, aps.rating AS apple_rating, aps.primary_genre AS apple_genre, aps.price AS apple_price, aps.review_count AS app_rvw_count, aps.content_rating AS app_content_rating,
		ps.name AS google_apps, ps.rating AS google_rating, ps.genres AS google_genre, ps.price AS google_price, ps.review_count AS goo_rvw_count, ps.content_rating AS goo_content_rating
FROM app_store_apps AS aps
INNER JOIN play_store_apps AS ps
ON aps.name = ps.name
WHERE aps.rating >=4.0
	AND aps.price BETWEEN 0.0 and 3.0
ORDER BY apple_rating DESC, google_rating DESC;
	--AND ps.rating >= 4.0
	--AND ps.price::numeric BETWEEN 0.0 AND 3.0

--(B)
-- If both the high and low cost apps will earn the same on advertising (5,000/mo) and marketing (1,000/mo) then it would be most cost-effective to purchase the highest rated apps that are lowest cost
-- so amended the query for max profitability:
	--RATING of 4.5+
	--Price of $0
-- and also omitting platform review counts	


SELECT  DISTINCT aps.name AS apple_apps, aps.rating AS apple_rating, aps.primary_genre AS apple_genre, aps.price AS apple_price, aps.content_rating AS app_content_rating,
		ps.name AS google_apps, ps.rating AS google_rating, ps.genres AS google_genre, ps.price AS google_price, ps.content_rating AS goo_content_rating
FROM app_store_apps AS aps
INNER JOIN play_store_apps AS ps
ON aps.name = ps.name
WHERE aps.rating >=4.5
	AND aps.price = 0.0
ORDER BY aps.rating DESC, ps.rating DESC;

(--B.extended)
	--TO CREATE ADDITIONAL COLUMNS FOR 
			--AVERGAE RATINGS OF BOTH AND
			-- COLUMN WITH PRICE ((note: only used apple price in case statement-specificllay for this table))
	-- AND GET TOP 10 RESULTS:

SELECT *, ROUND(((apple_rating + google_rating)/2),2) AS avg_rating_both,
	CASE 
		WHEN apple_price = 0.00 THEN 25000 
			ELSE 0 END AS real_price
FROM (
	SELECT  DISTINCT aps.name AS apple_apps, aps.rating AS apple_rating, aps.primary_genre AS apple_genre, aps.price AS apple_price, aps.content_rating AS app_content_rating,
		ps.name AS google_apps, ps.rating AS google_rating, ps.genres AS google_genre, ps.price AS google_price, ps.content_rating AS goo_content_rating
	FROM app_store_apps AS aps
	INNER JOIN play_store_apps AS ps
	ON aps.name = ps.name
	WHERE aps.rating >=4.5
		AND aps.price = 0.0
	)
ORDER BY avg_rating_both DESC
LIMIT 10;

----ALTERNATIVELY and more precise via Daniel---
WITH combined_apps AS
(SELECT DISTINCT name,
		CASE WHEN a.price::numeric > p.price::money::numeric THEN a.price::numeric ELSE p.price::money::numeric END AS price,
		CASE WHEN ROUND(a.rating/25,2)*25 < ROUND(p.rating/25,2)*25 THEN ROUND(a.rating/25,2)*25 ELSE ROUND(p.rating/25,2)*25 END AS rating
FROM app_store_apps AS a INNER JOIN play_store_apps AS p USING (name)
ORDER BY rating DESC, price),
longevity AS
(SELECT *, ROUND((rating/.25*.5)+1,1)*12 AS longevity,
	CASE WHEN price <=2.5 THEN 25000
		WHEN price >2.5 THEN (10000 * price) END AS purchase_cost	
FROM combined_apps),
market_cost AS
(SELECT * , (1000* longevity) AS market_cost
FROM longevity),
total_cost AS
(SELECT *, (purchase_cost + market_cost) AS total_cost
FROM market_cost),
total_rev AS
(SELECT *, (10000 * longevity) AS total_revenue
FROM total_cost)
SELECT *, (total_revenue - total_cost) AS profit
FROM total_rev
ORDER BY profit DESC


-------------------------------------------------------------------------------------------------------------------------------------
--*FROM JOSIAH:

--"Here’s all the apps with price differences I could find:" 

SELECT
	DISTINCT name,
	p.price,
	a.price
FROM play_store_apps AS p
INNER JOIN app_store_apps AS a
USING(name)
WHERE p.price::money != a.price::money;


-- OTHER TABLE WITH APP NAME, RATINGS, AND PRICE-- 
SELECT 
	DISTINCT name, 
	ROUND(p.rating/25,2)*25 AS rating_round_1,
	ROUND(a.rating,2) AS rating_round_2, 
	real_price
FROM (
	SELECT 
	DISTINCT name,
	rating,
		CASE 
			WHEN price > 0.00 THEN ROUND(price*10000,0) 
			WHEN price = 0.00 THEN 25000 
			ELSE price END AS real_price
	FROM app_store_apps
)AS a
INNER JOIN play_store_apps AS p
USING(name)
WHERE real_price <= 25000
AND a.rating > 4.25
ORDER BY rating_round_1 DESC, rating_round_2 DESC
LIMIT 10;


SELECT 
	DISTINCT name, 
	ROUND(p.rating/25,2)*25 AS rating_round_1,
	ROUND(a.rating,2) AS rating_round_2, 
	real_price,
	review_count,
	install_count
FROM (
	SELECT 
	DISTINCT name,
	rating,
		CASE 
			WHEN price > 0.00 THEN ROUND(price*10000,0) 
			WHEN price = 0.00 THEN 25000 
			ELSE price END AS real_price
	FROM app_store_apps
)AS a
INNER JOIN play_store_apps AS p
USING(name)
WHERE real_price <= 25000
AND p.rating > 4.25
AND review_count > 10000000
ORDER BY rating_round_1 DESC,
		rating_round_2 DESC;



-- played with this one to get sum rvw counts where price is <2.99 or >2.99

SELECT SUM(aps.review_count::numeric) AS rvw_count
FROM app_store_apps AS aps
INNER JOIN play_store_apps AS ps
    ON aps.name = ps.name
WHERE aps.price::money::numeric > 2.99
  AND aps.review_count::numeric > 0.0;

--SIDE BY SIDE LOOK AT COUNT OF TOP APPS FOR BOTH PLATFORMS--

SELECT 
    COALESCE(a.genre, g.genre) AS genre,
    a.total_apps AS apple_store_count,
    g.total_apps AS google_play_count
FROM (
    SELECT primary_genre AS genre, COUNT(*) AS total_apps
    FROM app_store_apps
    GROUP BY primary_genre
) a
FULL OUTER JOIN (
    SELECT genres AS genre, COUNT(*) AS total_apps
    FROM play_store_apps
    GROUP BY genres
) g ON a.genre = g.genre
ORDER BY COALESCE(a.genre, g.genre);

--APPLE STORE SUM OF GENRES--

SELECT 
    primary_genre AS genre,
    COUNT(*) AS total_apps
FROM app_store_apps
GROUP BY primary_genre
ORDER BY total_apps DESC;

--GOOGLE STORE SUM OF GENRES--

SELECT 
    genres AS genre,
    COUNT(*) AS total_apps
FROM play_store_apps
GROUP BY genres
ORDER BY total_apps DESC;



--APPLE CONTENT RATING COUNTS--

SELECT 
    content_rating AS apple_content_rating,
    COUNT(*) AS app_count
FROM app_store_apps
WHERE review_count::numeric > 500
GROUP BY content_rating
ORDER BY app_count DESC;

--GOOGLE content rating counts--

SELECT 
    content_rating AS google_content_rating,
    COUNT(*) AS app_count
FROM play_store_apps
WHERE review_count > 500
GROUP BY content_rating
ORDER BY app_count DESC;