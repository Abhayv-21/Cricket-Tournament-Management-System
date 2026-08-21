# Cricket Tournament Management System

## 📌 Project Overview

The Cricket Tournament Management System is a PostgreSQL-based database project designed to manage cricket tournaments, teams, players, matches, innings, ball-by-ball events, player statistics, and tournament points.

The system provides a structured way to store and analyze cricket tournament data while maintaining data integrity through primary keys, foreign keys, check constraints, functions, procedures, and triggers.

---

## 🎯 Objectives

- Manage cricket tournaments and teams
- Store player information
- Schedule and manage matches
- Maintain playing XI for each match
- Record innings-level information
- Store ball-by-ball match events
- Track batting and bowling performances
- Maintain fall of wickets
- Automatically maintain tournament points
- Generate useful cricket statistics using SQL queries

---

## 🗂️ Database Structure

The major tables in the database are:

1. `tournaments`
2. `teams`
3. `players`
4. `venues`
5. `matches`
6. `match_squads`
7. `innings`
8. `ball_events`
9. `batting_scorecards`
10. `bowling_scorecards`
11. `fall_of_wickets`
12. `points_table`

---

## 🔑 Main Relationships

- A tournament contains multiple teams.
- A team contains multiple players.
- A tournament consists of multiple matches.
- A match is played between two teams.
- A match is played at a venue.
- A match has multiple players in its squad.
- A match contains one or more innings.
- An innings contains multiple ball events.
- Ball events are associated with batsmen, bowlers and fielders.
- Batting and bowling scorecards are maintained for each innings.
- Fall of wickets records wickets during an innings.
- The points table maintains tournament standings for each team.

---

## ⚙️ Database Features

### Constraints

The database uses:

- Primary Key constraints
- Foreign Key constraints
- Unique constraints
- Check constraints
- Default values

These constraints help maintain data consistency and prevent invalid cricket records.

### Functions

Functions are implemented for operations such as:

- Calculating player statistics
- Retrieving match information
- Generating performance statistics
- Calculating tournament-related information

### Procedures

Stored procedures are used for operations that modify or manage tournament data.

### Triggers

Triggers are used to automatically perform operations when relevant database events occur.

For example, ball events can automatically update wicket-related information.

---

## 📊 Cricket Statistics

The system supports analysis of:

- Total runs
- Balls faced
- Fours
- Sixes
- Batting performance
- Bowling performance
- Wickets
- Runs conceded
- Economy
- Match results
- Tournament points
- Team standings

---

## 📁 Project Structure

```text
Cricket-Tournament-Management-System/
│
├── database/
│   ├── schema.sql
│   ├── sample_data.sql
│   ├── queries.sql
│   ├── procedures.sql
│   ├── triggers.sql
│   ├── database_objects.sql
│   ├── procedures_backup.sql
│   └── triggers_backup.sql
│
├── README.md
└── .gitignore
