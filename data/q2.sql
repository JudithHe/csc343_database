SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov.q2 CASCADE;
DROP VIEW IF EXISTS parlgov.allCabinets CASCADE;
DROP VIEW IF EXISTS parlgov.allParties CASCADE;
DROP VIEW IF EXISTS parlgov.cabinetCount CASCADE;
DROP VIEW IF EXISTS parlgov.memberCount CASCADE;
DROP VIEW IF EXISTS parlgov.committedParty CASCADE;
DROP VIEW IF EXISTS parlgov.answer CASCADE;

CREATE TABLE q2(
    countryName VARCHAR(50),
    partyName VARCHAR(100),
    partyFamily VARCHAR(50),
    stateMarket REAL);
/* 
commited party: a party that has been a member of all cabinets in
their country over the past 20 years
*/

-- create view with all cabinets over 20 years
-- allCabinets: country_id | cabinet_id
CREATE VIEW allCabinets AS
    SELECT country_id, id AS cabinet_id
    FROM cabinet
    WHERE start_date::date >= '1999-01-01';

-- create view with all parties and their cabinets over 20 years
-- allParties: country_id | party_id | cabinet_id
CREATE VIEW allParties AS
    SELECT country_id, party_id, cabinet_id
    FROM  allCabinets NATURAL JOIN cabinet_party;

-- create view with the number of cabinets per country over 20
-- years
-- cabinetCount: country_id | numCabinets
CREATE VIEW cabinetCount AS
    SELECT country_id, COUNT(cabinet_id) AS numCabinets
    FROM allCabinets
    GROUP BY country_id;

-- create view with the number of cabinet memberships per party
-- in their country within 20 years
-- memberCount: country_id | party_id | numMember
CREATE VIEW memberCount AS
    SELECT country_id, party_id, COUNT(*) AS numMember
    FROM allParties
    GROUP BY country_id, party_id;

-- create view with parties that have been members of all cabinets
-- in their country in the last 20 years
-- committedParty: country_id | party_id
CREATE VIEW committedParty AS
    SELECT DISTINCT m.country_id, m.party_id
    FROM cabinetCount c, memberCount m
    WHERE c.country_id = m.country_id AND c.numCabinets = m.numMember;

-- create view with final answer
-- answer: countryName | partyName | partyFamily | stateMarket
CREATE VIEW answer AS
    SELECT DISTINCT c.name AS countryName, p.name AS partyName, pf.family AS partyFamily, pp.state_market AS stateMarket
    FROM committedParty cp, country c, party p, party_family pf, party_position pp
    WHERE cp.country_id = c.id AND cp.party_id = p.id AND cp.party_id = pf.party_id AND cp.party_id = pp.party_id;

-- insert final answer into table q2
INSERT INTO q2(countryName, partyName, partyFamily, stateMarket) (
    SELECT *
    FROM answer);