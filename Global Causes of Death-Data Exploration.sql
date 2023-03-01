USE GlobalHealth
SELECT * FROM GlobalHealth..demographic ORDER BY 1,2
SELECT * FROM GlobalHealth..[total-number-of-deaths-by-cause] 
SELECT * FROM GlobalHealth..[annual-number-of-deaths-by-cause]
SELECT * FROM GlobalHealth..[total-number-of-deaths-by-cause] ORDER BY 1,2

/*
Dataset: Global cause of death
Communicable diseases: infectious diseases caused by bacteria, viruses. example; tuberculosis, Influenza, measles, Covid-19, etc..
Noncommunicable diseases: Chronic diseases caused by combination of genetic, physiological, environmental and behavioural factors. example; heart attacks and stroke, cancers, asthma, diabetes, etc...
Injuries: results from road traffic crashes, falls, drowning, burns, acts of voiolence, etc..
*/

-- Data to work on
SELECT * FROM GlobalHealth..[total-number-of-deaths-by-cause] ORDER BY 1,2

--Shows annual number of death from causes and their sum per country, 1990 - 2019.
SELECT *, SUM([Injuries]+ [Communicable diseases]+ [Non-communicable diseases]) as TotalDeath FROM GlobalHealth..[total-number-of-deaths-by-cause]
GROUP BY Entity, Code, year, [Communicable diseases], [Non-communicable diseases], [Injuries] 

--Looking at the total number of people died from all causes in Canada each year since 2010.
SELECT Entity, year, SUM([Injuries] + [Communicable diseases] + [Non-communicable diseases]) as [Total death from all causes] FROM GlobalHealth..[total-number-of-deaths-by-cause]
WHERE Entity LIKE '%Canada%' AND year >= 2010
GROUP BY Entity, year

--Shows countries with highest rate of deaths caused by infectious diseases in 2019 compared to their population.
SELECT t.Entity, t.year, d.Population, MAX([Communicable diseases]) as [Highest rate of death cuased by infectious diseases],
ROUND((t.[Communicable diseases]/d.Population)*100,2) as [Precent of population death]
FROM GlobalHealth..[total-number-of-deaths-by-cause] t
JOIN GlobalHealth..demographic d
   ON t.Code = d.Code
   AND t.Year = d.Year
