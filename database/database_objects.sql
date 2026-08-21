--
-- PostgreSQL database dump
--

\restrict D4XDyaDspTY2REqETSw3Gx3ogkUlyLeacgvOkRz3NeqMBogNHETZVZ9fGg14GT3

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: add_playing_xi(integer, integer, integer, boolean, boolean, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.add_playing_xi(IN p_match_id integer, IN p_player_id integer, IN p_team_id integer, IN p_is_captain boolean DEFAULT false, IN p_is_wicket_keeper boolean DEFAULT false, IN p_batting_position integer DEFAULT NULL::integer)
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


--
-- Name: conduct_toss(integer, integer, character varying); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.conduct_toss(IN p_match_id integer, IN p_toss_winner_id integer, IN p_toss_decision character varying)
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


--
-- Name: end_match(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.end_match(IN p_match_id integer)
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


--
-- Name: initialize_points_table(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.initialize_points_table(IN p_tournament_id integer)
    LANGUAGE plpgsql
    AS $$
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


--
-- Name: insert_fall_of_wickets(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.insert_fall_of_wickets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF NEW.is_wicket = TRUE THEN

        INSERT INTO fall_of_wickets(
            innings_id,
            batsman_out_id,
            wicket_number,
            score_at_wicket,
            over_number
        )
        SELECT
            i.innings_id,
            NEW.batsman_out_id,
            i.total_wickets+1,
            i.total_runs + NEW.total_runs,
            NEW.over_number + (NEW.ball_number / 10.0)
        FROM innings i
        WHERE i.innings_id = NEW.innings_id;

    END IF;

    RETURN NEW;

END;
$$;


--
-- Name: record_ball(integer, integer, integer, integer, integer, integer, integer, integer, character varying, boolean, integer, character varying, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.record_ball(IN p_innings_id integer, IN p_over_number integer, IN p_ball_number integer, IN p_striker_id integer, IN p_non_striker_id integer, IN p_bowler_id integer, IN p_batsman_runs integer, IN p_extras integer, IN p_extra_type character varying, IN p_is_wicket boolean, IN p_batsman_out_id integer, IN p_dismissal_type character varying, IN p_fielder_id integer)
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


--
-- Name: start_innings(integer, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.start_innings(IN p_match_id integer, IN p_innings_no integer, IN p_batting_team_id integer, IN p_bowling_team_id integer)
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


--
-- Name: start_match(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.start_match(IN p_match_id integer)
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


--
-- Name: update_batting_scorecard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_batting_scorecard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE batting_scorecards
    SET
        runs_scored = runs_scored + NEW.batsman_runs,
        balls_faced = balls_faced + CASE
                                        WHEN NEW.extra_type = 'Wide'
                                        THEN 0
                                        ELSE 1
                                    END,

        fours = fours + CASE
                            WHEN NEW.batsman_runs = 4
                            THEN 1
                            ELSE 0
                        END,

        sixes = sixes + CASE
                            WHEN NEW.batsman_runs = 6
                            THEN 1
                            ELSE 0
                        END
        WHERE
            innings_id = NEW.innings_id
            AND player_id = NEW.striker_id;
        RETURN NEW;
END;
$$;


--
-- Name: update_bowling_scorecard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_bowling_scorecard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_is_legal   boolean;
    v_cur_overs  numeric(3,1);
    v_whole      int;
    v_balls      int;
    v_new_overs  numeric(3,1);
BEGIN
    v_is_legal := NEW.extra_type IS NULL OR NEW.extra_type NOT IN ('Wide', 'No Ball');

    SELECT overs_bowled INTO v_cur_overs
    FROM bowling_scorecards
    WHERE innings_id = NEW.innings_id
      AND player_id = NEW.bowler_id
    FOR UPDATE;

    v_whole := TRUNC(v_cur_overs);
    v_balls := ROUND((v_cur_overs - v_whole) * 10)::int;

    IF v_is_legal THEN
        v_balls := v_balls + 1;
        IF v_balls = 6 THEN
            v_whole := v_whole + 1;
            v_balls := 0;
        END IF;
    END IF;

    v_new_overs := v_whole + (v_balls / 10.0);

    UPDATE bowling_scorecards
    SET
        runs_conceded = runs_conceded +
            CASE
                WHEN NEW.extra_type IN ('Bye', 'Leg Bye') THEN 0
                ELSE NEW.total_runs
            END,

        overs_bowled = v_new_overs,

        wickets = wickets +
            CASE
                WHEN NEW.is_wicket = TRUE
                 AND NEW.dismissal_type IN ('Bowled', 'Caught', 'LBW', 'Hit Wicket', 'Stumped')
                THEN 1
                ELSE 0
            END,

        wides = wides +
            CASE WHEN NEW.extra_type = 'Wide' THEN NEW.extras ELSE 0 END,

        no_balls = no_balls +
            CASE WHEN NEW.extra_type = 'No Ball' THEN NEW.extras ELSE 0 END

    WHERE innings_id = NEW.innings_id
      AND player_id = NEW.bowler_id;

    RETURN NEW;
END;
$$;


--
-- Name: update_bowling_socrecard(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_bowling_socrecard() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE bowling_scorecards
    SET
        runs_conceded = runs_conceded +
            CASE
                WHEN NEW.extra_type IN ('Bye', 'Leg Bye')
                THEN NEW.batsman_runs
                ELSE NEW.total_runs
            END,
        wickets = wickets +
            CASE
                WHEN NEW.is_wicket = TRUE
                    AND NEW.dismissal_type IN
                        ('Bowled', 'Caught', 'LBW', 'Hit Wicket')
                THEN 1
                ELSE 0
            END,
        wides = wides +
            CASE
                WHEN NEW.extra_type = 'Wide'
                THEN NEW.extras
                ELSE 0
            END,
        no_balls = no_balls +
            CASE
                WHEN NEW.extra_type = 'No Ball'
                THEN NEW.extras
                ELSE 0
            END

    WHERE
        innings_id = NEW.innings_id
        AND player_id = NEW.bowler_id;

    RETURN NEW;
END;
$$;


--
-- Name: update_innings_score(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_innings_score() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_legal_balls INTEGER;
BEGIN

    -- Count only legal deliveries
    SELECT COUNT(*)
    INTO v_legal_balls
    FROM ball_events
    WHERE innings_id = NEW.innings_id
      AND (
          extra_type IS NULL
          OR extra_type NOT IN ('Wide', 'No Ball')
      );

    -- Recalculate innings score
    UPDATE innings
    SET
        total_runs = (
            SELECT COALESCE(SUM(total_runs), 0)
            FROM ball_events
            WHERE innings_id = NEW.innings_id
        ),

        total_wickets = (
            SELECT COUNT(*)
            FROM ball_events
            WHERE innings_id = NEW.innings_id
              AND is_wicket = TRUE
        ),

        extras = (
            SELECT COALESCE(SUM(extras), 0)
            FROM ball_events
            WHERE innings_id = NEW.innings_id
        ),

        overs_completed =
            (v_legal_balls / 6)::INTEGER
            + ((v_legal_balls % 6)::NUMERIC / 10)

    WHERE innings_id = NEW.innings_id;

    RETURN NEW;
END;
$$;


--
-- Name: update_points_table(integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.update_points_table(IN p_match_id integer)
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ball_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ball_events (
    ball_event_id integer NOT NULL,
    innings_id integer NOT NULL,
    over_number integer NOT NULL,
    ball_number integer NOT NULL,
    striker_id integer NOT NULL,
    non_striker_id integer NOT NULL,
    bowler_id integer NOT NULL,
    batsman_runs integer NOT NULL,
    extras integer NOT NULL,
    total_runs integer NOT NULL,
    is_wicket boolean DEFAULT false,
    batsman_out_id integer,
    dismissal_type character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    fielder_id integer,
    extra_type character varying(20),
    CONSTRAINT ball_events_ball_number_check CHECK (((ball_number >= 1) AND (ball_number <= 6))),
    CONSTRAINT ball_events_batsman_runs_check CHECK ((batsman_runs >= 0)),
    CONSTRAINT ball_events_extras_check CHECK ((extras >= 0)),
    CONSTRAINT ball_events_over_number_check CHECK ((over_number >= 0)),
    CONSTRAINT ball_events_total_runs_check CHECK ((total_runs >= 0)),
    CONSTRAINT chk_dismissal_type CHECK (((dismissal_type IS NULL) OR ((dismissal_type)::text = ANY ((ARRAY['Bowled'::character varying, 'Caught'::character varying, 'LBW'::character varying, 'Run Out'::character varying, 'Stumped'::character varying, 'Hit Wicket'::character varying, 'Retired Out'::character varying])::text[])))),
    CONSTRAINT chk_extra_type CHECK (((extra_type IS NULL) OR ((extra_type)::text = ANY ((ARRAY['Wide'::character varying, 'No Ball'::character varying, 'Bye'::character varying, 'Leg Bye'::character varying])::text[])))),
    CONSTRAINT chk_wicket_details CHECK ((((is_wicket = false) AND (batsman_out_id IS NULL) AND (dismissal_type IS NULL)) OR ((is_wicket = true) AND (batsman_out_id IS NOT NULL) AND (dismissal_type IS NOT NULL))))
);


--
-- Name: ball_events_ball_event_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ball_events_ball_event_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ball_events_ball_event_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ball_events_ball_event_id_seq OWNED BY public.ball_events.ball_event_id;


--
-- Name: batting_scorecards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.batting_scorecards (
    batting_scorecard_id integer NOT NULL,
    innings_id integer NOT NULL,
    player_id integer NOT NULL,
    batting_position integer NOT NULL,
    runs_scored integer DEFAULT 0,
    balls_faced integer DEFAULT 0,
    fours integer DEFAULT 0,
    sixes integer DEFAULT 0,
    is_not_out boolean DEFAULT true,
    dismissal_type character varying(30),
    bowler_id integer,
    fielder_id integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT batting_scorecards_check CHECK (((balls_faced > 0) OR (runs_scored = 0))),
    CONSTRAINT batting_scorecards_check1 CHECK ((((4 * fours) + (6 * sixes)) <= runs_scored)),
    CONSTRAINT chk_balls_faced CHECK ((balls_faced >= 0)),
    CONSTRAINT chk_batting_position CHECK (((batting_position >= 1) AND (batting_position <= 11))),
    CONSTRAINT chk_dismissal_type CHECK (((dismissal_type IS NULL) OR ((dismissal_type)::text = ANY ((ARRAY['Bowled'::character varying, 'Caught'::character varying, 'LBW'::character varying, 'Run Out'::character varying, 'Stumped'::character varying, 'Hit Wicket'::character varying, 'Retired Out'::character varying])::text[])))),
    CONSTRAINT chk_fours CHECK ((fours >= 0)),
    CONSTRAINT chk_not_out CHECK ((((is_not_out = true) AND (dismissal_type IS NULL)) OR ((is_not_out = false) AND (dismissal_type IS NOT NULL)))),
    CONSTRAINT chk_runs_scored CHECK ((runs_scored >= 0)),
    CONSTRAINT chk_sixes CHECK ((sixes >= 0))
);


--
-- Name: batting_scorecards_batting_scorecard_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.batting_scorecards_batting_scorecard_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: batting_scorecards_batting_scorecard_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.batting_scorecards_batting_scorecard_id_seq OWNED BY public.batting_scorecards.batting_scorecard_id;


--
-- Name: bowling_scorecards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bowling_scorecards (
    bowling_scorecard_id integer NOT NULL,
    innings_id integer NOT NULL,
    player_id integer NOT NULL,
    overs_bowled numeric(3,1) DEFAULT 0.0,
    maidens integer DEFAULT 0,
    runs_conceded integer DEFAULT 0,
    wickets integer DEFAULT 0,
    no_balls integer DEFAULT 0,
    wides integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_extras_vs_overs CHECK (((overs_bowled >= (0)::numeric) OR ((no_balls = 0) AND (wides = 0)))),
    CONSTRAINT chk_maidens CHECK (((maidens)::numeric <= overs_bowled)),
    CONSTRAINT chk_no_balls CHECK ((no_balls >= 0)),
    CONSTRAINT chk_overs_bowled CHECK ((overs_bowled >= (0)::numeric)),
    CONSTRAINT chk_runs_conceded CHECK ((runs_conceded >= 0)),
    CONSTRAINT chk_runs_vs_overs CHECK (((overs_bowled > (0)::numeric) OR (runs_conceded = 0))),
    CONSTRAINT chk_wickets CHECK (((wickets >= 0) AND (wickets <= 10))),
    CONSTRAINT chk_wickets_vs_overs CHECK (((overs_bowled > (0)::numeric) OR (wickets = 0))),
    CONSTRAINT chk_wides CHECK ((wides >= 0))
);


--
-- Name: bowling_scorecards_bowling_scorecard_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bowling_scorecards_bowling_scorecard_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bowling_scorecards_bowling_scorecard_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bowling_scorecards_bowling_scorecard_id_seq OWNED BY public.bowling_scorecards.bowling_scorecard_id;


--
-- Name: fall_of_wickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fall_of_wickets (
    fall_of_wicket_id integer NOT NULL,
    innings_id integer NOT NULL,
    batsman_out_id integer NOT NULL,
    wicket_number integer NOT NULL,
    score_at_wicket integer NOT NULL,
    over_number numeric(3,1) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_over_number CHECK ((over_number >= (0)::numeric)),
    CONSTRAINT chk_score_at_wicket CHECK ((score_at_wicket >= 0)),
    CONSTRAINT chk_wicket_number CHECK (((wicket_number >= 1) AND (wicket_number <= 10)))
);


--
-- Name: fall_of_wickets_fall_of_wicket_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fall_of_wickets_fall_of_wicket_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fall_of_wickets_fall_of_wicket_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fall_of_wickets_fall_of_wicket_id_seq OWNED BY public.fall_of_wickets.fall_of_wicket_id;


--
-- Name: innings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.innings (
    innings_id integer NOT NULL,
    match_id integer NOT NULL,
    innings_no integer NOT NULL,
    batting_team_id integer NOT NULL,
    bowling_team_id integer NOT NULL,
    total_runs integer DEFAULT 0,
    total_wickets integer DEFAULT 0,
    overs_completed numeric(4,1) DEFAULT 0.0,
    extras integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_innings_no CHECK ((innings_no = ANY (ARRAY[1, 2]))),
    CONSTRAINT innings_check CHECK ((batting_team_id <> bowling_team_id))
);


--
-- Name: innings_innings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.innings_innings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: innings_innings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.innings_innings_id_seq OWNED BY public.innings.innings_id;


--
-- Name: match_squads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.match_squads (
    match_id integer NOT NULL,
    player_id integer NOT NULL,
    team_id integer NOT NULL,
    is_playing_xi boolean DEFAULT true,
    is_captain boolean DEFAULT false,
    is_wicket_keeper boolean DEFAULT false,
    batting_position integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_batting_position CHECK ((((batting_position >= 1) AND (batting_position <= 11)) OR (batting_position IS NULL)))
);


--
-- Name: matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.matches (
    match_id integer NOT NULL,
    tournament_id integer NOT NULL,
    team1_id integer NOT NULL,
    team2_id integer NOT NULL,
    venue_id integer NOT NULL,
    match_date date NOT NULL,
    status character varying(50) DEFAULT 'Scheduled'::character varying,
    winner_team_id integer,
    toss_winner_id integer,
    toss_decision character varying(50),
    match_result character varying(20),
    match_time time without time zone NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT matches_check CHECK ((team1_id <> team2_id)),
    CONSTRAINT matches_check1 CHECK (((winner_team_id IS NULL) OR (winner_team_id = team1_id) OR (winner_team_id = team2_id))),
    CONSTRAINT matches_match_result_check CHECK (((match_result)::text = ANY ((ARRAY['Pending'::character varying, 'Team Won'::character varying, 'Tie'::character varying, 'No Result'::character varying])::text[]))),
    CONSTRAINT matches_status_check CHECK (((status)::text = ANY ((ARRAY['Scheduled'::character varying, 'Live'::character varying, 'Completed'::character varying, 'Cancelled'::character varying])::text[]))),
    CONSTRAINT matches_toss_decision_check CHECK (((toss_decision)::text = ANY ((ARRAY['Batting'::character varying, 'Bowling'::character varying])::text[])))
);


--
-- Name: matches_match_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.matches_match_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: matches_match_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.matches_match_id_seq OWNED BY public.matches.match_id;


--
-- Name: players; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.players (
    player_id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    dob date NOT NULL,
    nationality character varying(50) NOT NULL,
    batting_style character varying(50),
    bowling_style character varying(50),
    player_role character varying(50),
    jersey_number integer NOT NULL,
    email character varying(100),
    phone_number character varying(15) NOT NULL,
    height_cm numeric(5,2),
    weight_kg numeric(5,2),
    team_id integer,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT players_batting_style_check CHECK (((batting_style)::text = ANY ((ARRAY['Right-hand Bat'::character varying, 'Left-Hand Bat'::character varying])::text[]))),
    CONSTRAINT players_bowling_style_check CHECK (((bowling_style)::text = ANY ((ARRAY['Right-arm Fast'::character varying, 'Left-arm Fast'::character varying, 'Right-arm Medium'::character varying, 'Left-arm Medium'::character varying, 'Right-arm Spin'::character varying, 'Left-arm Spin'::character varying])::text[]))),
    CONSTRAINT players_height_cm_check CHECK ((height_cm > (0)::numeric)),
    CONSTRAINT players_jersey_number_check CHECK ((jersey_number > 0)),
    CONSTRAINT players_player_role_check CHECK (((player_role)::text = ANY ((ARRAY['Batsman'::character varying, 'Bowler'::character varying, 'All-Rounder'::character varying, 'Wicket-Keeper'::character varying])::text[]))),
    CONSTRAINT players_weight_kg_check CHECK ((weight_kg > (0)::numeric))
);


--
-- Name: players_player_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.players_player_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: players_player_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.players_player_id_seq OWNED BY public.players.player_id;


--
-- Name: points_table; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.points_table (
    points_table_id integer NOT NULL,
    tournament_id integer NOT NULL,
    team_id integer NOT NULL,
    matches_played integer DEFAULT 0,
    wins integer DEFAULT 0,
    losses integer DEFAULT 0,
    ties integer DEFAULT 0,
    no_results integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_losses CHECK ((losses >= 0)),
    CONSTRAINT chk_matches_consistency CHECK ((matches_played = (((wins + losses) + ties) + no_results))),
    CONSTRAINT chk_matches_played CHECK ((matches_played >= 0)),
    CONSTRAINT chk_no_results CHECK ((no_results >= 0)),
    CONSTRAINT chk_ties CHECK ((ties >= 0)),
    CONSTRAINT chk_wins CHECK ((wins >= 0))
);


--
-- Name: points_table_points_table_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.points_table_points_table_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: points_table_points_table_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.points_table_points_table_id_seq OWNED BY public.points_table.points_table_id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    role_name character varying(30) NOT NULL
);


--
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- Name: teams; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teams (
    team_id integer NOT NULL,
    team_name character varying(100) NOT NULL,
    short_name character varying(10) NOT NULL,
    owner_name character varying(100) NOT NULL,
    coach_name character varying(100) NOT NULL,
    captain_id integer,
    home_venue_id integer,
    tournament_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: teams_team_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teams_team_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teams_team_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teams_team_id_seq OWNED BY public.teams.team_id;


--
-- Name: tournaments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tournaments (
    tournament_id integer NOT NULL,
    tournament_name character varying(100) NOT NULL,
    season integer,
    start_date date,
    location character varying(100),
    status character varying(20),
    CONSTRAINT tournaments_status_check CHECK (((status)::text = ANY ((ARRAY['Upcoming'::character varying, 'Ongoing'::character varying, 'Completed'::character varying])::text[])))
);


--
-- Name: tournaments_tournament_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tournaments_tournament_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tournaments_tournament_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tournaments_tournament_id_seq OWNED BY public.tournaments.tournament_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    full_name character varying(100) NOT NULL,
    email character varying(100) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: venues; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.venues (
    venue_id integer NOT NULL,
    venue_name character varying(100) NOT NULL,
    city character varying(100) NOT NULL,
    state character varying(100),
    country character varying(100) DEFAULT 'INDIA'::character varying,
    capacity integer,
    pitch_type character varying(30),
    tournament_id integer
);


--
-- Name: venues_venue_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.venues_venue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: venues_venue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.venues_venue_id_seq OWNED BY public.venues.venue_id;


--
-- Name: ball_events ball_event_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ball_events ALTER COLUMN ball_event_id SET DEFAULT nextval('public.ball_events_ball_event_id_seq'::regclass);


--
-- Name: batting_scorecards batting_scorecard_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.batting_scorecards ALTER COLUMN batting_scorecard_id SET DEFAULT nextval('public.batting_scorecards_batting_scorecard_id_seq'::regclass);


--
-- Name: bowling_scorecards bowling_scorecard_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bowling_scorecards ALTER COLUMN bowling_scorecard_id SET DEFAULT nextval('public.bowling_scorecards_bowling_scorecard_id_seq'::regclass);


--
-- Name: fall_of_wickets fall_of_wicket_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fall_of_wickets ALTER COLUMN fall_of_wicket_id SET DEFAULT nextval('public.fall_of_wickets_fall_of_wicket_id_seq'::regclass);


--
-- Name: innings innings_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.innings ALTER COLUMN innings_id SET DEFAULT nextval('public.innings_innings_id_seq'::regclass);


--
-- Name: matches match_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.matches ALTER COLUMN match_id SET DEFAULT nextval('public.matches_match_id_seq'::regclass);


--
-- Name: players player_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.players ALTER COLUMN player_id SET DEFAULT nextval('public.players_player_id_seq'::regclass);


--
-- Name: points_table points_table_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.points_table ALTER COLUMN points_table_id SET DEFAULT nextval('public.points_table_points_table_id_seq'::regclass);


--
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- Name: teams team_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teams ALTER COLUMN team_id SET DEFAULT nextval('public.teams_team_id_seq'::regclass);


--
-- Name: tournaments tournament_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tournaments ALTER COLUMN tournament_id SET DEFAULT nextval('public.tournaments_tournament_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: venues venue_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.venues ALTER COLUMN venue_id SET DEFAULT nextval('public.venues_venue_id_seq'::regclass);


--
-- PostgreSQL database dump complete
--

\unrestrict D4XDyaDspTY2REqETSw3Gx3ogkUlyLeacgvOkRz3NeqMBogNHETZVZ9fGg14GT3
