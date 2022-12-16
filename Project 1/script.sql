--PART 1
CREATE OR REPLACE VIEW forestation
AS
SELECT f.country_code,
        f.country_name,
        f.year,
        f.forest_area_sqkm,
        l.total_area_sq_mi,
        r.region, r.income_group,
        (f.forest_area_sqkm / (l.total_area_sq_mi * 2.59)) * 100 AS percent_forest_area,
        l.total_area_sq_mi * 2.59 AS total_area_sqkm
  FROM forest_area f
  JOIN land_area l
  ON f.country_code = l.country_code AND f.year = l.year
  JOIN regions r
  ON l.country_code = r.country_code
--a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.
SELECT f.forest_area_sqkm
		FROM forest_area f
        WHERE f.country_name = 'World'
        AND f.year = 1990;
--b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.”
SELECT f.forest_area_sqkm
		FROM forest_area f
        WHERE f.country_name = 'World'
        AND f.year = 2016;
--c. What was the change (in sq km) in the forest area of the world FROM 1990 to 2016?
--d. What was the percent change in forest area of the world between 1990 and 2016?
SELECT  
  forest2016.forest_area_sqkm - forest1990.forest_area_sqkm AS change,
  100.0*(forest2016.forest_area_sqkm - forest1990.forest_area_sqkm) / forest1990.forest_area_sqkm AS percentage
FROM forest_area  forest2016
JOIN forest_area  forest1990
	ON forest2016.country_name = forest1990.country_name
WHERE forest2016.year = '2016' AND forest1990.year = '1990'
  	AND forest2016.country_name = 'World' AND forest1990.country_name = 'World'
--e. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
SELECT l.country_name,
       l.total_area_sq_mi * 2.59 AS total_area_sqkm,
       ABS((l.total_area_sq_mi*2.59) - 
            (SELECT query1990.forest_area_sqkm - query2016.forest_area_sqkm AS diff_forest_area_sq_km
            FROM 
                (SELECT 
                    f.country_code, f.forest_area_sqkm
                    FROM forest_area f
                    WHERE f.country_name = 'World'
                    AND f.year = 1990) AS query1990
                JOIN (SELECT f.country_code,f.forest_area_sqkm
                    FROM forest_area f
                    WHERE f.country_name = 'World'
                    AND f.year = 2016) AS query2016
            ON query1990.country_code = query2016.country_code)
        ) AS diff_fa_la_sqkm
FROM land_area l
WHERE l.year = 2016
ORDER BY diff_fa_la_sqkm
LIMIT 1;


--PART 2
--Create a table that shows the Regions and their percent forest area (sum of forest area divided by sum of land area) in 1990 and 2016. (Note that 1 sq mi = 2.59 sq km).
CREATE OR REPLACE VIEW region_percent_forest
AS (
WITH sqkm_1990 AS
    (
        SELECT region,
               SUM(forest_area_sqkm) AS sum_forest_area_sqkm_1990,
               SUM(total_area_sqkm) AS sum_land_area_sqkm_1990,
               ROUND((SUM(forest_area_sqkm) / SUM(total_area_sqkm))::NUMERIC * 100,2) AS percentage_forest_area_1990
        FROM forestation
        WHERE year = 1990
        GROUP BY region
    ),
    sqkm_2016 AS
    (
        SELECT region,
               SUM(forest_area_sqkm) AS sum_forest_area_sqkm_2016,
               SUM(total_area_sqkm) AS sum_land_area_sqkm_2016,
               ROUND((SUM(forest_area_sqkm) / SUM(total_area_sqkm))::NUMERIC * 100,2) AS percentage_forest_area_2016
        FROM forestation
        WHERE year = 2016
        GROUP BY region
    )
SELECT sqkm_1990.region,
       percentage_forest_area_1990,
       percentage_forest_area_2016,
       percentage_forest_area_2016 - percentage_forest_area_1990 AS percentage_forest_area_change
FROM sqkm_1990
INNER JOIN sqkm_2016 ON sqkm_1990.region = sqkm_2016.region
)

--a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
--What was the percent forest of the entire world in 2016?
SELECT percentage_forest_area_2016 FROM region_percent_forest
WHERE region = 'World'
--Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
SELECT * FROM region_percent_forest
WHERE region != 'World'
order by percentage_forest_area_2016 DESC
----Which region had the LOWEST percent forest in 2016, to 2 decimal places?
SELECT * FROM region_percent_forest
WHERE region != 'World'
order by percentage_forest_area_2016 


