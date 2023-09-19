select * --location,date,total_cases, new_cases,total_deaths ,population
from PortfolioProject..covid_deaths$ 
WHERE continent is not null 
ORDER BY 1,2

/*
SELECT location,
	CASE 
		WHEN total_cases IS NOT NULL THEN 
		SUM(CAST (total_cases as INT))  /*,SUM(total_deaths)as total_deaths_in_country */
	END total_cases_in_country
from PortfolioProject..covid_deaths$ 
GROUP BY location
ORDER BY 1
*/

alter table PortfolioProject..covid_deaths$ alter column total_cases numeric
alter table PortfolioProject..covid_deaths$ alter column total_deaths numeric

-- likelihood of dying 
select location,date,total_cases,total_deaths,(total_deaths/total_cases) as death_ratio
from PortfolioProject..covid_deaths$ 
where location like '%unisia%'and continent is not null 

ORDER BY 1,2

-- highest infection percentage
select 
	location,
	MAX(total_cases) as total_cases,
	MAX((total_cases/population))*100 as infection_percentage 
from PortfolioProject..covid_deaths$ 
WHERE continent is not null 
GROUP BY location
ORDER BY infection_percentage desc

-- highest death count per population 
select 
	location,
	population,
	MAX(total_deaths) as total_deaths,
	MAX((total_deaths/population))*100 as death_per_population 
from PortfolioProject..covid_deaths$ 
WHERE continent is not null 
GROUP BY location,population
ORDER BY death_per_population desc

-- highest death count per population group by continent  (RESULTS ARE WRONG HERE -> CHECK IT LATER!!!)
select 
	continent,
	MAX(total_deaths) as total_deaths,
	MAX((total_deaths/population))*100 as death_per_population 
from PortfolioProject..covid_deaths$ 
WHERE continent is not null 
GROUP BY continent
ORDER BY death_per_population desc

-- highest death count per population group by continent  (RIGHT WAY)
select 
	location,
	MAX(total_deaths) as total_deaths,
	MAX((total_deaths/population))*100 as death_per_population 
from PortfolioProject..covid_deaths$ 
WHERE continent is null -- FITER ONLY ROWS CONCERNING CONTINENT  
GROUP BY location
ORDER BY death_per_population desc
---- highest death count in united states
select 
	location,
	population,
	MAX(total_deaths) as total_deaths,
	MAX((total_deaths/population))*100 as death_per_population 
from PortfolioProject..covid_deaths$ 
WHERE continent is not null and location like'%states%'
GROUP BY location,population
ORDER BY death_per_population desc

-- global figures 
---- comparing new deaths and new cases per day
select date
, SUM(new_cases) as new_cases
, SUM(cast(new_deaths as int))as new_deaths 
, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_per_case_percentage
from PortfolioProject..covid_deaths$ 
WHERE continent is not null and new_cases> 0
GROUP BY date 
ORDER BY 1


alter table PortfolioProject..covid_vaccinations$ alter column new_vaccinations numeric
alter table PortfolioProject..covid_vaccinations$ alter column total_vaccinations numeric

-- daily Vaccination rate  
select 
	dea.continent,
	dea.location,
	dea.date,
	new_vaccinations, 
	total_vaccinations,
	--population,
	new_vaccinations/total_vaccinations*100 as vaccinated_percenatge
from PortfolioProject..covid_deaths$ dea
Join PortfolioProject..covid_vaccinations$ vac
	ON  dea.location = vac.location
	and dea.date= vac.date 
WHERE total_vaccinations>0 and dea.continent is not null
ORDER BY 1,2,3

--- total population vs vaccination 

-- USE CTE for total population vs vaccination
With POPvsVAC (continent,location,date,population,new_vaccinations,rolling_people_vaccinated)
as(
select 
	dea.continent,
	dea.location,
	dea.date,
	population,
	new_vaccinations, 
	SUM(new_vaccinations/population) OVER (Partition by dea.location,dea.date) as rolling_vaccinated_people
from PortfolioProject..covid_deaths$ dea
Join PortfolioProject..covid_vaccinations$ vac
	ON  dea.location = vac.location
	and dea.date= vac.date 
WHERE total_vaccinations>0 and dea.continent is not null
)
select* ,(rolling_people_vaccinated/population)*100 as vacination_percentage 
from POPvsVAC

-- USE TEMP TABLE for total population vs vaccination
DROP TABLE if exists #tempPOPvsVAC
CREATE TABLE #tempPOPvsVAC
(
continent nvarchar(225),
location nvarchar(225),
date datetime,
population numeric,
new_vaccinations numeric , 
rolling_people_vaccinated numeric
)
Insert into #tempPOPvsVAC
select 
	dea.continent,
	dea.location,
	dea.date,
	population,
	new_vaccinations, 
	SUM(new_vaccinations/population) OVER (Partition by dea.location,dea.date) as rolling_vaccinated_people
from PortfolioProject..covid_deaths$ dea
Join PortfolioProject..covid_vaccinations$ vac
	ON  dea.location = vac.location
	and dea.date= vac.date 
WHERE total_vaccinations>0 and dea.continent is not null


select* ,(rolling_people_vaccinated/population)*100 as vacination_percentage 
from #tempPOPvsVAC

--Create View for later visualization in Tableau 
CREATE View VaccinatedPopulationPercentage as
select 
	dea.continent,
	dea.location,
	dea.date,
	population,
	new_vaccinations, 
	SUM(new_vaccinations/population) OVER (Partition by dea.location,dea.date) as rolling_vaccinated_people
from PortfolioProject..covid_deaths$ dea
Join PortfolioProject..covid_vaccinations$ vac
	ON  dea.location = vac.location
	and dea.date= vac.date 
WHERE total_vaccinations>0 and dea.continent is not null

select * from VaccinatedPopulationPercentage