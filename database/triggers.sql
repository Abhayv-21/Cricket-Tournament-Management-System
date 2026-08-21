-- TRIGGER FUNCTION UPDATE_INNINGS_SCORE
CREATE OR REPLACE FUNCTION update_innings_score()
RETURNS TRIGGER
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

CREATE TRIGGER trg_update_innings_score
AFTER INSERT
ON ball_events
FOR EACH ROW
EXECUTE FUNCTION update_innings_score();

-- ALTERING TABLE ball_events to store fielder_id and extras_type in it
ALTER TABLE ball_events
ADD COLUMN fielder_id INT;

ALTER TABLE ball_events
ADD CONSTRAINT fk_fielder
FOREIGN KEY(fielder_id)
REFERENCES players(player_id);

ALTER TABLE ball_events
ADD COLUMN extra_type VARCHAR(20);

ALTER TABLE ball_events
ADD CONSTRAINT chk_extra_type
CHECK(
extra_type IS NULL
OR extra_type IN ('Wide', 'No Ball', 'Bye', 'Leg Bye')
);

-- TRIGGER FUNCTION UPDATE_BATTINGS_SCORE
CREATE OR REPLACE FUNCTION update_batting_scorecard()
RETURNS TRIGGER
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_batting_scorecard
AFTER INSERT
ON ball_events
FOR EACH ROW
EXECUTE FUNCTION update_batting_scorecard();

-- TRIGGER FUNCTION UPDATE_BOWLING_SCORECARD
CREATE OR REPLACE FUNCTION update_bowling_scorecard()
RETURNS TRIGGER
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_bowling_scorecard
ON ball_events;

CREATE TRIGGER trg_update_bowling_scorecard
AFTER INSERT
ON ball_events
FOR EACH ROW
EXECUTE FUNCTION update_bowling_scorecard();

-- TRIGGER FUNCTION INSERT_FALL_OF_WICKETS
CREATE OR REPLACE FUNCTION insert_fall_of_wickets()
RETURNS TRIGGER
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
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_insert_fall_of_wickets
ON ball_events;

CREATE TRIGGER trg_insert_fall_of_wickets
AFTER INSERT
ON ball_events
FOR EACH ROW
EXECUTE FUNCTION insert_fall_of_wickets();