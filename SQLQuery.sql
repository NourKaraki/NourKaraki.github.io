/* 
Covid-19 Data Exploration
Skills used: Joins, CTE's, Temp Tables, Window Functions, Creating Views, Converting Data Types
*/

-- SELECT covid_death table
SELECT *
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY location;

-- SELECT covid_vaccinations table
SELECT *
FROM PortfolioProject..covid_vaccinations
ORDER BY location;

-- SELECT data needed to start
SELECT location, 
       date, 
       total_cases, 
       new_cases, 
       total_deaths, 
       population
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs total deaths
-- Shows the likelihood of dying if you get covid in your country
SELECT location, 
       date, 
       total_cases,
       total_deaths, 
       ROUND((total_deaths / total_cases)*100, 2) AS death_percentage
FROM PortfolioProject..covid_deaths
WHERE location LIKE '%germany%'
AND continent IS NOT NULL
ORDER BY location, date;

-- Total cases vs population
-- Shows what percentage of population got covid
SELECT location, 
       date, 
       population, 
       total_cases, 
       ROUND((total_cases / population)*100, 2) AS infected_pop_percentage
FROM PortfolioProject..covid_deaths
WHERE location LIKE '%germany%'
AND continent IS NOT NULL
ORDER BY location, date;

-- Countries with highest infection rate compared to the population
SELECT location, 
       population, 
       MAX(total_cases) AS highest_infection_rate , 
       ROUND(MAX(total_cases / population)*100, 2) AS infected_pop_percentage
FROM PortfolioProject..covid_deaths
GROUP BY location, population
ORDER BY infected_pop_percentage DESC;

-- Countries with the highest death count per population
SELECT location, 
       MAX(cast(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Continents with the highest death count
SELECT continent, 
       MAX(cast(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

-- Global numbers
SELECT date, 
  SUM(new_cases) AS total_cases, 
  SUM(CAST(new_deaths AS INT)) AS total_deaths, 
  ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases)*100, 2) AS death_percentage
FROM PortfolioProject..covid_deaths
where continent IS NOT NULL
GROUP BY date
ORDER BY date;

-- Total population vs vaccinations
-- Percentage of population that has recieved at least one covid vaccine
SELECT d.continent, 
       d.location, 
       d.date, 
       d.population, 
       v.new_vaccinations,
       SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_people
FROM PortfolioProject..covid_deaths AS d
JOIN PortfolioProject..covid_vaccinations AS v
  ON d.location = v.location
  AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY location, date;

-- CTE to perform calculation on PARTITION BY in previous query
WITH pop_vs_vac 
(continent, location, date, population, new_vaccinations, rolling_vaccinated_people)
AS 
(SELECT d.continent, 
        d.location, 
	d.date, 
	d.population, 
	v.new_vaccinations,
	SUM(CONVERT(INT, v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_people
FROM PortfolioProject..covid_deaths AS d
JOIN PortfolioProject..covid_vaccinations AS v
  ON d.location = v.location
  AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT *, ROUND((rolling_vaccinated_people / population * 100), 2) 
FROM pop_vs_vac;

-- Temp Table to perform calculation on PARTITION BY in previous query
DROP TABLE IF exists percent_population_vaccinated
CREATE TABLE percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinated_people numeric
)

INSERT INTO percent_population_vaccinated
Select d.continent, 
       d.location, 
       d.date, 
       d.population, 
       v.new_vaccinations,
       SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_people
From PortfolioProject..covid_deaths AS d
Join PortfolioProject..covid_vaccinations AS v
	On d.location = v.location
	AND d.date = v.date

Select *, (rolling_vaccinated_people / population)*100
From percent_population_vaccinated;

--Create view to store data for later visualization 
CREATE VIEW percent_population_vaccinated_ AS
Select d.continent, 
       d.location,
       d.date, 
       d.population, 
       v.new_vaccinations,
       SUM(CONVERT(INT,v.new_vaccinations)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_vaccinated_people
From PortfolioProject..covid_deaths AS d
Join PortfolioProject..covid_vaccinations AS v
	On d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *
FROM percent_population_vaccinated_;
