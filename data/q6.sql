SET SEARCH_PATH to parlgov;

DROP TABLE IF EXISTS parlgov."q6" CASCADE;
DROP VIEW IF EXISTS parlgov.CountryParty CASCADE;
DROP VIEW IF EXISTS parlgov.CountryPos1 CASCADE;
DROP VIEW IF EXISTS parlgov.CountryPos2 CASCADE;
DROP VIEW IF EXISTS parlgov.CountryPos4 CASCADE;
DROP VIEW IF EXISTS parlgov.CountryPos5 CASCADE;
DROP VIEW IF EXISTS parlgov.Results CASCADE;


CREATE TABLE "q6"(
countryName VARCHAR(50),
r0_2 INT default 0,
r2_4 INT default 0,
r4_6 INT default 0,
r6_8 INT default 0,
r8_10 INT default 0
--check("r0-2" >= 0 and "r0-2" <2),
--check("r2-4" >= 2 and "r2-4" <4),
--check("r4-6" >= 4 and "r4-6" <6),
--check("r6-8" >= 6 and "r6-8" <8),
--check("r8-10" >= 8 and "r8-10" <=10)
);

CREATE View CountryParty As   --country.name is unique and not null
Select country.name As countryname, party.id As partyid
From country left join party on country.id = country_id;

CREATE View CountryPos1 As  --country and r0-2
Select countryname, count(party_id) As r0_2
From CountryParty left join party_position on partyid = party_id
where left_right >= 0 and left_right < 2
Group by countryname;

CREATE View CountryPos2 As  --country and r2-4
Select countryname, count(party_id) As r2_4
From CountryParty left join party_position on partyid = party_id
where left_right >= 2 and left_right < 4
Group by countryname;

CREATE View CountryPos3 As  --country and r4-6
Select countryname, count(party_id) As r4_6
From CountryParty left join party_position on partyid = party_id
where left_right >= 4 and left_right < 6
Group by countryname;

CREATE View CountryPos4 As  --country and r6-8
Select countryname, count(party_id) As r6_8
From CountryParty left join party_position on partyid = party_id
where left_right >= 6 and left_right < 8
Group by countryname;

CREATE View CountryPos5 As  --country and r8-10
Select countryname, count(party_id) As r8_10
From CountryParty left join party_position on partyid = party_id
Where left_right >= 8 and left_right <= 10
Group by countryname;

CREATE View Results As 
Select countryname, r0_2, r2_4, r4_6, r6_8, r8_10
From CountryPos1 Natural join CountryPos2 Natural join CountryPos3 Natural join CountryPos4 Natural join CountryPos5;

--Insert into final table.
Insert into "q6"(countryName, r0_2, r2_4,r4_6,r6_8,r8_10)
(Select * From Results);







