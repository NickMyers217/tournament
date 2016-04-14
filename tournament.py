#!/usr/bin/env python
# 
# tournament.py -- implementation of a Swiss-system tournament
#

import psycopg2


def connect():
    """Connect to the PostgreSQL database.  Returns a database connection."""
    return psycopg2.connect("dbname=tournament")


def getTourneyID(name):
    """Returns the ID for a tournament name"""
    conn = connect()
    c = conn.cursor()
    c.execute("SELECT id FROM Tourneys WHERE name = %s",
              (name,))
    tid = c.fetchall()[0][0]
    conn.close()
    return tid


def deleteTourneys():
    """Remove all the tournament records from the database."""
    deleteAllMatches()
    deleteAllPlayers()
    conn = connect()
    conn.cursor().execute("DELETE FROM Tourneys;")
    conn.commit()
    conn.close()


def deleteAllMatches():
    """Remove all the match records."""
    conn = connect()
    conn.cursor().execute("DELETE FROM Matches;")
    conn.commit()
    conn.close()


def deleteAllPlayers():
    """Remove all the player records."""
    conn = connect()
    conn.cursor().execute("DELETE FROM Players;")
    conn.commit()
    conn.close()


def deleteMatches(tourney):
    """Remove all the match records from a tourney"""
    conn = connect()
    conn.cursor().execute("DELETE FROM Matches WHERE tourney = %s;",
                          (getTourneyID(tourney),))
    conn.commit()
    conn.close()


def deletePlayers(tourney):
    """Remove all the player records from a tourney."""
    conn = connect()
    conn.cursor().execute("DELETE FROM Players WHERE tourney = %s;",
                          (getTourneyID(tourney),))
    conn.commit()
    conn.close()


def countTourneys():
    """Returns the number of registered tournaments"""
    conn = connect()
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM Tourneys;")
    # The first value converted to an int is the count
    numTourneys = int(c.fetchall()[0][0])
    conn.close()
    return numTourneys


def registerTourney(name):
    """Adds a tournament to the database.
  
    Args:
      name: the tournament name
    """
    conn = connect()
    c = conn.cursor()
    c.execute("INSERT INTO Tourneys (name) VALUES (%s);", (name,))
    conn.commit()
    conn.close()


def countPlayers(tourney):
    """Returns the number of players currently registered in a tourney.
    
    Args:
      tourney: the tournament
    """
    conn = connect()
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM Players WHERE tourney = %s;",
              (getTourneyID(tourney),))
    # The first value converted to an int is the count
    numPlayers = int(c.fetchall()[0][0])
    conn.close()
    return numPlayers


def registerPlayer(tourney, name):
    """Adds a player to the tournament database.
  
    Args:
      tourney: the player's tournament
      name: the player's full name
    """
    conn = connect()
    c = conn.cursor()
    c.execute("INSERT INTO Players (tourney, name) VALUES (%s, %s);",
              (getTourneyID(tourney), name))
    conn.commit()
    conn.close()


def playerStandings(tourney):
    """Returns a list of the players and their win records, sorted by wins.

    The first entry in the list should be the player in first place, or a player
    tied for first place if there is currently a tie.

    Args:
      tourney: the tourney you want standings for

    Returns:
      A list of tuples, each of which contains (id, name, wins, matches):
        id: the player's unique id (assigned by the database)
        name: the player's full name (as registered)
        wins: the number of matches the player has won
        matches: the number of matches the player has played
    """
    conn = connect()
    c = conn.cursor()
    c.execute("SELECT * FROM standings WHERE tourney = %s;",
              (getTourneyID(tourney),)) 
    standings = c.fetchall()
    conn.close()
    return standings


def reportMatch(tourney, winner, loser):
    """Records the outcome of a single match between two players.

    Args:
      tourneyID: the tournament the match was in
      winner:  the id number of the player who won
      loser:  the id number of the player who lost
    """
    conn = connect()
    c = conn.cursor()
    matchInsert = '''
    INSERT INTO matches (tourney, player1, player2, winner)
    VALUES (%s, %s, %s, %s);
    '''
    c.execute(matchInsert, (getTourneyID(tourney), winner, loser, winner))
    conn.commit()
    conn.close()
     
 
def swissPairings(tourney):
    """Returns a list of pairs of players for the next round of a match.
  
    Assuming that there are an even number of players registered, each player
    appears exactly once in the pairings.  Each player is paired with another
    player with an equal or nearly-equal win record, that is, a player adjacent
    to him or her in the standings.
  
    Args:
      tourney: the tournamet to get pairings for

    Returns:
      A list of tuples, each of which contains (id1, name1, id2, name2)
        id1: the first player's unique id
        name1: the first player's name
        id2: the second player's unique id
        name2: the second player's name
    """
    conn = connect()
    c = conn.cursor()
    # All the magic is performed in the sql query
    c.execute("SELECT * FROM Pairings WHERE tourney = %s;",
              (getTourneyID(tourney),))
    pairings = c.fetchall()
    conn.close()
    return pairings
