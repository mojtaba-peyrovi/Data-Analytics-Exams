CREATE OR REPLACE VIEW preprocessed_table_for_question_2 (PURCHASE_ID, TIME_RECEIVED, TIME_DELIVERED, DELIVERY_METHOD, 
														  END_AMOUNT_WITH_VAT_EUR, DROPOFF_DISTANCE_STRAIGHT_LINE_METRES,
														  date_received, time_only_received, delivery_area_id, DELIVERY_RADIUS_METERS, EVENT_STARTED_TIMESTAMP, 
														  radius_status, previous_radius, previous_date, previous_radius_status, radius_change_length, 
														  radius_change, event_start_date, event_start_time, event_end_date, event_end_time, 
														  revenue_status, year_reduced, month_reduced, day_of_month_reduced, 
														  day_of_week_reduced, hour_reduced, day_time_reduced)  AS (

WITH radius_change_comparison AS (
/* using the view we created to answer question 1.2 to answer question 2*/
	SELECT * FROM radius_change_comparison rcc 
),

purchases_date_preprocessed AS (
select p.*, DATE(p."TIME_RECIEVED") as date_received, p."TIME_RECIEVED"::time as time_only_received from purchases p 
),	

-- question 2
date_condition_first AS (
/* The dataset above is joined with purchases dataset to answer question 2. 
 * The join conditions are: 
 * 1) the purchase time falls between the previous and current reduction date  
 * 2) the purchase date happens on the same day as the reduction end
 * 3) the purchase date happens on the same day as the reduction start
 * because for question 2 we aren't explicitly told to ignore temporary cases, the dataset below includes both temporary and default radius reductions */

	SELECT * FROM purchases_date_preprocessed p 
	JOIN radius_change_comparison rcc
	ON p.date_received  < rcc.event_end_date
	AND p.date_received > rcc.event_start_date

),



date_condition_second AS (

	SELECT * FROM purchases_date_preprocessed p 
	LEFT JOIN radius_change_comparison rcc
	ON p.date_received = rcc.event_start_date
),



date_condition_third AS (

	SELECT * FROM purchases_date_preprocessed p  
	LEFT JOIN radius_change_comparison rcc
	ON p.date_received = rcc.event_end_date
),

joined_all as (
 	select * from date_condition_first
	UNION
	select * from date_condition_second where time_only_received > event_start_time
	UNION
	select * from date_condition_third where time_only_received < event_end_time
),							  

missed_revenue_tagged AS (
/* Having the above table join in mind (order received between the previous and current reduction), 
 * if the DROP OFF DISTANCE is bigger than the DELIVERY RADIUS and smaller than the previous radius 
 * 	while the reduction is hapenning, it is a missed opportunity. For example, if we reduced 
 *	from 6500m  to 3500m, while the order comes during this period and the DROPP OFF distance is
 * 5000m, it means because of the reduction, this opportunity is not being shown on the website 
 * 	and we missed it. This is true for any DROP OFF value smaller than 6500m, because if the DROPP OFF value 
 * 	is bigger than 6500m, it means even if we didn't reduce during this period, this wouldn't be shown on the 
 * website anyways and it wasn't a potential opportunity.
 *  */
	SELECT *,
	CASE 
		WHEN 
		"DROPOFF_DISTANCE_STRAIGHT_LINE_METRES" > "delivery_radius_meters"
		AND
		"DROPOFF_DISTANCE_STRAIGHT_LINE_METRES" < previous_radius
		AND 
		event_start_date <> event_end_date
	
		/* because we are not required to do calculation and this calcualtion is already beyond the scope, 
		I leave it here, but there is a missing condition where the radius start and end happen on the same day.
		*/
 
		THEN 'Missed Revenue'
	
	END AS revenue_status	
	FROM joined_all
	
	
),


join_with_data_filters AS (
/* Just to be able to give the analysts enough dimensions to analyze the data for question 2.1, 
 *	I extracted some data from the EVENT START DATETIME Of course, this is not ideal to have all 
 *	these dimensions added directly to such dataset and usually we handle these date-related dimensions inside 
 * DimDate table. These dimensions are extracted just for the ease of access to answer question 2.1 */

SELECT *,
EXTRACT(YEAR FROM EVENT_STARTED_TIMESTAMP) AS year_reduced,
EXTRACT(MONTH FROM EVENT_STARTED_TIMESTAMP) AS month_reduced,
EXTRACT(DAY FROM EVENT_STARTED_TIMESTAMP) AS day_of_month_reduced,
TO_CHAR(EVENT_STARTED_TIMESTAMP, 'DAY') AS day_of_week_reduced,
EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) AS hour_reduced,
CASE 
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 6 AND 10 THEN 'Early Morning'
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 10 AND 12 THEN 'Morning'
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 12 AND 13 THEN 'Noon'
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 13 AND 17 THEN 'Afternoon'
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 17 AND 24 THEN 'Evening'
	WHEN EXTRACT(HOUR FROM EVENT_STARTED_TIMESTAMP) BETWEEN 0 AND 6 THEN 'Night'
END AS day_time_reduced

from missed_revenue_tagged)

select * from join_with_data_filters

);


-- sample answer for question 2.1 (It doesn't return correct values because of duplicated values)
SELECT day_of_week_reduced, day_time_reduced, COUNT(hour_reduced) AS hours_reduced
FROM preprocessed_table_for_question_2
WHERE radius_change = -1
GROUP BY 1, 2
ORDER BY 1, 3 DESC;




-- sample answer for question 2.2 (It doesn't return correct values because of duplicated values)
SELECT DISTINCT EVENT_STARTED_TIMESTAMP, previous_date, 
ROUND(radius_change_length,0) radius_change_length_mins, 
DELIVERY_RADIUS_METERS, previous_radius
FROM preprocessed_table_for_question_2
WHERE radius_change = -1
order by ROUND(radius_change_length,0) DESC;



-- sample answer for question 2.3
SELECT PURCHASE_ID, TIME_RECEIVED, EVENT_STARTED_TIMESTAMP, 
DROPOFF_DISTANCE_STRAIGHT_LINE_METRES, DELIVERY_RADIUS_METERS, 
previous_radius, radius_status, END_AMOUNT_WITH_VAT_EUR AS revenue_eur, revenue_status 
FROM preprocessed_table_for_question_2
WHERE revenue_status = 'Missed Revenue' AND radius_change = -1
ORDER BY 8 DESC;






