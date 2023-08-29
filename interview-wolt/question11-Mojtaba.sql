-- question 1.1
CREATE OR REPLACE VIEW default_radiuses (DELIVERY_RADIUS_METERS, frequency, percent_of_total, radius_status) AS (

WITH raduis_change_frequency AS (
/* count how many times each of the radiuses are repeated in the 'delivery radius log' dataset  */ 
	SELECT "DELIVERY_RADIUS_METERS", 
	COUNT("DELIVERY_RADIUS_METERS") AS frequency 
	FROM delivery_radius_log
	GROUP BY 1
),

radius_frequency_percent AS (
/* calculate frequency percentage of total to understand which radius is stable  */
	SELECT *,  
	ROUND(frequency * 1.0/(SELECT SUM(frequency) FROM raduis_change_frequency), 2) AS percent_of_total 
	FROM raduis_change_frequency
	ORDER BY frequency DESC
),

default_radiuses AS (
/* if the radius frequency percentage is less than 10%, we consider them unstable (temporary) cases 
	and any frequency over 10% considered stable */
	SELECT *, 
	CASE
		WHEN percent_of_total >= 0.1 THEN 'Default' ELSE 'Temporary'
	END AS radius_status	
	FROM radius_frequency_percent
	
)

SELECT * FROM default_radiuses

)



