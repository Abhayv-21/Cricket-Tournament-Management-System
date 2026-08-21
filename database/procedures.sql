-- PROCEDURE RECIRD_BALL
CREATE OR REPLACE PROCEDURE record_ball(
    p_innings_id INT,
    p_over_number INT,
    p_ball_number INT,
    p_striker_id INT,
    p_non_striker_id INT,
    p_bowler_id INT,
    p_batsman_runs INT,
    p_extras INT,
    p_extra_type VARCHAR(20),
    p_is_wicket BOOLEAN,
    p_batsman_out_id INT,
    p_dismissal_type VARCHAR(50),
    p_fielder_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_striker_id = p_non_striker_id THEN
        RAISE EXCEPTION 'Striker and non-striker cannot be the same player';
    END IF;

    IF p_striker_id = p_bowler_id THEN
        RAISE EXCEPTION 'Bowler cannot be the striker';
    END IF;

    IF p_non_striker_id = p_bowler_id THEN
        RAISE EXCEPTION 'Bowler cannot be the non striker';
    END IF;

    INSERT INTO ball_events(
        innings_id,
        over_number,
        ball_number,
        striker_id,
        non_striker_id,
        bowler_id,
        batsman_runs,
        extras,
        total_runs,
        extra_type,
        is_wicket,
        batsman_out_id,
        dismissal_type,
        fielder_id
    )
    VALUES (
        p_innings_id,
        p_over_number,
        p_ball_number,
        p_striker_id,
        p_non_striker_id,
        p_bowler_id,
        p_batsman_runs,
        p_extras,
        p_batsman_runs + p_extras,
        p_extra_type,
        p_is_wicket,
        p_batsman_out_id,
        p_dismissal_type,
        p_fielder_id
    );
END;
$$;

-- PROCEDURE START_INNINGS
CREATE OR REPLACE PROCEDURE start_innings(
    p_match_id INT,
    p_innings_no INT,
    p_batting_team_id INT,
    p_bowling_team_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Check that match exists
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;


    -- Check that innings number is valid
    IF p_innings_no NOT IN (1, 2) THEN
        RAISE EXCEPTION 'Innings number must be 1 or 2.';
    END IF;


    -- Check that teams are different
    IF p_batting_team_id = p_bowling_team_id THEN
        RAISE EXCEPTION 'Batting and bowling teams must be different.';
    END IF;


    -- Check that both teams are actually playing this match
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
          AND (
              (team1_id = p_batting_team_id AND team2_id = p_bowling_team_id)
              OR
              (team1_id = p_bowling_team_id AND team2_id = p_batting_team_id)
          )
    ) THEN
        RAISE EXCEPTION 'Invalid batting and bowling teams for this match.';
    END IF;


    -- Check that innings does not already exist
    IF EXISTS (
        SELECT 1
        FROM innings
        WHERE match_id = p_match_id
          AND innings_no = p_innings_no
    ) THEN
        RAISE EXCEPTION 'This innings has already been started.';
    END IF;


    -- Check batting team has exactly 11 players in playing XI
    IF (
        SELECT COUNT(*)
        FROM match_squads
        WHERE match_id = p_match_id
          AND team_id = p_batting_team_id
          AND is_playing_xi = TRUE
    ) <> 11 THEN
        RAISE EXCEPTION 'Batting team must have exactly 11 players in the playing XI.';
    END IF;


    -- Check bowling team has exactly 11 players in playing XI
    IF (
        SELECT COUNT(*)
        FROM match_squads
        WHERE match_id = p_match_id
          AND team_id = p_bowling_team_id
          AND is_playing_xi = TRUE
    ) <> 11 THEN
        RAISE EXCEPTION 'Bowling team must have exactly 11 players in the playing XI.';
    END IF;


    -- Create innings
    INSERT INTO innings(
        match_id,
        innings_no,
        batting_team_id,
        bowling_team_id,
        total_runs,
        total_wickets,
        extras,
        overs_completed
    )
    VALUES (
        p_match_id,
        p_innings_no,
        p_batting_team_id,
        p_bowling_team_id,
        0,
        0,
        0,
        0.0
    );


    -- Create batting scorecard for all 11 batsmen
    INSERT INTO batting_scorecards(
        innings_id,
        player_id,
        batting_position
    )
    SELECT
        i.innings_id,
        ms.player_id,
        ms.batting_position
    FROM innings i
    JOIN match_squads ms
        ON ms.match_id = p_match_id
       AND ms.team_id = p_batting_team_id
       AND ms.is_playing_xi = TRUE
    WHERE i.match_id = p_match_id
      AND i.innings_no = p_innings_no;


    -- Create bowling scorecard for all 11 players
    INSERT INTO bowling_scorecards(
        innings_id,
        player_id
    )
    SELECT
        i.innings_id,
        ms.player_id
    FROM innings i
    JOIN match_squads ms
        ON ms.match_id = p_match_id
       AND ms.team_id = p_bowling_team_id
       AND ms.is_playing_xi = TRUE
    WHERE i.match_id = p_match_id
      AND i.innings_no = p_innings_no;


END;
$$;

-- -- PROCEDURE end_match
CREATE OR REPLACE PROCEDURE end_match(
    p_match_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tournament_id INT;
    v_team1_id INT;
    v_team2_id INT;
    v_team1_runs INT;
    v_team2_runs INT;
    v_winner_team_id INT;
BEGIN

    -- Check whether match exists
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;


    -- Prevent ending an already completed match
    IF EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
          AND status = 'Completed'
    ) THEN
        RAISE EXCEPTION 'Match has already been completed.';
    END IF;


    -- Get match details
    SELECT
        tournament_id,
        team1_id,
        team2_id
    INTO
        v_tournament_id,
        v_team1_id,
        v_team2_id
    FROM matches
    WHERE match_id = p_match_id;


    -- Check whether both innings exist
    IF (
        SELECT COUNT(*)
        FROM innings
        WHERE match_id = p_match_id
    ) < 2 THEN
        RAISE EXCEPTION
            'Both innings must be completed before ending the match.';
    END IF;


    -- Get Team 1 score
    SELECT total_runs
    INTO v_team1_runs
    FROM innings
    WHERE match_id = p_match_id
      AND innings_no = 1;


    -- Get Team 2 score
    SELECT total_runs
    INTO v_team2_runs
    FROM innings
    WHERE match_id = p_match_id
      AND innings_no = 2;


    -- Determine winner
    IF v_team1_runs > v_team2_runs THEN

        v_winner_team_id := v_team1_id;

        UPDATE matches
        SET
            status = 'Completed',
            winner_team_id = v_winner_team_id,
            match_result = 'Team Won'
        WHERE match_id = p_match_id;


    ELSIF v_team2_runs > v_team1_runs THEN

        v_winner_team_id := v_team2_id;

        UPDATE matches
        SET
            status = 'Completed',
            winner_team_id = v_winner_team_id,
            match_result = 'Team Won'
        WHERE match_id = p_match_id;


    ELSE

        UPDATE matches
        SET
            status = 'Completed',
            winner_team_id = NULL,
            match_result = 'Tie'
        WHERE match_id = p_match_id;

    END IF;


    -- Automatically update points table
    CALL update_points_table(p_match_id);


END;
$$;

-- PROCEDURE conduct_toss
CREATE OR REPLACE PROCEDURE conduct_toss(
    p_match_id INT,
    p_toss_winner_id INT,
    p_toss_decision VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- check if match exists
    IF NOT EXISTS(
        SELECT 1 FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;

    -- check if toss winner is one of the playing teams
    IF NOT EXISTS(
        SELECT 1 FROM matches
        WHERE match_id = p_match_id
            AND(
                team1_id = p_toss_winner_id
                OR team2_id = p_toss_winner_id
            )
    )THEN
        RAISE EXCEPTION 'Toss winner must be one of the teams playing the match';
    END IF;

    -- check toss decision
    IF p_toss_decision NOT IN ('Batting', 'Bowling') THEN
        RAISE EXCEPTION 'Toss decision must be batting or bowling';
    END IF;


    -- check if toss is already conducted
    IF EXISTS(
        SELECT 1 FROM matches
        WHERE match_id = p_match_id
            AND toss_winner_id IS NOT NULL
    )THEN
        RAISE EXCEPTION 'Toss has already been done';
    END IF;

    -- updating toss details
    UPDATE matches
    SET
        toss_winner_id = p_toss_winner_id,
        toss_decision = p_toss_decision
    WHERE match_id = p_match_id;

END;
$$;

-- PROCEDURE add_playing_xi
CREATE OR REPLACE PROCEDURE add_playing_xi(
    p_match_id INT,
    p_player_id INT,
    p_team_id INT,
    p_is_captain BOOLEAN DEFAULT FALSE,
    p_is_wicket_keeper BOOLEAN DEFAULT FALSE,
    p_batting_position INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN

    -- Check if match exists
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;


    -- Check if player exists
    IF NOT EXISTS (
        SELECT 1
        FROM players
        WHERE player_id = p_player_id
    ) THEN
        RAISE EXCEPTION 'Player does not exist.';
    END IF;


    -- Check if team exists
    IF NOT EXISTS (
        SELECT 1
        FROM teams
        WHERE team_id = p_team_id
    ) THEN
        RAISE EXCEPTION 'Team does not exist.';
    END IF;


    -- Check if player belongs to the team
    IF NOT EXISTS (
        SELECT 1
        FROM players
        WHERE player_id = p_player_id
          AND team_id = p_team_id
    ) THEN
        RAISE EXCEPTION 'Player does not belong to this team.';
    END IF;


    -- Check if player is already added to this match
    IF EXISTS (
        SELECT 1
        FROM match_squads
        WHERE match_id = p_match_id
          AND player_id = p_player_id
    ) THEN
        RAISE EXCEPTION 'Player is already added to this match.';
    END IF;


    -- Check whether team already has 11 players in playing XI
    IF (
        SELECT COUNT(*)
        FROM match_squads
        WHERE match_id = p_match_id
          AND team_id = p_team_id
          AND is_playing_xi = TRUE
    ) >= 11 THEN
        RAISE EXCEPTION 'This team already has 11 players in the playing XI.';
    END IF;


    -- Check batting position
    IF p_batting_position IS NOT NULL THEN

        IF EXISTS (
            SELECT 1
            FROM match_squads
            WHERE match_id = p_match_id
              AND team_id = p_team_id
              AND batting_position = p_batting_position
        ) THEN
            RAISE EXCEPTION 'This batting position is already occupied.';
        END IF;

    END IF;


    -- Check captain
    IF p_is_captain = TRUE THEN

        IF EXISTS (
            SELECT 1
            FROM match_squads
            WHERE match_id = p_match_id
              AND team_id = p_team_id
              AND is_captain = TRUE
        ) THEN
            RAISE EXCEPTION 'This team already has a captain.';
        END IF;

    END IF;


    -- Insert player into match squad
    INSERT INTO match_squads (
        match_id,
        player_id,
        team_id,
        is_playing_xi,
        is_captain,
        is_wicket_keeper,
        batting_position
    )
    VALUES (
        p_match_id,
        p_player_id,
        p_team_id,
        TRUE,
        p_is_captain,
        p_is_wicket_keeper,
        p_batting_position
    );

END;
$$;

-- PROCEDURE START_MATCH
CREATE OR REPLACE PROCEDURE start_match(
    p_match_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_team1_id INT;
    v_team2_id INT;
BEGIN

    -- Check if match exists
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;


    -- Get the two teams
    SELECT team1_id, team2_id
    INTO v_team1_id, v_team2_id
    FROM matches
    WHERE match_id = p_match_id;


    -- Check match status
    IF (
        SELECT status
        FROM matches
        WHERE match_id = p_match_id
    ) <> 'Scheduled' THEN
        RAISE EXCEPTION 'Only a scheduled match can be started.';
    END IF;


    -- Check whether toss has been conducted
    IF (
        SELECT toss_winner_id
        FROM matches
        WHERE match_id = p_match_id
    ) IS NULL THEN
        RAISE EXCEPTION 'Toss must be conducted before starting the match.';
    END IF;


    -- Check Team 1 playing XI
    IF (
        SELECT COUNT(*)
        FROM match_squads
        WHERE match_id = p_match_id
          AND team_id = v_team1_id
          AND is_playing_xi = TRUE
    ) <> 11 THEN
        RAISE EXCEPTION 'Team 1 must have exactly 11 players in the playing XI.';
    END IF;


    -- Check Team 2 playing XI
    IF (
        SELECT COUNT(*)
        FROM match_squads
        WHERE match_id = p_match_id
          AND team_id = v_team2_id
          AND is_playing_xi = TRUE
    ) <> 11 THEN
        RAISE EXCEPTION 'Team 2 must have exactly 11 players in the playing XI.';
    END IF;


    -- Start the match
    UPDATE matches
    SET status = 'Live'
    WHERE match_id = p_match_id;

END;
$$;

-- PROCEDURE initialize_points_table
CREATE OR REPLACE PROCEDURE initialize_points_table(
    p_tournament_id INT
)
LANGUAGE plpgsql
-- AS $$
BEGIN

    -- Checking if tournament exists
    IF NOT EXISTS (
        SELECT 1
        FROM tournaments
        WHERE tournament_id = p_tournament_id
    ) THEN
        RAISE EXCEPTION 'Tournament does not exist.';
    END IF;

    -- Inserting one points-table row for every team
    -- that belongs to this tournament
    INSERT INTO points_table (
        tournament_id,
        team_id
    )
    SELECT
        p_tournament_id,
        team_id
    FROM teams
    WHERE tournament_id = p_tournament_id
    ON CONFLICT (tournament_id, team_id)
    DO NOTHING;

END;
$$;

-- PROCEDURE update_points_table
CREATE OR REPLACE PROCEDURE update_points_table(
    p_match_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tournament_id INT;
    v_team1_id INT;
    v_team2_id INT;
    v_winner_team_id INT;
    v_match_result VARCHAR(20);
BEGIN

    -- Check whether match exists
    IF NOT EXISTS (
        SELECT 1
        FROM matches
        WHERE match_id = p_match_id
    ) THEN
        RAISE EXCEPTION 'Match does not exist.';
    END IF;


    -- Get match details
    SELECT
        tournament_id,
        team1_id,
        team2_id,
        winner_team_id,
        match_result
    INTO
        v_tournament_id,
        v_team1_id,
        v_team2_id,
        v_winner_team_id,
        v_match_result
    FROM matches
    WHERE match_id = p_match_id;


    -- Match must be completed
    IF v_match_result IS NULL
       OR v_match_result = 'Pending' THEN
        RAISE EXCEPTION
            'Match must be completed before updating points table.';
    END IF;


    -- Make sure points-table rows exist
    CALL initialize_points_table(v_tournament_id);


    -- TEAM WON
    IF v_match_result = 'Team Won' THEN

        -- Winner
        UPDATE points_table
        SET
            matches_played = matches_played + 1,
            wins = wins + 1
        WHERE tournament_id = v_tournament_id
          AND team_id = v_winner_team_id;


        -- Loser
        UPDATE points_table
        SET
            matches_played = matches_played + 1,
            losses = losses + 1
        WHERE tournament_id = v_tournament_id
          AND team_id <> v_winner_team_id
          AND team_id IN (v_team1_id, v_team2_id);


    -- TIE
    ELSIF v_match_result = 'Tie' THEN

        UPDATE points_table
        SET
            matches_played = matches_played + 1,
            ties = ties + 1
        WHERE tournament_id = v_tournament_id
          AND team_id IN (v_team1_id, v_team2_id);


    -- NO RESULT
    ELSIF v_match_result = 'No Result' THEN

        UPDATE points_table
        SET
            matches_played = matches_played + 1,
            no_results = no_results + 1
        WHERE tournament_id = v_tournament_id
          AND team_id IN (v_team1_id, v_team2_id);

    END IF;

END;
$$;