WHERE t.year = 2019 AND t.Entity NOT in ('World', 'G20', 'OECD Countries', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','South-East Asia Region (WHO)', 'East Asia & Pacific (WB)','South Asia (WB)','Western Pacific Region (WHO)', 'Region of the Americas (WHO)','World Bank High Income','Sub-Saharan Africa (WB)','African Region (WHO)','European Region (WHO)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Eastern Mediterranean Region (WHO)','World Bank Low Income','Middle East & North Africa (WB)','North America (WB)')
GROUP BY t.Entity, t.year, d.Population, [Communicable diseases]
ORDER BY [Precent of Population death] DESC

--Shows countries with highest number of execution per year. 
SELECT Entity, year, MAX([Number of executions (Amnesty International)]) as [Highest Count of Execution] FROM GlobalHealth..[annual-number-of-deaths-by-cause] 
WHERE [Number of executions (Amnesty International)] IS NOT NULL  
AND Entity NOT in ('World', 'G20', 'OECD Countries', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','South-East Asia Region (WHO)', 'East Asia & Pacific (WB)','South Asia (WB)','Western Pacific Region (WHO)', 'Region of the Americas (WHO)','World Bank High Income','Sub-Saharan Africa (WB)','African Region (WHO)','European Region (WHO)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Eastern Mediterranean Region (WHO)','World Bank Low Income','Middle East & North Africa (WB)','North America (WB)')
GROUP BY Entity, year
ORDER BY [Highest Count of Execution] DESC

--Shows total number of death caused by Chronic (Non-communicable) diseases per country, 1990 - 2019.
SELECT a.Entity, a.Year, b.Population, SUM([Non-communicable diseases]) as [Total Rate of Death Caused by Chronic Diseases], ROUND((a.[Non-communicable diseases]/b.population)*100,2) as [Precent Population Death]
FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
   ON a.Code = b.Code
   AND a.year = b.Year
WHERE a.Entity NOT in ('World', 'G20', 'OECD Countries', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','South-East Asia Region (WHO)', 'East Asia & Pacific (WB)','South Asia (WB)','Western Pacific Region (WHO)', 'Region of the Americas (WHO)','World Bank High Income','Sub-Saharan Africa (WB)','African Region (WHO)','European Region (WHO)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Eastern Mediterranean Region (WHO)','World Bank Low Income','Middle East & North Africa (WB)','North America (WB)')
GROUP BY a.Entity, a.Year, a.[Non-communicable diseases], b.Population
ORDER BY [Precent Population Death] DESC

--Shows total number of death due to Chronic diseases in the World and in WHO Regions.
SELECT Entity, Year, SUM([Non-communicable diseases]) as [Total Deaths Caused by Chronic Dieases]
FROM GlobalHealth..[total-number-of-deaths-by-cause] 
WHERE year = 2019 AND Entity in ('World','African Region (WHO)', 'Eastern Mediterranean Region (WHO)', 'European Region (WHO)', 'Region of the Americas (WHO)', 'South-East Asia Region (WHO)','Western Pacific Region (WHO)')
GROUP BY Entity, Year, [Non-communicable diseases]
ORDER BY [Total Deaths Caused by Chronic Dieases] DESC

-- Shows number of death caused by road injuries and its commulative sum over the subsequent years.
SELECT a.Entity, a.Year, a.[Road injuries]
,SUM(cast(a.[Road injuries] as int)) OVER (PARTITION BY a.Entity ORDER BY a.Entity, a.year) as [Total death by road injuries]
FROM GlobalHealth..[annual-number-of-deaths-by-cause] a

--CTE
--Looking at the precentage of population death from all causes.
USE GlobalHealth
GO 
WITH CombinedCauses as
(
SELECT a.Entity, a.Code, a.year, b.population, SUM([Communicable diseases] + [Non-communicable diseases] + [Injuries]) as [Total death from all causes]
FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
  ON a.code = b.code 
  And a.year = b.year
GROUP BY a.Entity, a.code, a.year, b.Population, a.[Communicable diseases], a.[Non-communicable diseases], a.Injuries
)
SELECT Entity, year, Population, [Total death from all causes], ROUND(([Total death from all causes]/Population)*100,2) as [Precent popualtion death] FROM CombinedCauses
GO

--Temp table.
DROP TABLE IF EXISTS #CombinedCauses
CREATE TABLE #CombinedCauses
(
Entity nvarchar(255),
Code nvarchar(255),
Year float,
Population numeric,
[Total death from all causes] numeric,
)
INSERT INTO #CombinedCauses
SELECT a.Entity, a.Code, a.year, b.population, SUM([Communicable diseases] + [Non-communicable diseases] + [Injuries]) as [Total death from all causes]
FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
  ON a.code = b.code 
  And a.year = b.year
GROUP BY a.Entity, a.code, a.year, b.Population, a.[Communicable diseases], a.[Non-communicable diseases], a.Injuries
SELECT Entity, year, Population, [Total death from all causes], ROUND(([Total death from all causes]/Population)*100,2) as [Precent popualtion death] FROM #CombinedCauses

--Store the data for visualization.
DROP VIEW IF EXISTS Visual
GO
CREATE VIEW Visual as
WITH CombinedCauses as
(
SELECT a.Entity, a.Code, a.year, b.population, SUM([Communicable diseases] + [Non-communicable diseases] + [Injuries]) as [Total death from all causes]
FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
  ON a.code = b.code 
  And a.year = b.year
GROUP BY a.Entity, a.code, a.year, b.Population, a.[Communicable diseases], a.[Non-communicable diseases], a.Injuries
)
SELECT Entity, code, year, Population, [Total death from all causes], ROUND(([Total death from all causes]/Population)*100,2) as [Precent popualtion death] FROM CombinedCauses
GO
SELECT * FROM GlobalHealth..Visual

-- Entities classified by institutions.
USE GlobalHealth
DROP VIEW IF EXISTS Classification 
GO
CREATE VIEW Classification as 
SELECT Entity, Code, Year, Population,
CASE
WHEN Entity IN ('East Asia & Pacific (WB)','South Asia (WB)','Sub-Saharan Africa (WB)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Middle East & North Africa (WB)','North America (WB)', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','World Bank High Income','World Bank Low Income') Then 'World Bank' 
WHEN Entity in ('South-East Asia Region (WHO)', 'Western Pacific Region (WHO)','Region of the Americas (WHO)','African Region (WHO)','European Region (WHO)','Eastern Mediterranean Region (WHO)') Then 'World Health Organization'
ELSE ''
END AS 'Classifying Institution'
FROM GlobalHealth..demographic
GO

select * from Visual

--Shows total death from all causes in different regions of the world classified by World Health Organization (WHO). 
SELECT a.Entity, a.code, a.year, a.Population, a.[Total death from all causes] FROM Visual a
WHERE a.Code in (SELECT b.Code FROM Classification b WHERE b.[Classifying Institution] in ('World Health Organization'))

--Looking at the World Bank classified entities with more than 1 precent of its population death.
SELECT v.Entity, v.year, v.Population, [Precent popualtion death], c.[Classifying Institution] FROM visual v
JOIN Classification c
   ON v.Code = c.Code
   AND v.Year = c.Year
GROUP BY v.Entity, c.[Classifying Institution], v.year, v.Population, v.[Precent popualtion death]
HAVING (v.[Precent popualtion death]) > 1 AND c.[Classifying Institution] in ('World Bank')


/*Data for visualization - Annual number of death by causes*/
--1-Exclude transnational entities.
SELECT a.Entity, a.Code, a.Year, b.population, a.[Communicable diseases],a.[Non-communicable diseases], a.Injuries
 FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
   ON a.code = b.code
   AND a.year = b.year
WHERE a.Entity NOT in ('G20', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','South-East Asia Region (WHO)', 'East Asia & Pacific (WB)','South Asia (WB)','Western Pacific Region (WHO)','OECD Countries','Region of the Americas (WHO)','World Bank High Income','Sub-Saharan Africa (WB)','African Region (WHO)','European Region (WHO)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Eastern Mediterranean Region (WHO)','World Bank Low Income','Middle East & North Africa (WB)','North America (WB)')
ORDER BY 1,2 

--2-Store the data to restructure.
USE GlobalHealth
DROP VIEW IF EXISTS [Cause Cateogry]
GO
CREATE VIEW [Cause Category] as
(
SELECT a.Entity, a.Code, a.Year, b.population, a.[Communicable diseases],a.[Non-communicable diseases], a.Injuries
 FROM GlobalHealth..[total-number-of-deaths-by-cause] a
JOIN GlobalHealth..demographic b
   ON a.code = b.code
   AND a.year = b.year
WHERE a.Entity NOT in ('G20', 'World Bank Lower Middle Income', 'World Bank Upper Middle Income','South-East Asia Region (WHO)', 'East Asia & Pacific (WB)','South Asia (WB)','Western Pacific Region (WHO)','OECD Countries','Region of the Americas (WHO)','World Bank High Income','Sub-Saharan Africa (WB)','African Region (WHO)','European Region (WHO)','Europe & Central Asia (WB)','Latin America & Caribbean (WB)','Eastern Mediterranean Region (WHO)','World Bank Low Income','Middle East & North Africa (WB)','North America (WB)')
)
GO
SELECT * FROM GlobalHealth..[Cause Category]

--3-Restructure dataset - Column to Row - Export to CSV for Tableau.
SELECT Entity, code, year, population, [Cause of death], [Number of death] FROM GlobalHealth..[Cause Category]
    UNPIVOT
    (
    [Number of death]
    for [Cause of death] in ([communicable diseases], [Non-communicable diseases], [injuries])
    ) U


/*Data for visualization - Number of death by age group*/
--1-Join - get the population data.
SELECT a.Entity, a.Code, a.Year, b.Population,a.[70+ years ], a.[50-69 years], a.[15-49 years], a.[5-14 years], a.[Under 5 ]
FROM GlobalHealth..[number-of-deaths-by-age-group] a
JOIN GlobalHealth..demographic b
   ON a.code = b.code
   AND a.year = b.year

--2-Store data to restructure.
USE GlobalHealth
DROP VIEW IF EXISTS Age
GO
CREATE VIEW Age as
SELECT a.Entity, a.Code, a.Year, b.Population,a.[70+ years ], a.[50-69 years], a.[15-49 years], a.[5-14 years], a.[Under 5 ]
FROM GlobalHealth..[number-of-deaths-by-age-group] a
JOIN GlobalHealth..demographic b
   ON a.code = b.code
   AND a.year = b.year
GO
--3-Restructure dataset - Column to Row - Export to CSV for Tableau.
SELECT Entity, code, year, population, AgeGroup, TotalDeath FROM Age a 
 unpivot
 (
  TotalDeath
  for AgeGroup in ([70+ years], [50-69 years], [15-49 years], [5-14 years], [Under 5])
 )U 


/*Data for visualization - Annul number of death by causes*/
--1-Restructure - Column to Row.
SELECT Entity, code, year, [Cause of death], [Number of death] FROM GlobalHealth..[annual-number-of-deaths-by-cause] 
  UNPIVOT
  (
  [Number of death] 
  for [Cause of death] in ([Meningitis], [Alzheimer's disease and other dementias], [Parkinson's disease], [Nutritional deficiencies],
    Malaria, Drowning, [Interpersonal violence], [Maternal disorders], [HIV/AIDS], [Drug use disorders], Tuberculosis, [Cardiovascular diseases],
    [Lower respiratory infections], [Neonatal disorders], [Alcohol use disorders], [Self-harm], [Exposure to forces of nature], [Diarrheal diseases], [Environmental heat and cold exposure],
    Neoplasms, [Conflict and terrorism], [Diabetes mellitus], [Chronic kidney disease], Poisonings, [Protein-energy malnutrition], [Road injuries], [Chronic respiratory diseases], [Cirrhosis and other chronic liver diseases],
    [Digestive diseases], [Fire, heat, and hot substances], [Acute hepatitis])
  )U

--2-Store data
USE GlobalHealth
DROP VIEW IF EXISTS [NumbyCause]
GO
CREATE VIEW [NumbyCause] as 
SELECT Entity, code, year, [Cause of death], [Number of death] FROM GlobalHealth..[annual-number-of-deaths-by-cause] 
  UNPIVOT
  (
  [Number of death] 
  for [Cause of death] in ([Meningitis], [Alzheimer's disease and other dementias], [Parkinson's disease], [Nutritional deficiencies],
    Malaria, Drowning, [Interpersonal violence], [Maternal disorders], [HIV/AIDS], [Drug use disorders], Tuberculosis, [Cardiovascular diseases],
    [Lower respiratory infections], [Neonatal disorders], [Alcohol use disorders], [Self-harm], [Exposure to forces of nature], [Diarrheal diseases], [Environmental heat and cold exposure],
    Neoplasms, [Conflict and terrorism], [Diabetes mellitus], [Chronic kidney disease], Poisonings, [Protein-energy malnutrition], [Road injuries], [Chronic respiratory diseases], [Cirrhosis and other chronic liver diseases],
    [Digestive diseases], [Fire, heat, and hot substances], [Acute hepatitis])
  )U
GO
SELECT * FROM NumbyCause

/*Data for visualization - Total number of death from all causes per country, 1990 - 2019 - Export to csv for Tableau*/
SELECT Entity, year, SUM([Communicable diseases] + [Non-communicable diseases] + Injuries) as Totaldeath
FROM GlobalHealth..[total-number-of-deaths-by-cause] 
GROUP BY Entity, Code, year, [Communicable diseases], [Non-communicable diseases], Injuries

/*Data for visualization - death rate per 100,000 people by causes - Export to csv for Tableau*/ 
SELECT a.Entity, a.code, a.year, b.Population, [Cause of death], [Number of death], 
ROUND(([Number of death]/Population) *1000000,0) AS DeathRate
FROM NumbyCause a
JOIN GlobalHealth..demographic b
  ON a.code = b.code 
  And a.year = b.year
GROUP BY a.Entity, a.code, a.[Year], Population, a.[Cause of death], a.[Number of death]



