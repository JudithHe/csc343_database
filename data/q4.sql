SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov."q4" CASCADE;
DROP VIEW IF EXISTS parlgov.election_date CASCADE;
DROP VIEW IF EXISTS parlgov.election_last_20 CASCADE;
DROP VIEW IF EXISTS parlgov.election_percent_votes CASCADE;
DROP VIEW IF EXISTS parlgov.election_percent_votes_avg CASCADE;
DROP VIEW IF EXISTS parlgov.range_0_to_5 CASCADE;
DROP VIEW IF EXISTS parlgov.range_5_to_10 CASCADE;
DROP VIEW IF EXISTS parlgov.range_10_to_20 CASCADE;
DROP VIEW IF EXISTS parlgov.range_20_to_30 CASCADE;
DROP VIEW IF EXISTS parlgov.range_30_to_40 CASCADE;
DROP VIEW IF EXISTS parlgov.range_40_to_100 CASCADE;
DROP VIEW IF EXISTS parlgov.election_ranges CASCADE;

CREATE TABLE "q4"(
year INT,
countryName VARCHAR(50),
voteRange VARCHAR(8),
partyName VARCHAR(100),
UNIQUE(year, countryName, partyName)
);

--FIRST: finding the elections between 1996 and 2016 inclusive.

--Left Joining election_result and election for the year of each election.
CREATE VIEW election_date AS
SELECT e.election_id, e.party_id, e.votes, d.votes_valid, EXTRACT(YEAR from d.e_date) AS year
FROM election_result AS e LEFT JOIN election AS d
ON e.election_id = d.id
WHERE e.votes IS NOT NULL and d.votes_valid IS NOT NULL;

--Find the elections that took place between 1996 and 2016 inclusive.
CREATE VIEW election_last_20 AS
SELECT election_id, party_id, votes, votes_valid, year
FROM election_date
WHERE year >= 1996 and year <= 2016
ORDER BY party_id, year;

--SECOND: finding the distinct percent of valid votes for each party in a given year.

--Find the percent of valid of votes for each party in a given year.
CREATE VIEW election_percent_votes AS
SELECT party_id, (100*(CAST(votes AS float))/votes_valid) AS percentage, year
FROM election_last_20
ORDER BY party_id, year;

--Find the average percent of valid votes for each party in a given year.
CREATE VIEW election_percent_votes_avg AS
SELECT party_id, AVG(percentage) AS avg_percentage, year
FROM election_percent_votes
GROUP BY party_id, year;

--THIRD: finding the ranges each party's percent of valid votes belongs to.

--Find views with percentages between 0 exclusive and 5 inclusive.
CREATE VIEW range_0_to_5 AS
SELECT party_id, CAST('(0-5]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 0 AND avg_percentage <= 5;

--Find views with percentages between 5 exclusive and 10 inclusive.
CREATE VIEW range_5_to_10 AS
SELECT party_id, CAST('(5-10]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 5 AND avg_percentage <= 10;

--Find views with percentages between 10 exclusive and 20 inclusive.
CREATE VIEW range_10_to_20 AS
SELECT party_id, CAST('(10-20]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 10 AND avg_percentage <= 20;

--Find views with percentages between 20 exclusive and 30 inclusive.
CREATE VIEW range_20_to_30 AS
SELECT party_id, CAST('(20-30]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 20 AND avg_percentage <= 30;

--Find views with percentages between 30 exclusive and 40 inclusive.
CREATE VIEW range_30_to_40 AS
SELECT party_id, CAST('(30-40]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 30 AND avg_percentage <= 40;

--Find views with percentages between 40 exclusive and 100 inclusive.
CREATE VIEW range_40_to_100 AS
SELECT party_id, CAST('(40-100]' AS VARCHAR) AS voteRange, year, avg_percentage
FROM election_percent_votes_avg
WHERE avg_percentage > 40 AND avg_percentage <= 100;

--Union all of the individual views together.
CREATE VIEW election_ranges AS
(SELECT *
 FROM range_0_to_5)
UNION
(SELECT *
 FROM range_5_to_10)
UNION
(SELECT *
 FROM range_10_to_20)
UNION
(SELECT *
 FROM range_20_to_30)
UNION
(SELECT *
 FROM range_30_to_40)
UNION
(SELECT *
 FROM range_40_to_100);

--FOURTH: Left joining the other attributes on: countryName, partyName.

--Left Joining election_ranges with party for short partyName and country_id.
CREATE VIEW election_ranges_with_partyName AS
SELECT e.year, e.voteRange, p.country_id, p.name_short AS partyName
FROM election_ranges e LEFT JOIN party p
ON e.party_id = p.id;

--Left Joining election_ranges_with_partyName with country for countryName.
CREATE VIEW election_ranges_with_countryName AS
SELECT e.year, c.name AS countryName, e.voteRange, e.partyName
FROM election_ranges_with_partyName e LEFT JOIN country c
ON e.country_id = c.id;

INSERT INTO "q4"(year, countryName, voteRange, partyName)
(SELECT *
 FROM election_ranges_with_countryName);
