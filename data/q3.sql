SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov."q3" CASCADE;
DROP VIEW IF EXISTS parlgov.election_result_parties CASCADE;
DROP VIEW IF EXISTS parlgov.num_parties_per_country CASCADE;
DROP VIEW IF EXISTS parlgov.num_elections_per_country CASCADE;
DROP VIEW IF EXISTS parlgov.average_winnings_per_party_times_three CASCADE;
DROP VIEW IF EXISTS parlgov.max_votes CASCADE;
DROP VIEW IF EXISTS parlgov.winning_party CASCADE;
DROP VIEW IF EXISTS parlgov.duplicates CASCADE;
DROP VIEW IF EXISTS parlgov.true_winning_party CASCADE;
DROP VIEW IF EXISTS parlgov.num_wins CASCADE;
DROP VIEW IF EXISTS parlgov.all_parties CASCADE;
DROP VIEW IF EXISTS parlgov.all_parties_num_wins CASCADE;
DROP VIEW IF EXISTS parlgov.won_elections CASCADE;
DROP VIEW IF EXISTS parlgov.wonElections_with_country CASCADE;
DROP VIEW IF EXISTS parlgov.wonElections_with_average CASCADE;
DROP VIEW IF EXISTS parlgov.above_average_parties CASCADE;
DROP VIEW IF EXISTS parlgov.avg_parties_with_election_id CASCADE;
DROP VIEW IF EXISTS parlgov.avg_parties_with_dates CASCADE;
DROP VIEW IF EXISTS parlgov.most_recent_election_date  CASCADE;
DROP VIEW IF EXISTS parlgov.most_recent_avg_party_with_election_id CASCADE;
DROP VIEW IF EXISTS parlgov.avg_party_with_family CASCADE;
DROP VIEW IF EXISTS parlgov.avg_party_with_name CASCADE;
DROP VIEW IF EXISTS parlgov.avg_party_with_country_name CASCADE;

CREATE TABLE "q3"(
countryName VARCHAR(50),
partyName VARCHAR(100),
partyFamily VARCHAR(50),
wonElections INT,
mostRecentlyWonElectionId INT,
mostRecentlyWonElectionYear INT
);

--FIRST: finding 3 times the average number of winning elections of parties of the same country.

--Left joining election_result and party for the country_id of each election.
CREATE VIEW election_result_parties AS
SELECT e.election_id, e.party_id, e.votes, p.country_id
FROM election_result AS e LEFT JOIN party AS p
ON e.party_id = p.id;

--Find the number of distinct parties per country (only including parties who have participated in an election.)
--CREATE VIEW num_parties_per_country AS
--SELECT country_id, count(distinct party_id) AS num_parties
--FROM election_result_parties
--GROUP BY country_id;

CREATE VIEW num_parties_per_country AS
SELECT country_id, count(*) as num_parties
FROM party
GROUP BY country_id;

--Find the number of elections held in a country.
CREATE VIEW num_elections_per_country AS
SELECT country_id, count(distinct id) AS num_elections
FROM election
GROUP BY country_id;

--Find the average number of elections per party which is equivalent to average winnings per party, then multiplying by three.
CREATE VIEW average_winnings_per_party_times_three AS
SELECT e.country_id, 3*(CAST(e.num_elections AS float))/p.num_parties AS average_three
FROM Num_parties_per_country AS p FULL JOIN Num_elections_per_country AS e
ON p.country_id = e.country_id;

--SECOND: finding the number of wins per party.

--Find the max number of votes per election.
CREATE VIEW max_votes AS
SELECT election_id, MAX(votes) AS max_votes
FROM election_result
GROUP BY election_id;

--Find the winning party of the election.
CREATE VIEW winning_party AS
SELECT m.election_id, e.party_id, e.votes
FROM max_votes AS m LEFT JOIN election_result AS e
ON m.election_id = e.election_id and m.max_votes = e.votes;

--Find elections that don't have winners but a tie.
CREATE VIEW duplicates AS
SELECT w1.election_id, w1.party_id, w1.votes
FROM winning_party AS w1, winning_party AS w2
where w1.election_id = w2.election_id and w1.party_id != w2.party_id and w1.votes = w2.votes;

--Remove duplicates.
CREATE VIEW true_winning_party AS
(SELECT *
FROM winning_party)
EXCEPT
(SELECT *
FROM duplicates);

--Find the number of times each party won.
CREATE VIEW num_wins AS
SELECT party_id, count(*) AS wonElections
FROM true_winning_party
GROUP BY party_id;

