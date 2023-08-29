/* test cases for Question 1
 * 1.sum of frequency is equal to the total number of rows in the source table  
 * 2. all radius values in the view are present in the source table */ 



-- TEST CASE 1
SELECT 'source' source_vs_target, COUNT(*) AS row_count 
FROM delivery_radius_log drl

UNION ALL	

SELECT 'target', SUM(frequency) 
FROM default_radiuses;



-- TEST CASE 2
SELECT source."DELIVERY_RADIUS_METERS" source , target.DELIVERY_RADIUS_METERS target 
FROM 
	(SELECT DISTINCT "DELIVERY_RADIUS_METERS" FROM delivery_radius_log) source
	FULL OUTER JOIN
	(SELECT DELIVERY_RADIUS_METERS FROM default_radiuses) target 
	ON source."DELIVERY_RADIUS_METERS" = target.DELIVERY_RADIUS_METERS
	


