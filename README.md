# Swiss Pairings
This is an implementation of a Swiss style tournament pairing system written in Python.
It is backed by a PostgreSQL database.

tournament.py exposes a simple API for CRUD operations on the tournaments, players, and matches in the database, and tournament.sql is the database setup script.

## Installation
To get the database up and running, use the following commands from your shell (you'll need git, python 2.7, and psql installed).

``` shell
git clone https://github.com/nickmyers217/tournament
cd tournament
psql -f tournament.sql
python tournament_test.py
```

That will create the tournament database on your system and run the unit tests, the rest is up to you.