-- TABLE ROLES
CREATE TABLE roles(
    role_id SERIAL PRIMARY KEY,
    role_name VARCHAR(30) UNIQUE NOT NULL
);

-- TABLE USRES
CREATE TABLE users(
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_role
        FOREIGN KEY(role_id)
        REFERENCES roles(role_id)
);

INSERT INTO roles(role_name)
VALUES
('Admin'),
('Scorer'),
('Team Owner'),
('Viewer');


-- TABLE TOURNAMNETS
CREATE TABLE tournaments(
    tournament_id SERIAL PRIMARY KEY,
    tournament_name VARCHAR(100) NOT NULL,
    season INT,
    start_date DATE,
    location VARCHAR(100),
    status VARCHAR(20)
        CHECK(status IN ('Upcoming', 'Ongoing', 'Completed'))
);

-- TABLE VENUES
CREATE TABLE venues(
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    country VARCHAR(100) DEFAULT 'INDIA',
    capacity INT,
    pitch_type VARCHAR(30),
    tournament_id INT,

    CONSTRAINT fk_tournament
        FOREIGN KEY (tournament_id)
        REFERENCES tournaments(tournament_id)
        ON DELETE CASCADE
);


-- TABLE TEAM
CREATE TABLE teams(
    team_id SERIAL PRIMARY KEY,
    team_name VARCHAR(100) UNIQUE NOT NULL,
    short_name VARCHAR(10) UNIQUE NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    coach_name VARCHAR(100) NOT NULL,
    captain_id INT,
    home_venue_id INT,
    CONSTRAINT fk_home_venue
    FOREIGN KEY(home_venue_id)
    REFERENCES venues(venue_id),
    tournament_id INT NOT NULL,
    CONSTRAINT fk_tournament
    FOREIGN KEY(tournament_id)
    REFERENCES tournaments(tournament_id),
    created_at TIMESTAMP
    DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE players(
    player_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    dob DATE NOT NULL,
    nationality VARCHAR(50) NOT NULL,
    batting_style VARCHAR(50)
    CHECK (batting_style IN ('Right-hand Bat', 'Left-Hand Bat')),
    bowling_style VARCHAR(50)
    CHECK (
    bowling_style IN (
        'Right-arm Fast',
        'Left-arm Fast',
        'Right-arm Medium',
        'Left-arm Medium',
        'Right-arm Spin',
        'Left-arm Spin'
    )
),
    player_role VARCHAR(50)
    CHECK (player_role IN ('Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper')),
    jersey_number INT NOT NULL,
    CHECK (jersey_number>0),
    email VARCHAR(100) UNIQUE,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    height_cm DECIMAL(5, 2),
    CHECK (height_cm>0),
    weight_kg DECIMAL(5, 2),
    CHECK (weight_kg>0),
    team_id INT,
    CONSTRAINT fk_team
    FOREIGN KEY(team_id)
    REFERENCES teams(team_id),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP
    DEFAULT CURRENT_TIMESTAMP
);

-- TABLE MATCHES
CREATE TABLE matches(
    match_id SERIAL PRIMARY KEY,

    tournament_id INT NOT NULL,
    CONSTRAINT fk_tournament
    FOREIGN KEY(tournament_id)
    REFERENCES tournaments(tournament_id),

    team1_id INT NOT NULL,
    CONSTRAINT fk_team1_id
    FOREIGN KEY(team1_id)
    REFERENCES teams(team_id),

    team2_id INT NOT NULL,
    CONSTRAINT fk_team2_id
    FOREIGN KEY(team2_id)
    REFERENCES teams(team_id),
    CHECK (team1_id <> team2_id),

    venue_id INT NOT NULL,
    CONSTRAINT fk_match_venue
    FOREIGN KEY(venue_id)
    REFERENCES venues(venue_id),

    match_date DATE NOT NULL,

    status VARCHAR(50)
    DEFAULT 'Scheduled'
    CHECK (status IN ('Scheduled', 'Live', 'Completed', 'Cancelled')),

    winner_team_id INT,
    CONSTRAINT fk_winner_team_id
    FOREIGN KEY(winner_team_id)
    REFERENCES teams(team_id),

    CHECK(
        winner_team_id IS NULL
        OR winner_team_id = team1_id
        OR winner_team_id = team2_id
    ),

    toss_winner_id INT,
    CONSTRAINT fk_toss_winner_id
    FOREIGN KEY(toss_winner_id)
    REFERENCES teams(team_id),

    toss_decision VARCHAR(50)
    CHECK (toss_decision IN ('Batting', 'Bowling')),

    match_result VARCHAR(20)
    CHECK (
        match_result IN ('Pending', 'Team Won', 'Tie', 'No Result')
    ),

    match_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLE MATCH_SQUADS
CREATE TABLE match_squads(
    match_id INT NOT NULL,
    CONSTRAINT fk_match
    FOREIGN KEY(match_id)
    REFERENCES matches(match_id),

    player_id INT NOT NULL,
    CONSTRAINT fk_player
    FOREIGN KEY(player_id)
    REFERENCES players(player_id),

    team_id INT NOT NULL,
    CONSTRAINT fk_team
    FOREIGN KEY(team_id)
    REFERENCES teams(team_id),

    PRIMARY KEY (match_id, player_id),

    is_playing_xi BOOLEAN DEFAULT TRUE,
    is_captain BOOLEAN DEFAULT FALSE,
    is_wicket_keeper BOOLEAN DEFAULT FALSE,
    batting_position INT,
    CONSTRAINT chk_batting_position
    CHECK (
        batting_position BETWEEN 1 AND 11
        OR batting_position IS NULL
    ),
    UNIQUE (match_id, team_id, batting_position),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLE INNIGNS
CREATE TABLE innings(
    innings_id SERIAL PRIMARY KEY,

    match_id INT NOT NULL,
    CONSTRAINT fk_match_id
    FOREIGN KEY(match_id)
    REFERENCES matches(match_id),

    innings_no INT NOT NULL,
    CONSTRAINT chk_innings_no
    CHECK(
        innings_no IN (1, 2)
    ),
    CONSTRAINT uq_match_innings
    UNIQUE (match_id, innings_no),

    batting_team_id INT NOT NULL,
    bowling_team_id INT NOT NULL,

    CONSTRAINT fk_batting_team
    FOREIGN KEY (batting_team_id)
    REFERENCES teams(team_id),

    CONSTRAINT fk_bowling_team
    FOREIGN KEY (bowling_team_id)
    REFERENCES teams(team_id),

    CHECK (batting_team_id <> bowling_team_id),

    total_runs INT DEFAULT 0,
    total_wickets INT DEFAULT 0,
    overs_completed DECIMAL(4, 1) DEFAULT 0.0,
    extras INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TABLE BALL_EVENTS
CREATE TABLE ball_events(
    ball_event_id SERIAL PRIMARY KEY,
    innings_id INT NOT NULL,
    over_number INT NOT NULL,
    ball_number INT NOT NULL,
    striker_id INT NOT NULL,
    non_striker_id INT NOT NULL,
    bowler_id INT NOT NULL,
    batsman_runs INT NOT NULL,
    extras INT NOT NULL,
    total_runs INT NOT NULL,
    is_wicket BOOLEAN DEFAULT FALSE,
    batsman_out_id INT,
    dismissal_type VARCHAR(30),

    CONSTRAINT fk_innings
    FOREIGN KEY (innings_id)
    REFERENCES innings(innings_id),

    CONSTRAINT fk_striker
    FOREIGN KEY (striker_id)
    REFERENCES players(player_id),

    CONSTRAINT fk_non_striker
    FOREIGN KEY (non_striker_id)
    REFERENCES players(player_id),

    CONSTRAINT fk_bowler_id
    FOREIGN KEY (bowler_id)
    REFERENCES players(player_id),

    CONSTRAINT fk_batsman_out_id
    FOREIGN KEY (batsman_out_id)
    REFERENCES players(player_id),

    CHECK (ball_number BETWEEN 1 AND 6),

    CHECK (over_number >= 0),

    CHECK (batsman_runs >= 0),

    CHECK (extras >= 0),

    CHECK (total_runs >= 0),

    CONSTRAINT chk_wicket_details
    CHECK (
        (is_wicket = FALSE AND batsman_out_id IS NULL AND dismissal_type IS NULL)
        OR
        (is_wicket = TRUE AND batsman_out_id IS NOT NULL AND dismissal_type IS NOT NULL)
    ),

    CONSTRAINT chk_dismissal_type
    CHECK (
        dismissal_type IS NULL
        OR dismissal_type IN (
            'Bowled',
            'Caught',
            'LBW',
            'Run Out',
            'Stumped',
            'Hit Wicket',
            'Retired Out'
        )
    ),

    UNIQUE (innings_id, over_number, ball_number),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- TABLE BATTING_SCORECARDS
CREATE TABLE batting_scorecards(
    batting_scorecard_id SERIAL PRIMARY KEY,

    innings_id INT NOT NULL,
    player_id INT NOT NULL,

    batting_position INT NOT NULL,

    runs_scored INT DEFAULT 0,
    balls_faced INT DEFAULT 0,
    fours INT DEFAULT 0,
    sixes INT DEFAULT 0,

    is_not_out BOOLEAN DEFAULT TRUE,

    dismissal_type VARCHAR(30),

    bowler_id INT,
    fielder_id INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_innings_id
    FOREIGN KEY (innings_id)
    REFERENCES innings(innings_id),

    CONSTRAINT fk_player_id
    FOREIGN KEY(player_id)
    REFERENCES players(player_id),

    CONSTRAINT fk_bowler_id
    FOREIGN KEY(bowler_id)
    REFERENCES players(player_id),

    CONSTRAINT fk_fielder_id
    FOREIGN KEY(fielder_id)
    REFERENCES players(player_id),

    CONSTRAINT chk_batting_position
    CHECK (batting_position BETWEEN 1 AND 11),

    CONSTRAINT chk_runs_scored
    CHECK (runs_scored>=0),

    CONSTRAINT chk_balls_faced
    CHECK (balls_faced>=0),

    CONSTRAINT chk_fours
    CHECK (fours>=0),

    CONSTRAINT chk_sixes
    CHECK(sixes>=0),

    CONSTRAINT chk_dismissal_type
    CHECK (
    dismissal_type IS NULL
    OR dismissal_type IN (
        'Bowled',
        'Caught',
        'LBW',
        'Run Out',
        'Stumped',
        'Hit Wicket',
        'Retired Out'
                    )
    ),

    CONSTRAINT chk_not_out
    CHECK (
    (is_not_out = TRUE AND dismissal_type IS NULL)
    OR
    (is_not_out = FALSE AND dismissal_type IS NOT NULL)),

    CHECK (balls_faced > 0 OR runs_scored = 0),

    CHECK ((4 * fours + 6 * sixes) <= runs_scored),

    CONSTRAINT uq_player_innings
    UNIQUE (innings_id, player_id),

    UNIQUE (innings_id, batting_position)

);

-- TABLE BOWLING SCORECRAD
CREATE TABLE bowling_scorecards(
    bowling_scorecard_id SERIAL PRIMARY KEY,
    innings_id INT NOT NULL,
    player_id INT NOT NULL,
    overs_bowled DECIMAL(3, 1) DEFAULT 0.0,
    maidens INT DEFAULT 0,
    runs_conceded INT DEFAULT 0,
    wickets INT DEFAULT 0,
    no_balls INT DEFAULT 0,
    wides INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_innings
    FOREIGN KEY(innings_id)
    REFERENCES innings(innings_id),

    CONSTRAINT fk_player
    FOREIGN KEY(player_id)
    REFERENCES players(player_id),

    CONSTRAINT uq_bowling_player_innings
    UNIQUE (innings_id, player_id),

    CONSTRAINT chk_overs_bowled
    CHECK (overs_bowled >= 0),

    CONSTRAINT chk_maidens
    CHECK (maidens <= overs_bowled),

    CONSTRAINT chk_runs_conceded
    CHECK (runs_conceded >= 0),

    CONSTRAINT chk_no_balls
    CHECK (no_balls >= 0),

    CONSTRAINT chk_wides
    CHECK (wides >= 0),

    CONSTRAINT chk_wickets
    CHECK (wickets BETWEEN 0 AND 10),

    CONSTRAINT chk_runs_vs_overs
    CHECK (
        overs_bowled > 0
        OR runs_conceded = 0
    ),

    CONSTRAINT chk_wickets_vs_overs
    CHECK (
        overs_bowled > 0
        OR wickets = 0
    ),

    CONSTRAINT chk_extras_vs_overs
    CHECK(
        overs_bowled >= 0
        OR (no_balls = 0 AND wides = 0)
    )
);

-- TABLE FALL OF WICKETS
CREATE TABLE fall_of_wickets(
    fall_of_wicket_id SERIAL PRIMARY KEY,

    innings_id INT NOT NULL,
    batsman_out_id INT NOT NULL,

    wicket_number INT NOT NULL,
    score_at_wicket INT NOT NULL,
    over_number DECIMAL(3,1) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_innings
    FOREIGN KEY (innings_id)
    REFERENCES innings(innings_id),

    CONSTRAINT fk_batsman_out
    FOREIGN KEY (batsman_out_id)
    REFERENCES players(player_id),

    CONSTRAINT uq_innings_wicket
    UNIQUE (innings_id, wicket_number),

    CONSTRAINT uq_batsman_out
    UNIQUE (innings_id, batsman_out_id),

    CONSTRAINT chk_wicket_number
    CHECK (wicket_number BETWEEN 1 AND 10),

    CONSTRAINT chk_score_at_wicket
    CHECK (score_at_wicket >= 0),

    CONSTRAINT chk_over_number
    CHECK (over_number >= 0)
);

-- TABLE POINTS_TABLE
CREATE TABLE points_table(
    points_table_id SERIAL PRIMARY KEY,

    tournament_id INT NOT NULL,
    team_id INT NOT NULL,

    matches_played INT DEFAULT 0,
    wins INT DEFAULT 0,
    losses INT DEFAULT 0,
    ties INT DEFAULT 0,
    no_results INT DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_points_tournament
    FOREIGN KEY (tournament_id)
    REFERENCES tournaments(tournament_id),

    CONSTRAINT fk_points_team
    FOREIGN KEY (team_id)
    REFERENCES teams(team_id),

    CONSTRAINT uq_tournament_team
    UNIQUE (tournament_id, team_id),

    CONSTRAINT chk_matches_played
    CHECK (matches_played >= 0),

    CONSTRAINT chk_wins
    CHECK (wins >= 0),

    CONSTRAINT chk_losses
    CHECK (losses >= 0),

    CONSTRAINT chk_ties
    CHECK (ties >= 0),

    CONSTRAINT chk_no_results
    CHECK (no_results >= 0),

    CONSTRAINT chk_matches_consistency
    CHECK (
        matches_played =
        wins + losses + ties + no_results
    )
);

