-- Looking data of the table
Select *
From PortfolioDb.dbo.covidDeaths

Select * 
From PortfolioDb.dbo.covidVaccination

-- Select data we are starting with
Select  
	Location, 
	date, 
	population, 
	new_cases, 
	Total_cases, 
	Total_deaths
From 
	PortfolioDb.dbo.covidDeaths
Where 
	Continent is not Null
Order by 1,2

-- Total Cases vs Total Deaths
Select 
	Location, 
	Date, 
	Total_cases, 
	Total_deaths, 
	(convert(float, total_deaths)/convert(float,total_cases))*100 as DeathPercentage
From 
	PortfolioDb.dbo.covidDeaths
Where
	Location like '%states%'
order by 1,2

-- -- Total cases vs Population
-- Shows what percentage of Population infected with Covid
Select
	Location,
	Date,
	Total_cases,
	(Total_cases/Population)*100 as PercentPopulationInfected
From
	PortfolioDb.dbo.covidDeaths
Where
	Total_cases is not Null
Order by 1,2

-- Countries with Highest Infection Rate compared to Population
Select 
	Location, 
	Population, 
	Max(Total_cases) as HighestInfectionCount,
	Max((Total_cases/Population))*100 as PercentPopulationInfected
From
	PortfolioDb.dbo.covidDeaths
Group by 
	Location, Population
Order by 
	PercentPopulationInfected Desc

-- Countries with Highest Death Count per Population
Select 
	Location, 
	MAX(cast(Total_deaths as int)) as TotalDeathCount
From 
	PortfolioDb.dbo.covidDeaths
Where 
	continent is not null 
Group by 
	Location
order by 
	TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population

Select 
	continent, 
	MAX(cast(Total_deaths as int)) as TotalDeathCount
From 
	PortfolioDb.dbo.covidDeaths
Where 
	continent is not null 
Group by 
	continent
order by 
	TotalDeathCount desc

-- Global Numbers
Select 
	Sum(new_cases) as total_cases, 
	Sum(cast(new_deaths as int)) as Total_deaths,
		CASE 
			When 
				Sum(new_cases) = 0 
				Then 0
			Else 
				Sum(cast(new_deaths as int))/Sum(new_cases)*100 
		ENd as DeathPercentage
From 
	PortfolioDb.dbo.covidDeaths
Where 
	continent is not null
order by 1,2


-- Join two table
Select * 
From 
	PortfolioDb.dbo.covidDeaths as Dea
Join 
	PortfolioDb.dbo.covidVaccination as Vac
	On Dea.location = Vac.location
	And 
	Dea.date = Vac.date

-- Looking at Total Population vs Vaccinations

Select 
	dea.continent, 
	dea.location, 
	dea.date, dea.population, 
	vac.new_vaccinations, 

	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER 
	(Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
From 
	PortfolioDb.dbo.covidDeaths as dea
Join 
	PortfolioDb.dbo.covidVaccination as vac
	on dea.location = vac.location
	and
	dea.date = vac.date
Where 
	dea.continent is not null
order by 
	2,3

With PopvsVac 
	(Continent, 
		Location, 
		Date, 
		Population, 
		New_vaccinations, 
		RollingPeopleVaccinated)
as
(
Select 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations, 
	SUM(CONVERT(int, vac.new_vaccinations)) 
	OVER (Partition by dea.Location order by dea.location, dea.Date) as RollingPeopleVaccinated
From 
	PortfolioDb.dbo.covidDeaths as dea
Join 
	PortfolioDb.dbo.covidVaccination as vac
	on dea.location = vac.location
	and 
	dea.date = vac.date
Where 
dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM
    PortfolioDb.dbo.CovidDeaths dea
JOIN
    PortfolioDb.dbo.covidVaccination vac ON dea.location = vac.location AND dea.date = vac.date;

SELECT *,
       (RollingPeopleVaccinated / Population) * 100
FROM
    #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated 
as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioDb.dbo.CovidDeaths dea
Join PortfolioDb.dbo.covidVaccination vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select * from PercentPopulationVaccinated