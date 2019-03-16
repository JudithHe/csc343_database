SET SEARCH_PATH to parlgov;

SELECT *
FROM q4
ORDER BY q4.year DESC, q4.countryName DESC, q4.voteRange DESC, q4.partyName DESC;
