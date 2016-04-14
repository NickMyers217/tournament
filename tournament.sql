-- Table and view definitions for the tournament project

-- Setup the database
DROP DATABASE IF EXISTS tournament;
CREATE DATABASE tournament;
\c tournament;


-- Create the tables
--CREATE TABLE Tourneys (id     serial  PRIMARY KEY NOT NULL
--                      ,name   varchar(50));


-- Players Table
CREATE TABLE Players (id      serial  PRIMARY KEY NOT NULL
                     --,tourney integer REFERENCES Tourneys (id)
                     ,name    varchar(50));


-- Matches Table
CREATE TABLE Matches (id      serial  PRIMARY KEY NOT NULL
                     --,tourney integer REFERENCES Tourneys (id)
                     ,player1 integer REFERENCES Players (id)
                     ,player2 integer REFERENCES Players (id)
                     ,winner  integer REFERENCES Players (id));


-- Wins View: Shows how many wins each player has
-- This is a count aggregation of the players left joined to matches
CREATE VIEW Wins AS
    SELECT
	p.id, COUNT(m.winner) AS wins
    FROM
        Players p LEFT JOIN Matches m ON p.id = m.winner
    GROUP BY p.id
    ORDER BY wins DESC;


/* NumMatches View: Shows how many matches each player has played
 * Due to the structure of the Matches table a player can appear
 * in either the player1 or player2 field for a given match
 *
 * This means their total number of matches is equal to:
 *   Times played as p1 + Times played as p2
 *
 * That can be calculated as follows:
 *   1) Aggregate the count of the players in each position in two subqueries
 *   2) Join the 2 queries and sum the 2 counts on every row
 */
CREATE VIEW NumMatches AS
    SELECT
        p.id, (pOnes.countp1 + pTwos.countp2) AS matches
    FROM
	Players p
	INNER JOIN (
	    SELECT p.id AS p1id, COUNT(m.player1) AS countp1
	    FROM Players p LEFT JOIN Matches m ON p.id = m.player1
	    GROUP BY p.id
	) AS pOnes ON p.id = pOnes.p1id
	INNER JOIN (
	    SELECT p.id AS p2id, COUNT(m.player2) AS countp2
	    FROM Players p LEFT JOIN Matches m ON p.id = m.player2
	    GROUP BY p.id
	) AS pTwos ON p.id = pTwos.p2id
    ORDER BY matches DESC;


-- Standings View: Shows the current standings
-- This is a simple join of the players to theis matches and wins
CREATE VIEW Standings AS
    SELECT
	p.id, p.name, w.wins, nm.matches
    FROM
        Players p
	INNER JOIN Wins w        ON p.id = w.id
	INNER JOIN NumMatches nm ON p.id = nm.id
    ORDER BY w.wins DESC;


/* Swiss Pairings View: Creates the correct pairings for the next round
 * The idea is to create two subqueries of the standings
 * using the SQL row number feature as follows:
 *   1) Every other row starting from the first (odd rows)
 *   2) Every other row starting from the second (even rows)
 *
 * These two queries can be joined using the row number as the key
 * as any even row number minus one equals its odd counterpart
 */
CREATE VIEW Pairings AS
    SELECT
        odds.p1id, odds.p1name, evens.p2id, evens.p2name
    FROM (
        SELECT t.id AS p1id, t.name AS p1name, t.row
	FROM (
	    SELECT *, row_number() OVER(ORDER BY wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 != 0 -- Remainder after division by 2 == odd number
    ) AS odds
    INNER JOIN (
	SELECT t.id AS p2id, t.name AS p2name, (t.row - 1) AS rowM1
	FROM (
	    SELECT *, row_number() OVER(ORDER BY wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 = 0 -- No remainder after division by 2 == even number
    ) AS evens
    ON odds.row = evens.rowM1;
