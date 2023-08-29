-- Create view
CREATE OR REPLACE VIEW radius_change_comparison(DELIVERY_AREA_ID, DELIVERY_RADIUS_METERS, EVENT_STARTED_TIMESTAMP, 
												radius_status, previous_radius, previous_date, previous_radius_status, radius_change_length, radius_change,
											    event_start_date, event_start_time, event_end_date, event_end_time) AS (

WITH default_radiuses_tagged AS (
/* join the delivery_radius_log table to the table above (default_radiuses) to tag the default and temporary radiuses as 
 * in the question we are asked to ignore the changes to temporary radiuses*/
	SELECT drl.*, dr.radius_status FROM delivery_radius_log drl 
	LEFT JOIN default_radiuses dr
	ON drl."DELIVERY_RADIUS_METERS" = dr.DELIVERY_RADIUS_METERS

),			
													
previous_radius_and_date_change AS (
/* Using window function (LAG) we bring in the previous radius change in meters and 
 * the date of the change next to the current values to prepare for comparison For the first record, we 
	replace null with 0 for previous record and an arbitrary old date for the previous date */
	SELECT *,
	COALESCE(LAG("DELIVERY_RADIUS_METERS") OVER(), 0) AS previous_radius,
	COALESCE(LAG("EVENT_STARTED_TIMESTAMP") OVER(), '1970-01-01') AS previous_date,
	COALESCE(LAG("radius_status") OVER(), 'N/A') AS previous_radius_status
	FROM default_radiuses_tagged
),												
												

radius_change_comparison AS (
/* by comparing the previous and current radiuses, 
 * we can find whenever the radius is decucted and tag it as -1. 
 * If the radius in expanded we tagged it as 1, if no change we tag as 0 */
	SELECT *, 
	ROUND(EXTRACT(epoch FROM ("EVENT_STARTED_TIMESTAMP" - previous_date ))/60, 0) AS radius_change_length,
	CASE 
		WHEN "DELIVERY_RADIUS_METERS" - previous_radius < 0 THEN -1 
		WHEN "DELIVERY_RADIUS_METERS" - previous_radius = 0 THEN 0 
		ELSE 1 
	END AS radius_change,
	-- extracted date and time from previous radius change timestamp
	DATE(previous_date) as event_start_date, 
	previous_date::time as event_start_time,
	DATE("EVENT_STARTED_TIMESTAMP") as event_end_date,
	"EVENT_STARTED_TIMESTAMP"::time as event_end_time
	
	FROM previous_radius_and_date_change
)

SELECT * FROM radius_change_comparison												

);



-- answer to question 1.2
 with radius_change_length AS (
/* having in mind we only want to calculate the reduction to default values, 
 * we calculate the length of radius changes only when we have changes to DEFAULT radiuses */
	SELECT * FROM radius_change_comparison
	WHERE
	radius_change = -1 
	AND previous_radius <> 0 -- this line excludes the first record which has no previous radius.
	AND (previous_radius_status = 'Default' AND radius_status = 'Default')
	OR (previous_radius_status = 'Default' AND radius_status = 'Temporary')
	OR (previous_radius_status = 'Temporary' AND radius_status = 'Temporary') 
	/* The third case above should be also included in case there are several 
	temporary changes in a row, which should be part of change from the preivous default. 
	we can alternatively write one line to exclude
	 (previous_radius_status = 'Temporary' AND radius_status = 'Default') instead of three lines with OR
	 but for the ease of readability and being self-explanatory, I wrote it this way*/

)

SELECT 
ROUND(SUM(radius_change_length), 0) AS total_mins, 
ROUND(SUM(radius_change_length) /60, 0) AS hours, 
ROUND(MOD(SUM(radius_change_length), 60), 0) AS minutes 
FROM radius_change_length;
 