--All party ids.
CREATE VIEW all_parties AS
SELECT id as party_id, 0 as wonElections
FROM party;

--All winnings of all parties (not distinct) (contains false 0s for some parties).
CREATE VIEW all_parties_num_wins AS
(SELECT *
 FROM num_wins)
UNION
(SELECT *
 FROM all_parties);

--The true number of wins per party.
CREATE VIEW won_elections AS
SELECT party_id, MAX(wonElections) AS wonElections
FROM all_parties_num_wins
GROUP BY party_id;


--THIRD: finding which parties are above average.

--Left Joining won_elections with party for the country_id of each party.
CREATE VIEW wonElections_with_country AS
SELECT n.party_id, n.wonElections, p.country_id
FROM won_elections AS n LEFT JOIN party AS p
ON n.party_id = p.id;

--Left Joining wonElections_with_country with Average_winnings_per_party_times three for the average winnings per country.
CREATE VIEW wonElections_with_average AS
SELECT w.party_id, w.wonElections, w.country_id, a.average_three
FROM wonElections_with_country AS w LEFT JOIN average_winnings_per_party_times_three AS a
ON w.country_id = a.country_id;

--Find which parties are above three times the average winnings.
CREATE VIEW above_average_parties AS
SELECT country_id, party_id, wonElections
FROM wonElections_with_average
WHERE wonElections > average_three;

--FOURTH: Joining with other tables to find the attributes: countryName, partyName, partyFamily, mostRecentlyWonElectionId, mostRecentlyWonElectionYear.

--Left Joining above_average_parties with election_result for the election_id of each election.
CREATE VIEW avg_parties_with_election_id AS
SELECT a.country_id, a.party_id, a.wonElections, e.election_id
FROM above_average_parties AS a LEFT JOIN election_result AS e
ON a.party_id = e.party_id
ORDER BY a.party_id;

--Left Joining avg_parties_with_election_id with election for the date of each election.
CREATE VIEW avg_parties_with_dates AS
SELECT a.country_id, a.party_id, a.wonElections, a.election_id, e.e_date
FROM avg_parties_with_election_id AS a LEFT JOIN election AS e
ON a.election_id = e.id;

--Find the most recient election for each party.
CREATE VIEW most_recent_election_date AS
SELECT country_id, party_id, wonElections, MAX(e_date) AS mostRecentlyWonElectionDate
FROM avg_parties_with_dates
GROUP BY country_id, party_id, wonElections;

--Left Joining most_recent_election_date with avg_parties_with_dates for the election_id of each election.
CREATE VIEW most_recent_avg_party_with_election_id AS
SELECT DISTINCT m.country_id, m.party_id, m.wonElections, m.mostRecentlyWonElectionDate, e.election_id
FROM most_recent_election_date AS m LEFT JOIN avg_parties_with_dates AS e
ON m.mostRecentlyWonElectionDate = e.e_date and m.party_id = e.party_id;

--Left Joining most_recent_avg_party_with_election_id with party_family for the party family of each party.
CREATE VIEW avg_party_with_family AS
SELECT m.country_id, m.party_id, m.wonElections, EXTRACT(YEAR from m.mostRecentlyWonElectionDate) AS mostRecentlyWonElectionYear, m.election_id, f.family
FROM most_recent_avg_party_with_election_id AS m LEFT JOIN party_family AS f
ON m.party_id = f.party_id;

--Left Joining avg_party_with_family with party for the partyName of each party.
CREATE VIEW avg_party_with_name AS
SELECT a.country_id, p.name AS partyName, a.family AS partyFamily, a.wonElections, a.election_id AS mostRecentlyWonElectionId, a.mostRecentlyWonElectionYear
FROM avg_party_with_family AS a LEFT JOIN party AS p
ON a.party_id = p.id;

--Left Joining avg_party_with_name with country for the countryName of each party.
CREATE VIEW avg_party_with_country_name AS
SELECT c.name AS countryName, a.partyName, a.partyFamily, a.wonElections, a.mostRecentlyWonElectionId, a.mostRecentlyWonElectionYear
FROM avg_party_with_name AS a LEFT JOIN country AS c
ON a.country_id = c.id;

--FIFTH: Insert into final table.
INSERT INTO "q3"(countryName, partyName, partyFamily, wonElections, mostRecentlyWonElectionId, mostRecentlyWonElectionYear)
(SELECT *
FROM avg_party_with_country_name);

