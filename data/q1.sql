SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov.q1 CASCADE;
DROP VIEW IF EXISTS parlgov.info CASCADE;
DROP VIEW IF EXISTS parlgov.leaderPairs1 CASCADE;
DROP VIEW IF EXISTS parlgov.leaderPairs2 CASCADE;
DROP VIEW IF EXISTS parlgov.leaderPairs CASCADE;
DROP VIEW IF EXISTS parlgov.notLeaderPairs CASCADE;
DROP VIEW IF EXISTS parlgov.allPairs CASCADE;
DROP VIEW IF EXISTS parlgov.electionCount CASCADE;
DROP VIEW IF EXISTS parlgov.pairCount CASCADE;
DROP VIEW IF EXISTS parlgov.answer CASCADE;

CREATE TABLE q1(
    countryId INT,
    alliedPartyId1 INT,
    alliedPartyId2 INT);

/*
election(id(key), country_id REF country(id), ...)
election_result(id(key), election_id REF election(id), party_id REF party(id), alliance_id REF election_result(id), ...)
*/
-- create view with all the necessary information
-- info: country_id | election_id | result_id | party_id | alliance_id
CREATE VIEW info AS
    SELECT DISTINCT e.country_id, e_r.election_id, e_r.id AS result_id, e_r.party_id, e_r.alliance_id
    FROM election e, election_result e_r
    WHERE e.id = e_r.election_id;

-- create view with all allied pairs involving leader parties
-- where party_id (not leader) < party_id (leader)
-- leaderPairs1: country_id | election_id | party1 | party2
CREATE VIEW leaderPairs1 AS
    SELECT i1.country_id, i1.election_id, i1.party_id AS party1, i2.party_id AS party2
    FROM info i1, info i2
    WHERE i1.alliance_id IS NOT NULL AND i1.country_id = i2.country_id AND i1.election_id = i2.election_id AND 
          i1.alliance_id = i2.result_id AND i1.party_id < i2.party_id;

-- create view with all allied pairs involving leader parties
-- where party_id > alliance_id (leader)
-- leaderPairs2: country_id | election_id | party1 | party2
CREATE VIEW leaderPairs2 AS
    SELECT i1.country_id, i1.election_id, i2.party_id AS party1, i1.party_id AS party2
    FROM info i1, info i2
    WHERE i1.alliance_id IS NOT NULL AND i1.country_id = i2.country_id AND i1.election_id = i2.election_id AND 
          i1.alliance_id = i2.result_id AND i1.party_id > i2.party_id;

-- create view with all allied pairs involving leader parties
-- leaderPairs: country_id | election_id | party1 | party2
CREATE VIEW leaderPairs AS
    (SELECT *
    FROM leaderPairs1) 
    UNION 
    (SELECT *
    FROM leaderPairs2);

-- create view with all allied pairs not involving leaders
-- notLeaderPairs: country_id | election_id | party1 | party2
CREATE VIEW notLeaderPairs AS
    SELECT d1.country_id, d1.election_id, d1.party_id AS party1, d2.party_id AS party2
    FROM info d1, info d2
    WHERE d1.country_id = d2.country_id AND d1.election_id = d2.election_id AND
          d1.alliance_id = d2.alliance_id AND d1.party_id < d2.party_id;

-- create view with all allied pairs
-- allPairs: country_id | election_id | party1 | party2
CREATE VIEW allPairs AS
    (SELECT *
    FROM leaderPairs)
    UNION
    (SELECT *
    FROM notLeaderPairs);

-- create view with the number of elections per country
-- electionCount: country_id | numElections
CREATE VIEW electionCount AS
    SELECT country_id, COUNT(election_id) AS numElections
    FROM (SELECT DISTINCT country_id, election_id FROM allPairs) AS e
    GROUP BY country_id;

-- create view with number of elections each pair has been allies in
-- pairCount: country_id | party1 | party2 | numPairs
CREATE VIEW pairCount AS
    SELECT country_id, party1, party2, count(*) as numPairs
    FROM allPairs
    GROUP BY country_id, party1, party2;

-- create view with final answer
-- answer: countryID, alliedParty1, alliedParty2
CREATE VIEW answer AS
    SELECT country_id AS countryId, party1 AS alliedPartyId1, party2 as alliedPartyId2
    FROM electionCount NATURAL JOIN pairCount
    WHERE (numElections * 0.3) <= numPairs;

-- insert final answer into table q1
INSERT INTO q1(countryId, alliedPartyId1, alliedPartyId2) (
    SELECT *
    FROM answer);