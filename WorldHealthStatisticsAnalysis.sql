/*
This project uses SQL to analyze World Health Statistics data from World Health Organization website: 
https://www.who.int/data/gho/publications/world-health-statistics
Data was slightly edited in excel to remove extra columns and change formatting.
The project was done in MySQL Workbench.
*/

 -- Create table and import data.
USE who;
CREATE TABLE health_statistics
(
IND_NAME VARCHAR(255),
DIM_GEO_NAME VARCHAR(255),
DIM_1_CODE VARCHAR(255),
VALUE_NUMERIC DOUBLE
);

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/World_Health_Statistics_modified.csv' 
INTO TABLE who.health_statistics character set latin1
FIELDS TERMINATED BY ','
IGNORE 1 lines;

-- Check all the rows were loaded. 
SELECT COUNT(*) FROM who.health_statistics;

-- Let's see what regions have highest percent of overweight children.
SELECT hs.DIM_GEO_NAME, hs.VALUE_NUMERIC
FROM who.health_statistics as hs
WHERE hs.IND_NAME = 'Prevalence of overweight in children under 5 (%)' 
AND hs.DIM_GEO_NAME LIKE '%region%'
ORDER BY hs.VALUE_NUMERIC DESC;


-- Let's see how obesity rates change with age.
-- Unfortunately MySql doesn't support pivot method, so we'll use CASE.
SELECT 
	hs.DIM_GEO_NAME,
    SUM(CASE WHEN hs.IND_NAME = 'Prevalence of overweight in children under 5 (%)' THEN hs.VALUE_NUMERIC ELSE 0 END) as Under_5,
    SUM(CASE WHEN hs.IND_NAME = 'Prevalence of obesity among children and adolescents (5–19 years) (%)' THEN hs.VALUE_NUMERIC ELSE 0 END) as Between_5_19,
    SUM(CASE WHEN hs.IND_NAME = 'Age-standardized prevalence of obesity among adults (18+ years) (%)' THEN hs.VALUE_NUMERIC ELSE 0 END) as Adults
FROM who.health_statistics as hs
WHERE hs.DIM_GEO_NAME LIKE '%region%' 
	AND (hs.IND_NAME = 'Prevalence of obesity among children and adolescents (5–19 years) (%)' 
		OR hs.IND_NAME = 'Prevalence of overweight in children under 5 (%)' 
        OR hs.IND_NAME = 'Age-standardized prevalence of obesity among adults (18+ years) (%)')
GROUP BY hs.DIM_GEO_NAME
ORDER BY Under_5 DESC;


-- Let's compare healthy life expectancy between men and women in different countries
SELECT 
	hs.DIM_GEO_NAME,
    SUM(CASE WHEN hs.DIM_1_CODE = 'SEX_FMLE' THEN hs.VALUE_NUMERIC ELSE 0 END) as Women,
    SUM(CASE WHEN hs.DIM_1_CODE = 'SEX_MLE' THEN hs.VALUE_NUMERIC ELSE 0 END) as Men
FROM who.health_statistics as hs
WHERE hs.IND_NAME = 'Healthy life expectancy at birth (years)'
GROUP BY hs.DIM_GEO_NAME
ORDER BY hs.DIM_GEO_NAME;

-- In order to better understand the dataset, we will try to join it with additional dataset downloaded from:
-- https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv
-- that provided mapping between countries and regions.
-- We'll try to understand if regional numbers in the original dataset are averages across country level data in the region.
-- Table for the country region mapping dataset was created using Table Data Import Wizard.
-- For comparison we'll use 'Life expectancy at birth (years)' parameter for males.

-- Let's check that we have region mapping for all the countries
SELECT distinct(hs.DIM_GEO_NAME) 
FROM who.health_statistics as hs
WHERE hs.DIM_GEO_NAME NOT IN
	(SELECT who.countries_regions_map.name FROM who.countries_regions_map) AND hs.DIM_GEO_NAME NOT LIKE '%region%';

-- Looks like most countries are mapped

-- Let's compare average female life expectancy by region based on built in region data 
-- and based on a separate country to region mapping dataset.
SELECT map.region, ROUND(AVG(hs.VALUE_NUMERIC),2) as average
FROM who.health_statistics as hs
INNER JOIN who.countries_regions_map as map
ON hs.DIM_GEO_NAME=map.name
WHERE hs.IND_NAME = 'Life expectancy at birth (years)' AND hs.DIM_1_CODE != 'SEX_MLE'
GROUP BY map.region
ORDER BY average DESC;

SELECT who.health_statistics.DIM_GEO_NAME, ROUND(AVG(who.health_statistics.VALUE_NUMERIC),2) as average
FROM who.health_statistics
WHERE who.health_statistics.IND_NAME = 'Life expectancy at birth (years)' 
	AND who.health_statistics.DIM_1_CODE != 'SEX_MLE' 
	AND who.health_statistics.DIM_GEO_NAME LIKE '%region%'
GROUP BY who.health_statistics.DIM_GEO_NAME
ORDER BY average DESC;

-- We can see that there is not a perfect match between regional data in WHO table compared to averaging based on country to region mapping.
-- For Africa, numbers are close: 64.46 compared to 64.89.
-- For Europe, 77.9 compared to 79.32.
-- There might be some discrepancy though as to which country is mapped to what region.

-- Let's compare one parameter ('Suicide mortality rate (per 100 000 population)') across subregions using the region mapping dataset.
SELECT who.countries_regions_map.subregion, ROUND(AVG(who.health_statistics.VALUE_NUMERIC),2) as average
FROM who.health_statistics
INNER JOIN who.countries_regions_map
ON who.health_statistics.DIM_GEO_NAME=who.countries_regions_map.name
WHERE who.health_statistics.IND_NAME = 'Suicide mortality rate (per 100 000 population)'
GROUP BY who.countries_regions_map.subregion
ORDER BY average DESC;

-- Let's use window function to find country ranking for a subset of healthcare quality indicators.
SELECT hs.IND_NAME, hs.DIM_GEO_NAME, RANK() OVER(PARTITION BY hs.IND_NAME ORDER BY hs.VALUE_NUMERIC DESC) as country_ranking
FROM who.health_statistics as hs
WHERE hs.IND_NAME like '%Density%'
ORDER BY hs.DIM_GEO_NAME;

-- Let's find deltas between the indicator value for men vs women for different indicators/countries
SELECT 	
  hs.IND_NAME, 
  hs.DIM_GEO_NAME,
  hs.VALUE_NUMERIC - LAG(hs.VALUE_NUMERIC)
    OVER (ORDER BY hs.DIM_GEO_NAME, hs.DIM_1_CODE) AS delta
FROM who.health_statistics as hs
WHERE hs.DIM_1_CODE like '%SEX_FMLE%' OR  hs.DIM_1_CODE like '%SEX_MLE%'
-- ORDER BY hs.IND_NAME, hs.DIM_GEO_NAME











