--Data we are Going to use

select * from dbo.['owid-covid-data$']
select * from dbo.CovidVaccination$
--Looking for total cases vs total deaths in india

select date,total_cases,total_deaths,population,(total_deaths/total_cases)*100 as DeathPercentage from dbo.['owid-covid-data$']
where location='india'
order by date Desc;

--looking total case vs total population in india

select date,total_cases,population,(total_cases/population)*100 as Infectionpercentage from dbo.['owid-covid-data$']
where location='india'
order by date Desc;

--looking countries with highest Infection rate Compare population
select location,population, max(cast(total_cases As int))as CountryWiseInfectioncount,Max(total_cases/population)*100 as Infectionpercentage from dbo.['owid-covid-data$']
group by population,location
order by Infectionpercentage desc;

--looking countries with highest death count per population
select location,max(cast(total_deaths as int)) as TotalDeathCount from dbo.['owid-covid-data$']
where continent is not null
group by location
order by TotalDeathCount desc;

--looking continent with highest death count per population
select continent,MAX(cast(total_deaths as int)) as totalDeathCount from dbo.['owid-covid-data$']
where continent is not null
Group by continent
order by totalDeathCount desc;

--Global Numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From dbo.['owid-covid-data$']
where continent is not null 
order by 1,2

--Looking the numbers of total vaccination in india
select dea.date, dea.continent,dea.location, dea.population,vac.new_vaccinations from dbo.['owid-covid-data$'] dea join
dbo.CovidVaccination$ vac on  dea.date=vac.date
and dea.location=vac.location
where dea.location='India'

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, cast(dea.population as bigint), cast(vac.new_vaccinations as bigint)
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.['owid-covid-data$'] dea
Join dbo.CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.['owid-covid-data$'] dea
Join dbo.CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationvac
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From dbo.['owid-covid-data$'] dea
Join dbo.CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View
PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From dbo.['owid-covid-data$'] dea
Join dbo.CovidVaccination$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null


