# World Health Statistics
### SQL data analysis project  
This project uses World Health Statistics data from [World Health Organization website](https://www.who.int/data/gho/publications/world-health-statistics/).  
It also uses a github dataset that maps countries to regions: [Dataset](https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv)  
The project was done in MySQL Workbench 8.0.

First, some simple query to find an average percent of overweight children was executed: 
```sql
SELECT hs.DIM_GEO_NAME, hs.VALUE_NUMERIC
FROM who.health_statistics as hs
WHERE hs.IND_NAME = 'Prevalence of overweight in children under 5 (%)' 
AND hs.DIM_GEO_NAME LIKE '%region%'
ORDER BY hs.VALUE_NUMERIC DESC;
```
![Image](images/OverweightChildren.png?raw=true)  
We can see that the Americas have the highest percentage of overweight children.  

Next the obesity rate change with age was analyzed: 
```sql
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
```
![Image](images/ObesityChangeWithAge.png?raw=true)  
We can see that with the exception of Western Pacific Region, the rank of the region in regards to obesity rates remains the same in different age groups.  

Next, a query was designed to compare life expectancy between males and females:  
```sql
SELECT 
	hs.DIM_GEO_NAME,
    SUM(CASE WHEN hs.DIM_1_CODE = 'SEX_FMLE' THEN hs.VALUE_NUMERIC ELSE 0 END) as Women,
    SUM(CASE WHEN hs.DIM_1_CODE = 'SEX_MLE' THEN hs.VALUE_NUMERIC ELSE 0 END) as Men
FROM who.health_statistics as hs
WHERE hs.IND_NAME = 'Healthy life expectancy at birth (years)'
GROUP BY hs.DIM_GEO_NAME
ORDER BY hs.DIM_GEO_NAME;
```
![Image](images/MenVsWomenLifeExpectancy.png?raw=true)  
It is known that women on average live longer and the data proves it in majority of the countries.  

Next some queries were performed to investigate validity of the data and compare region level data averages from original dataset with similar averages when region average is done using a helper mapping dataset (country to region mapping).  
```sql
SELECT map.region, ROUND(AVG(hs.VALUE_NUMERIC),2) as average
FROM who.health_statistics as hs
INNER JOIN who.countries_regions_map as map
ON hs.DIM_GEO_NAME=map.name
WHERE hs.IND_NAME = 'Life expectancy at birth (years)' AND hs.DIM_1_CODE != 'SEX_MLE'
GROUP BY map.region
ORDER BY average DESC;
```
![Image](images/AverageFemaleLifeExpectancyRegionBasedOnMapping.png?raw=true)

```sql
SELECT who.health_statistics.DIM_GEO_NAME, ROUND(AVG(who.health_statistics.VALUE_NUMERIC),2) as average
FROM who.health_statistics
WHERE who.health_statistics.IND_NAME = 'Life expectancy at birth (years)' 
	AND who.health_statistics.DIM_1_CODE != 'SEX_MLE' 
	AND who.health_statistics.DIM_GEO_NAME LIKE '%region%'
GROUP BY who.health_statistics.DIM_GEO_NAME
ORDER BY average DESC;
```
![Image](images/AverageFemaleLifeExpectancyRegionBasedOnBuiltInData.png?raw=true)

We can see that there is not a perfect match between regional data in WHO table compared to averaging based on country to region mapping.
For Africa, numbers are close: 64.46 compared to 64.89.
For Europe, 77.9 compared to 79.32.
There might be some discrepancies though as to which country is mapped to what region.  

Next, window functions were used to show country rankings for a subset of healthcare quality indicators:
```sql
SELECT hs.IND_NAME, hs.DIM_GEO_NAME, RANK() OVER(PARTITION BY hs.IND_NAME ORDER BY hs.VALUE_NUMERIC DESC) as country_ranking
FROM who.health_statistics as hs
WHERE hs.IND_NAME like '%Density%'
ORDER BY hs.DIM_GEO_NAME;
```
![Image](images/CountryRankingForHealthcareIndicators.png?raw=true)
