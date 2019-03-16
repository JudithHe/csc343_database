SET SEARCH_PATH to parlgov;

SELECT *
FROM q3
ORDER BY q3.countryName ASC, q3.wonElections ASC, q3.partyName DESC;
