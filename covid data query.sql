select * from ['covid-deaths$']
where continent is not null
order by 3,4 --column no.s starting from 1

--select * from ['covid-vaccination$']
--order by 3,4

--select data that we r going to use

select location,date,total_cases,new_cases,total_deaths, population 
from ['covid-deaths$']
order by 1,2

-- total cases vs total deaths (Death Percentage)

select location,date,total_cases,new_cases,total_deaths,(total_deaths/total_cases)*100 as [Death Percentage]
from ['covid-deaths$'] --ceiling for round off to nearest integer = {ceiling((total_deaths/total_cases)*100) as [Death Percentage]}
where continent is not null
--where location like '%india%'
order by 1,2

--Total cases vs Population (Infected percentage)

select location,date,population,total_cases,(total_cases/population)*100 as [Infected Percentage]
from ['covid-deaths$']
where continent is not null--CEILING((total_cases/population)*100) as [Infected Percentage]
--where location = 'india'and continent is not null --Joining two conditions
order by 1,2

--select location,date,population,total_cases,total_deaths, (total_cases/population)*100 as InfectedPercentage, (total_deaths/total_cases)*100 as DeathPercentage
--from ['covid-deaths$']
--where location = 'india'
--order by 1,2

--Countries with highest infection rates wrt to population

select location,population,max(total_cases)as [Total Cases],max((total_cases/population)*100 )as [High Infection Rate]
from ['covid-deaths$']
where continent is not null
group by location,population --group countries based on population into individual bins specifying high infection rate
order by [High Infection Rate] desc

--[High Infection Rate] date wise

select location,population,date,max(total_cases)as [Total Cases],max((total_cases/population)*100 )as [High Infection Rate]
from ['covid-deaths$']
where continent is not null
group by location,population,date --group countries based on population into individual bins specifying high infection rate
order by [High Infection Rate] desc

--Countries with highest death rate wrt to Population

--select location,population,max(total_cases) as [Total Cases],max(total_deaths) as [Total Deaths],max((total_deaths/population)*100 )as [High Death Rate]
--from ['covid-deaths$']
--where continent is not null --to avoid data falsification i.e. if continent is null then in country column continents are present i.e data for entire continent
--group by location,population
--order by [High Death Rate] desc

--Countries with highest count wrt to Population

select location,max(cast(total_deaths as int)) as [Total Death Count] --change data type into int for better computation as it takes as other data type
from ['covid-deaths$']
where continent is not null
group by location 
order by [Total Death Count] desc


--Data in terms of Continent
-- highest death count in continents
--excluding European union as data is in europe column, international,world

select location,max(cast(total_deaths as int)) as [Total Death Count] --change data type into int for better computation as it takes as other data type
from ['covid-deaths$']
where continent is null and location not in ('World','European Union','International','Upper middle income','High income','Lower middle income','Low income')
group by location 
order by [Total Death Count] desc

--or based on continent column
--select continent,max(cast(total_deaths as int)) as [Total Death Count] --change data type into int for better computation as it takes as other data type
--from ['covid-deaths$']
--where continent is not null
--group by continent
--order by [Total Death Count] desc


--Global Numbers

select sum(new_cases)as [Total new cases],sum(cast(new_deaths as int)) as [Total new deaths],sum(cast(new_deaths as int))/SUM(new_cases)*100 as [death percentage]
from ['covid-deaths$']
where continent is not null



--Joins

select *
from ['covid-deaths$'] 
join ['covid-vaccination$'] 
on ['covid-deaths$'].location =['covid-vaccination$'].location and ['covid-deaths$'].date = ['covid-vaccination$'].date


--Total Vaccinations vs Total population

select ['covid-deaths$'].continent,['covid-deaths$'].location,['covid-deaths$'].date,['covid-deaths$'].population, ['covid-vaccination$'].new_vaccinations
from ['covid-deaths$'] 
join ['covid-vaccination$'] --join to get vaccinations dataset
on ['covid-deaths$'].location =['covid-vaccination$'].location and ['covid-deaths$'].date = ['covid-vaccination$'].date
where ['covid-deaths$'].continent is not null
order by 2,3


--cumulative new vaccinations based on continent,location,date

select ['covid-deaths$'].continent,['covid-deaths$'].location,['covid-deaths$'].date,['covid-deaths$'].population, ['covid-vaccination$'].new_vaccinations,
SUM(cast(['covid-vaccination$'].new_vaccinations as bigint)) over (partition by ['covid-deaths$'].location order by ['covid-deaths$'].location, 
['covid-deaths$'].date) as [Cumulaitve Vaccinated People] --do sum based on partition of location and that too in an asc order based on date & location
from ['covid-deaths$'] 
join ['covid-vaccination$'] --join to get vaccinations dataset
on ['covid-deaths$'].location =['covid-vaccination$'].location and ['covid-deaths$'].date = ['covid-vaccination$'].date
where ['covid-deaths$'].continent is not null
order by 2,3

--Use CTE

with vaccinated (continent,location,date,population,new_vaccinations,[Cumulative Vaccinated People])
as

(select ['covid-deaths$'].continent,['covid-deaths$'].location,['covid-deaths$'].date,['covid-deaths$'].population, ['covid-vaccination$'].new_vaccinations,
SUM(convert(bigint,['covid-vaccination$'].new_vaccinations)) over (partition by ['covid-deaths$'].location order by ['covid-deaths$'].location, 
['covid-deaths$'].date) as [Cumulative Vaccinated People] --do sum based on partition of location and that too in an asc order based on date & location
from ['covid-deaths$'] 
join ['covid-vaccination$'] --join to get vaccinations dataset
on ['covid-deaths$'].location =['covid-vaccination$'].location 
and ['covid-deaths$'].date = ['covid-vaccination$'].date
where ['covid-deaths$'].continent is not null
)
select *, ([Cumulative Vaccinated People]/population)*100 as vaccinatedpercentage
from vaccinated


--or 
--use TEMP TABLE
drop table if exists #percentvaccinated
create table #percentvaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations integer,
[Cumulative Vaccinated People] numeric)

insert into #percentvaccinated
select ['covid-deaths$'].continent,['covid-deaths$'].location,['covid-deaths$'].date,['covid-deaths$'].population, ['covid-vaccination$'].new_vaccinations,
SUM(convert(bigint,['covid-vaccination$'].new_vaccinations)) over (partition by ['covid-deaths$'].location order by ['covid-deaths$'].location, 
['covid-deaths$'].date) as [Cumulative Vaccinated People] --do sum based on partition of location and that too in an asc order based on date & location
from ['covid-deaths$'] 
join ['covid-vaccination$'] --join to get vaccinations dataset
on ['covid-deaths$'].location =['covid-vaccination$'].location 
and ['covid-deaths$'].date = ['covid-vaccination$'].date
where ['covid-deaths$'].continent is not null
order by 1,2

select *,([Cumulative Vaccinated People]/population)*100 
from #percentvaccinated

