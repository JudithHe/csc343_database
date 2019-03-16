SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov."q5" CASCADE;
DROP VIEW IF EXISTS parlgov.ExistElection CASCADE;
DROP VIEW IF EXISTS parlgov.ParRatioPerElec CASCADE;
DROP VIEW IF EXISTS parlgov.PartiRatioPerCounPerYear CASCADE;
DROP VIEW IF EXISTS parlgov.notNonDescCountry CASCADE;
DROP VIEW IF EXISTS parlgov.NonDescCountry CASCADE;
DROP VIEW IF EXISTS parlgov.Answer CASCADE;

CREATE TABLE q5(
countryName VARCHAR(50) not NULL,
year INT not NULL,
participationRatio REAL
--check(year >= 2001 and year <= 2016)
--check(participationRate >= 0.0 and participationRate <= 1.0)
);


-- First: Find countries that have elections between 2001-2016.
 CREATE View ExistElection AS 
 select country_id , EXTRACT(YEAR FROM e_date) As year
 from election
 where  EXTRACT(YEAR FROM e_date) >= 2001 and EXTRACT(YEAR FROM e_date) <= 2016;

--Seco: Find the countries whose average election partipation ratios during these years are monotonically non-decreasing

--For each election between 2001 and 2016, find the participation ratio
CREATE View ParRatioPerElec As
select id, country_id, EXTRACT(YEAR FROM e_date) As year, CAST(votes_cast as float)/electorate As PartiRatio
from election
where country_id in (select distinct country_id from ExistElection) and EXTRACT(YEAR FROM e_date) >= 2001 and EXTRACT(YEAR FROM e_date) <= 2016;

--Find the average participation ratio for a country in a year within the time constraint
CREATE View PartiRatioPerCounPerYear As
select country_id, year, AVG(PartiRatio) As aver_parti_ratio
from ParRatioPerElec
group by country_id, year;

---Find the countries whose average election partipation ratios during these years are not monotonically non-decreasing
CREATE View notNonDescCountry As
select e1.country_id As country_id
from PartiRatioPerCounPerYear e1, PartiRatioPerCounPerYear e2  --self join
where e1.country_id = e2.country_id and e1.year < e2.year and e1.aver_parti_ratio > e2.aver_parti_ratio;

--Find the countries whose average election partipation ratios during these years are monotonically non-decreasing
--CREATE View NonDescCountry As
--select e1.country_id As country_id
--from PartiRatioPerCounPerYear e1, PartiRatioPerCounPerYear e2  --self join
--where e1.country_id = e2.country_id and e1.year < e2.year and e1.aver_parti_ratio <= e2.aver_parti_ratio;

---Find the countries whose average election partipation ratios during these years are monotonically non-decreasing
CREATE View NonDescCountry As
select country_id, year, aver_parti_ratio
from PartiRatioPerCounPerYear  --self join
where country_id not in (SELECT * FROM notNonDescCountry);

--Find the info we need form PartiRatioPerCounPerYear
--CREATE View Result As 
--select country_id, year, aver_parti_ratio
--from PartiRatioPerCounPerYear
--where country_id in (select * from NonDescCountry);
 
--Find the country name for the countries satisfying requirements
CREATE View Answer As 
select name As countryName, year, aver_parti_ratio As participationRatio
from NonDescCountry, country
where country_id = id;

--Finally : Insert into the final table.
INSERT INTO "q5"(countryName, year, participationRatio)
(SELECT *
FROM Answer);



