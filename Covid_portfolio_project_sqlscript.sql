
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
		
		
				--United States Covid breakdown by country and Per 100 k population

DECLARE		@PopulationLimit Int
SET			@PopulationLimit = 20000
       

SELECT		TOP 25 
			cif.county AS County, 
			cif.[State],
			FORMAT(Cd.cases, 'N0') AS 'Total Cases', 
			FORMAT(cif.Population, 'N0') as Population,
			FORMAT((100000*(Cd.cases*1.0/cif.Population)),'N0') as 'Per 100K Cases'

FROM		dbo.COVIDCountyData as Cd
JOIN		dbo.CountyInfo as cif on cif.FIPS = Cd.fips
WHERE	Cd.[date] = (select MAX(ccd.[date]) FROM dbo.COVIDCountyData as ccd) 
and		cif.Population >= @PopulationLimit

Order by	 ((100000*(Cd.cases*1.0/cif.Population))) DESC


		---Creating Stored Procedure for New Deaths and New Cases--

CREATE PROCEDURE UpdateStateDaily As
Update  s
Set		NewCases = s.cases - IsNull(sp.cases, 0)


From    COVIDStateData As s
Left Join COVIDStateData As sp 
on      sp.FIPS = s.FIPS and sp.date = DATEADD(DAY, -1, s.date)

Exec    UpdateStateDaily

Drop Procedure UpdateStateDaily


-- Creating Subqueries---

Select		s.State
		,FORMAT(sd.NewCases, 'N0') as [Max New Cases]
		,CONVERT(Varchar, Cast(Date as Date), 101) as Date
		,DATENAME(WEEKDAY, sd.Date) as [Day of Week]
		,FORMAT((sd.NewCases * 1.0/s.population)*100000, 'N1') as 'Per 100k Rate'
FROM		(Select 		fips
							,date
							,NewCases
							,ROW_NUMBER() OVER(PARTITION by fips Order by NewCases DESC, date Desc) as RowNumber
				From	[dbo].[COVIDStateData]) as sd
				Join	[dbo].[StateInfo] as s on s.FIPS = sd.fips
				Where			sd.RowNumber = 1
				Order by		(sd.NewCases * 1.0/s.Population)*100000 DESC

		---- Query for per capita number of cases that are most recent (7 days) by state----

		Select s.State
	  ,FORMAT(CAST(s.population as numeric), '#,#') as Population
	  ,FORMAT(sd.[Cases Past Week], 'N0') as [Cases Past Week]
	  ,FORMAT((sd.[Cases Past Week]* 1.0/s.population)*100000, 'N1') as [Per 100k Rate]
	  ,RANK() Over( Order by (sd.[Cases Past Week]* 1.0/s.population*100000) Desc) As [Rank]
From	(Select		Fips
					,Sum(NewCases) as [Cases Past Week]
		From		COVIDStateData
	    where		date > (select Max(DateAdd(DD,-7,date )) from [dbo].[COVIDStateData])
		Group by	FIPS) As SD
Join	[dbo].[StateInfo] as s on s.fips = sd.fips
Group by s.state,s.population, sd.[Cases Past Week]
Order by  State  Asc

         ---- Query for per capita number of cases that are most recent (7 days) by state---

		 Select s.State
	  ,FORMAT(CAST(s.population as numeric), '#,#') as Population
	  ,FORMAT(sd.[Deaths Past Week], 'N0') as [Deaths Past Week]
	  ,FORMAT((sd.[Deaths Past Week]* 1.0/s.population)*100000, 'N1') as [Per 100k Rate]
	  ,RANK() Over( Order by (sd.[Deaths Past Week]* 1.0/s.population*100000) Desc) As [Rank]
From	(Select		Fips
					,Sum(NewDeaths) as [Deaths Past Week]
		From		COVIDStateData
	    where		date > (select Max(DateAdd(DD,-7,date )) from [dbo].[COVIDStateData])
		Group by	FIPS) As SD
Join	[dbo].[StateInfo] as s on s.fips = sd.fips
Group by s.state,s.population, sd.[Deaths Past Week]
Order by  sd.[Deaths Past Week]* 1.0/s.population*100000  DESC

		
		
		
		
