-- Table definitions for the tournament project.

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


-- Create the views
-- Wins View
CREATE VIEW Wins AS
    SELECT
	p.id, COUNT(m.winner) AS wins
    FROM
        Players p LEFT JOIN Matches m ON p.id = m.winner
    GROUP BY p.id
    ORDER BY wins DESC;


-- NumMatches View
CREATE VIEW NumMatches AS
    SELECT
        p.id, (pOnes.countp1 + pTwos.countp2) AS matches
    FROM
	Players p INNER JOIN (
	    SELECT p.id AS p1id, COUNT(m.player1) AS countp1
	    FROM Players p LEFT JOIN Matches m ON p.id = m.player1
	    GROUP BY p.id
	) AS pOnes ON p.id = pOnes.p1id INNER JOIN (
	    SELECT p.id AS p2id, COUNT(m.player2) AS countp2
	    FROM Players p LEFT JOIN Matches m ON p.id = m.player2
	    GROUP BY p.id
	) AS pTwos ON p.id = pTwos.p2id
    ORDER BY matches DESC;


-- Standings View
CREATE VIEW Standings AS
    SELECT
	p.id, p.name, w.wins, nm.matches
    FROM
        Players p INNER JOIN Wins w ON p.id = w.id
	INNER JOIN NumMatches nm ON p.id = nm.id
    ORDER BY w.wins DESC;


-- Swiss Pairings
CREATE VIEW Pairings AS
    SELECT
        odds.p1id, odds.p1name, evens.p2id, evens.p2name
    FROM (
        SELECT t.id AS p1id, t.name AS p1name, t.row
	FROM (
	    SELECT *, row_number() OVER(ORDER BY wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 != 0
    ) AS odds INNER JOIN (
	SELECT t.id AS p2id, t.name AS p2name, (t.row - 1) AS rowM1
	FROM (
	    SELECT *, row_number() OVER(ORDER BY wins DESC) AS row
	    FROM Standings
	) AS t
	WHERE t.row % 2 = 0
    ) AS evens ON odds.row = evens.rowM1;
    



















