
Select * From [CovidPortfolioProject ]..CovidDeaths
where continent is not null
		order by 3,4

Select * From [CovidPortfolioProject ]..CovidVaccinations
		order by 3,4

-- Selecting Data to use-- 
Select location, date, total_cases, new_cases, total_deaths, population
		From [CovidPortfolioProject ]..CovidDeaths
		order by 1,2

--Total Cases Vs Total Deaths --
--Shows liklihood of dying as respective to country--
Select location, date,total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
		From [CovidPortfolioProject ]..CovidDeaths
		where location = 'United States'
		order by 1,2

--Total cases vs Population--
--Shows the percentage of population contracted COVID--
Select location, date,population,total_cases,  (total_cases/population)*100 as PopulationPercentage
		From [CovidPortfolioProject ]..CovidDeaths
		where location = 'United States'
		order by 1,2

--Countries with highest infection rates compared to population-- 

Select	location, 
		population,
		Max(total_cases) as Highestinfectioncount,  
		Max((total_cases/population))*100 as PopulationPercentageInfected
From [CovidPortfolioProject ]..CovidDeaths
		--where location = 'United States'
		group by location, population
		order by PopulationPercentageInfected desc

-- countries with highest death count per population --
--BREAKING THINGS DOWN BY CONTINENT--

Select	location,
		Max(cast(total_deaths as int)) as deathcount 
From [CovidPortfolioProject ]..CovidDeaths
		where continent is null
		group by location
		order by deathcount desc

-- Showing continents with highest death count--

Select	continent,
		Max(cast(total_deaths as int)) as deathcount 
From [CovidPortfolioProject ]..CovidDeaths
		where continent is not null
		group by continent
		order by deathcount desc

--- GLOBAL NUMBERS---

Select      SUM(new_cases) as totalcases,
			SUM(cast(new_deaths as int)) as totaldeaths,
			sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
	From [CovidPortfolioProject ]..CovidDeaths
		--where location = 'United States'
		Where continent is not null
		--group by date 
		order by 1,2

---Looking for Total population vs vaccinations

Select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		sum(cast( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated
From CovidDeaths dea
		join CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		order by 2,3


--USING CTES

WITH popvsvac (continent, location, date, population,new_vaccinations, Rollingpeoplevaccinated)
 as (

 Select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		sum(cast( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated
From CovidDeaths dea
		join CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		--order by 2,3
)

Select *, (Rollingpeoplevaccinated/population)*100 from popvsvac

--USING TEMP TABLES

Drop table if exists #Percentpopulationvaccinated 
create table #Percentpopulationvaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	Rollingpeoplevaccinated numeric
)
 Insert INTO #Percentpopulationvaccinated
 Select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		sum(cast( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated
From CovidDeaths dea
		join CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null

Select *, (Rollingpeoplevaccinated/population)*100 from #Percentpopulationvaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW Percentpopulationvaccinated as 
Select	dea.continent, 
		dea.location, 
		dea.date, 
		dea.population,
		vac.new_vaccinations,
		sum(cast( vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location, dea.date) as Rollingpeoplevaccinated
From CovidDeaths dea
		join CovidVaccinations vac
		on dea.location = vac.location
		and dea.date = vac.date
		where dea.continent is not null
		--order by 2,3
		
		
		
		
