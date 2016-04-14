-- Table and view definitions for the tournament project

-- Setup the database
DROP DATABASE IF EXISTS tournament;
CREATE DATABASE tournament;
\c tournament;



-- Create the tables

-- Tournament Table
CREATE TABLE Tourneys (id     serial  PRIMARY KEY NOT NULL
                      ,name   varchar(50));


-- Players Table
CREATE TABLE Players (tourney integer REFERENCES Tourneys (id)
                     ,id      serial  PRIMARY KEY NOT NULL
		     ,name    varchar(50));


-- Matches Table
CREATE TABLE Matches (tourney integer REFERENCES Tourneys (id)
                     ,id      serial  PRIMARY KEY NOT NULL
		     ,player1 integer REFERENCES Players (id)
                     ,player2 integer REFERENCES Players (id)
                     ,winner  integer REFERENCES Players (id));



-- Views

-- Wins View: Shows how many wins each player has in their tournament
-- This is a count aggregation of the players left joined to matches
CREATE VIEW Wins AS
    SELECT
	p.tourney, p.id, COUNT(m.winner) AS wins
    FROM
        Players p
	LEFT JOIN Matches m
	ON p.tourney = m.tourney AND p.id = m.winner
    GROUP BY p.id
    ORDER BY p.tourney, wins DESC;


/* NumMatches View: Shows how many matches each player has played
 *
 * Due to the structure of the Matches table a player can appear
 * in either the player1 or player2 field for a given match
 *
 * This means their total number of matches is equal to:
 *   Times played as p1 + Times played as p2
 *
 * That can be calculated as follows:
 *   1) Aggregate the count of the players in each position in two subqueries
 *   2) Join the 2 queries and sum the 2 counts on every row
 *
 * This formula needs to be performed across each tournament
 */
CREATE VIEW NumMatches AS
    SELECT
        p.tourney, p.id, (pOnes.countp1 + pTwos.countp2) AS matches
    FROM
	Players p
	INNER JOIN (
	    SELECT p.tourney AS p1t, p.id AS p1id, COUNT(m.player1) AS countp1
	    FROM Players p LEFT JOIN Matches m
		ON p.tourney = m.tourney AND p.id = m.player1
	    GROUP BY p.tourney, p.id
	) AS pOnes
	ON p.tourney = pOnes.p1t AND p.id = pOnes.p1id
	INNER JOIN (
	    SELECT p.tourney AS p2t, p.id AS p2id, COUNT(m.player2) AS countp2
	    FROM Players p LEFT JOIN Matches m
	        ON p.tourney = m.tourney AND p.id = m.player2
	    GROUP BY p.tourney, p.id
	) AS pTwos
	ON p.tourney = pTwos.p2t AND p.id = pTwos.p2id
    ORDER BY p.tourney, matches DESC;


-- Standings View: Shows the current standings for all the tournaments
-- This is a simple join of the players to their matches and wins
CREATE VIEW Standings AS
    SELECT
	p.tourney, p.id, p.name, w.wins, nm.matches
    FROM
        Players p
	INNER JOIN Wins w
	    ON p.tourney = w.tourney AND p.id = w.id
	INNER JOIN NumMatches nm
	    ON p.tourney = nm.tourney AND p.id = nm.id
    ORDER BY p.tourney, w.wins DESC;


/* Swiss Pairings View: Creates the correct pairings for the next round
 *
 * The idea is to create two subqueries of the standings
 * using the SQL row number feature as follows:
 *   1) Every other row starting from the first (odd rows)
 *   2) Every other row starting from the second (even rows)
 *
 * These two queries can be joined using the row number as the key
 * as any even row number minus one equals its odd counterpart
 *
 * Assumes even number of players in each tournament
 */
CREATE VIEW Pairings AS
    SELECT
        odds.p1t AS tourney, odds.p1id, odds.p1name, evens.p2id, evens.p2name
    FROM (
        SELECT
	    t.tourney AS p1t, t.id AS p1id, t.name AS p1name, t.row
	FROM (
	    SELECT *, row_number() OVER(ORDER BY tourney, wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 != 0 -- Remainder after division by 2 == odd number
    ) AS odds
    INNER JOIN (
	SELECT
	    t.tourney AS p2t, t.id AS p2id, t.name AS p2name, (t.row - 1) AS rowM1
	FROM (
	    SELECT *, row_number() OVER(ORDER BY tourney, wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 = 0 -- No remainder after division by 2 == even number
    ) AS evens
    ON odds.row = evens.rowM1
    ORDER BY tourney;
