SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM public.covid_death
ORDER BY 1, 2

-- Total cases Vs Total deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths::numeric/total_cases *100) AS death_percentage
FROM public.covid_death
WHERE location like '%ndia%'
ORDER BY 1, 2

-- Total cases Vs Population

SELECT Location, date, population, total_cases, (total_cases::numeric/population *100) AS Percent_Population_Infected
FROM public.covid_death
WHERE location like '%ndia%'
ORDER BY 1, 2

-- Countries with Highest Infection Rate compared to Population

SELECT Location, population, MAX(total_cases) AS Highest_Infection_count, MAX((total_cases::numeric/population))*100 AS Percent_Population_Infected
FROM public.covid_death
-- WHERE location like '%ndia%'
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC NULLS LAST

-- Countries with Highest Death Count per Population

SELECT Location, MAX(total_deaths) AS Highest_deaths_count, MAX((total_deaths::numeric/population))*100 AS dead_as_per_population
FROM public.covid_death
-- WHERE location like '%ndia%'
GROUP BY location
ORDER BY dead_as_per_population DESC NULLS LAST

-- Continent with Highest Death Count per Population

SELECT continent, MAX(total_deaths) AS Highest_deaths_count, MAX((total_deaths::numeric/population))*100 AS dead_as_per_population
FROM public.covid_death
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY dead_as_per_population DESC NULLS LAST

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths::numeric)/SUM(new_cases) *100) AS death_percentage
FROM public.covid_death
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent , dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(dea.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
FROM public.covid_death dea
JOIN public.covid_vaccination vac
ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Using CTE to perform Calculation on Partition By in previous query

WITH PopVsVacc (continent, location, date, population, new_vaccinations, Rolling_People_Vaccinated)
AS
	(SELECT dea.continent , dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
	FROM public.covid_death dea
	JOIN public.covid_vaccination vac
	ON dea.location = vac.location
	   AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL)
--ORDER BY 2, 3

SELECT * , (Rolling_People_Vaccinated/Population) * 100 as Rate_of_people_vaccinated_daily
FROM PopVsVacc

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated
CREATE TEMPORARY TABLE PercentPopulationVaccinated
(
Continent varchar(35),
location varchar(35),
Date date,
Population double precision,
New_vaccinations integer,
Rolling_People_Vaccinated double precision
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent , dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
	FROM public.covid_death dea
	JOIN public.covid_vaccination vac
	ON dea.location = vac.location
	   AND dea.date = vac.date

SELECT *, Rolling_People_Vaccinated/Population * 100 AS Percent_Population_Vaccinated
FROM PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
SELECT dea.continent , dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS Rolling_People_Vaccinated
	FROM public.covid_death dea
	JOIN public.covid_vaccination vac
	ON dea.location = vac.location
	   AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL