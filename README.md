# World Health Statistics
### SQL data analysis project  
This project uses World Health Statistics data from [World Health Organization website](https://www.who.int/data/gho/publications/world-health-statistics/).  
It also uses a github dataset that maps countries to regions: [Dataset](https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/blob/master/all/all.csv)  

First some simple query to find an average percent of overweight children was executed: 
```sql
SELECT hs.DIM_GEO_NAME, hs.VALUE_NUMERIC
FROM who.health_statistics as hs
WHERE hs.IND_NAME = 'Prevalence of overweight in children under 5 (%)' 
AND hs.DIM_GEO_NAME LIKE '%region%'
ORDER BY hs.VALUE_NUMERIC DESC;
```
![Image](images/OverweightChildren.png?raw=true)  
We can see that Americas have the highest percentage of overweight children.  

Next we've analyzed how the obesity rates change with age: 
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

Next we created a query to compare male vs female life expectancy: ![Image](images/MenVsWomenLifeExpectancy.png?raw=true) It is known that women on average live longer and the data proves it in majority of the countries.  

Next some queries were performed to investigate validity of the data and compare region level data averages from original dataset with similar averages when region average is done using a helper mapping dataset (country to region mapping).  
![Image](images/AverageFemaleLifeExpectancyRegionBasedOnBuiltInData.png?raw=true)
![Image](images/AverageFemaleLifeExpectancyRegionBasedOnMapping.png?raw=true)
We can see that there is not a perfect match between regional data in WHO table compared to averaging based on country to region mapping.
For Africa, numbers are close: 64.46 compared to 64.89.
For Europe, 77.9 compared to 79.32.
There might be some discrepancies though as to which country is mapped to what region.

Next we used window functions to show country rankings for a subset of healthcare quality indicators: ![Image](images/CountryRankingForHealthcareIndicators.png?raw=true)