--b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
--What was the percent forest of the entire world in 1990?
SELECT percentage_forest_area_1990 FROM region_percent_forest
WHERE region = 'World'
--Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
SELECT * FROM region_percent_forest
WHERE region != 'World'
order by percentage_forest_area_1990 DESC
----Which region had the LOWEST percent forest in 1990, to 2 decimal places?
SELECT * FROM percentage_forest_area_1990
WHERE region != 'World'
order by percentage_forest_area_1990

--c. Based on the table you created, which regions of the world DECREASED in forest area FROM 1990 to 2016?
SELECT * FROM region_percent_forest
WHERE region != 'World' and percentage_forest_area_1990 > percentage_forest_area_2016



--PART 3
--a. Which 5 countries saw the largest amount decrease in forest area FROM 1990 to 2016? What was the difference in forest area for each?
WITH sqkm_1990 AS
    (
        SELECT country_name,region, forest_area_sqkm AS forest_area_sqkm_1990
        FROM forestation
        WHERE year = 1990 AND country_name != 'World'
    ),
    sqkm_2016 AS
    (
        SELECT country_name,region, forest_area_sqkm AS forest_area_sqkm_2016
        FROM forestation
        WHERE year = 2016 AND country_name != 'World'
    )
SELECT sqkm_1990.country_name, sqkm_1990.region,
ROUND((forest_area_sqkm_2016 - forest_area_sqkm_1990)::NUMERIC,2) AS sqkm_change
FROM sqkm_1990
JOIN sqkm_2016 ON sqkm_1990.country_name = sqkm_2016.country_name
ORDER BY sqkm_change
LIMIT 5;

-- b. Which 5 countries saw the largest percent decrease in forest area FROM 1990 to 2016?
WITH sqkm_1990 AS
    (
        SELECT country_name, region, forest_area_sqkm AS forest_area_sqkm_1990
        FROM forestation
        WHERE year = 1990 AND country_name != 'World'
    ),
    sqkm_2016 AS
    (
        SELECT country_name, region, forest_area_sqkm AS forest_area_sqkm_2016
        FROM forestation
        WHERE year = 2016 AND country_name != 'World'
    )
SELECT sqkm_1990.country_name, sqkm_1990.region,
       ROUND((forest_area_sqkm_2016 - forest_area_sqkm_1990)::NUMERIC,2) AS sqkm_change,
       ROUND(((forest_area_sqkm_2016 - forest_area_sqkm_1990)/(forest_area_sqkm_1990))::NUMERIC * 100,2) AS percent_change
FROM sqkm_1990
INNER JOIN sqkm_2016 ON sqkm_1990.country_name = sqkm_2016.country_name
WHERE (forest_area_sqkm_2016 - forest_area_sqkm_1990) is not null
ORDER BY percent_change
LIMIT 5;

--c. If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?
WITH quartile_2016 AS
    (
        SELECT
            case
                WHEN percent_forest_area <= 25.00 THEN 'Q1'
                WHEN percent_forest_area > 25.00 AND percent_forest_area <= 50.00 THEN 'Q2'
                WHEN percent_forest_area > 50.00 AND percent_forest_area <= 75.00 THEN 'Q3'
                WHEN percent_forest_area > 75.00 THEN 'Q4'
            END AS quartile
        FROM forestation
        WHERE year = 2016 AND country_code != 'WLD' AND percent_forest_area IS NOT NULL
    )
SELECT quartile, count(*) as quartile_count
FROM quartile_2016
group by quartile
order by quartile

--d.List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.
SELECT country_name, region,ROUND(percent_forest_area::NUMERIC,2)
FROM forestation
WHERE year = 2016 AND percent_forest_area > 75.00;

--e. How many countries had a percent forestation higher than the United States in 2016?
SELECT COUNT(*)
FROM forestation a
INNER JOIN forestation b ON a.year = b.year AND a.country_code = b.country_code
WHERE a.year = 2016 AND a.percent_forest_area >
                        (
                            SELECT percent_forest_area
                            FROM forestation
                            WHERE year = 2016 AND country_code = 'USA'
                        )
