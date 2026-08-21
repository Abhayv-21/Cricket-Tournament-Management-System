-- ============================================================
-- CRICKET TOURNAMENT MANAGEMENT SYSTEM
-- SQL QUERIES
-- ============================================================


-- ============================================================
-- 1. DISPLAY ALL TOURNAMENTS
-- ============================================================

SELECT *
FROM tournaments;


-- ============================================================
-- 2. DISPLAY ALL TEAMS IN THE TOURNAMENT
-- ============================================================

SELECT
    t.team_id,
    t.team_name,
    t.short_name,
    t.owner_name,
    t.coach_name
FROM teams t
JOIN tournaments tr
    ON t.tournament_id = tr.tournament_id;


-- ============================================================
-- 3. DISPLAY ALL PLAYERS WITH THEIR TEAM
-- ============================================================

SELECT
    p.player_id,
    p.full_name,
    p.player_role,
    p.batting_style,
    p.bowling_style,
    t.team_name
FROM players p
JOIN teams t
    ON p.team_id = t.team_id
ORDER BY t.team_name, p.full_name;


-- ============================================================
-- 4. DISPLAY ALL MATCHES WITH TEAM NAMES
-- ============================================================

SELECT
    m.match_id,
    t1.team_name AS team_1,
    t2.team_name AS team_2,
    v.venue_name,
    m.match_date,
    m.match_time,
    m.status,
    m.match_result
FROM matches m
JOIN teams t1
    ON m.team1_id = t1.team_id
JOIN teams t2
    ON m.team2_id = t2.team_id
JOIN venues v
    ON m.venue_id = v.venue_id
ORDER BY m.match_date;


-- ============================================================
-- 5. DISPLAY PLAYING XI FOR A MATCH
-- ============================================================

SELECT
    ms.match_id,
    t.team_name,
    p.full_name,
    ms.is_captain,
    ms.is_wicket_keeper,
    ms.batting_position
FROM match_squads ms
JOIN players p
    ON ms.player_id = p.player_id
JOIN teams t
    ON ms.team_id = t.team_id
WHERE ms.is_playing_xi = TRUE
ORDER BY ms.match_id, t.team_name, ms.batting_position;


-- ============================================================
-- 6. DISPLAY TOURNAMENT POINTS TABLE
-- ============================================================

SELECT
    t.team_name,
    pt.matches_played,
    pt.wins,
    pt.losses,
    pt.ties,
    pt.no_results,
    (pt.wins * 2 + pt.ties) AS points
FROM points_table pt
JOIN teams t
    ON pt.team_id = t.team_id
ORDER BY points DESC;


-- ============================================================
-- 7. TOP RUN SCORERS
-- ============================================================

SELECT
    p.full_name,
    t.team_name,
    SUM(bs.runs_scored) AS total_runs
FROM batting_scorecards bs
JOIN players p
    ON bs.player_id = p.player_id
JOIN teams t
    ON p.team_id = t.team_id
GROUP BY p.player_id, p.full_name, t.team_name
ORDER BY total_runs DESC;


-- ============================================================
-- 8. TOP WICKET TAKERS
-- ============================================================

SELECT
    p.full_name,
    t.team_name,
    SUM(bsc.wickets) AS total_wickets
FROM bowling_scorecards bsc
JOIN players p
    ON bsc.player_id = p.player_id
JOIN teams t
    ON p.team_id = t.team_id
GROUP BY p.player_id, p.full_name, t.team_name
ORDER BY total_wickets DESC;


-- ============================================================
-- 9. BATTING SCORECARD
-- ============================================================

SELECT
    p.full_name,
    bs.batting_position,
    bs.runs_scored,
    bs.balls_faced,
    bs.fours,
    bs.sixes,
    bs.is_not_out,
    bs.dismissal_type
FROM batting_scorecards bs
JOIN players p
    ON bs.player_id = p.player_id
WHERE bs.innings_id = 1
ORDER BY bs.batting_position;


-- ============================================================
-- 10. BOWLING SCORECARD
-- ============================================================

SELECT
    p.full_name,
    bs.overs_bowled,
    bs.maidens,
    bs.runs_conceded,
    bs.wickets,
    bs.wides,
    bs.no_balls
FROM bowling_scorecards bs
JOIN players p
    ON bs.player_id = p.player_id
WHERE bs.innings_id = 1
ORDER BY bs.wickets DESC, bs.runs_conceded;


-- ============================================================
-- 11. FALL OF WICKETS
-- ============================================================

SELECT
    fw.wicket_number,
    p.full_name AS batsman,
    fw.score_at_wicket,
    fw.over_number
FROM fall_of_wickets fw
JOIN players p
    ON fw.batsman_out_id = p.player_id
WHERE fw.innings_id = 1
ORDER BY fw.wicket_number;


-- ============================================================
-- 12. DISPLAY INNINGS SUMMARY
-- ============================================================

SELECT
    i.innings_id,
    i.innings_no,
    bt.team_name AS batting_team,
    bw.team_name AS bowling_team,
    i.total_runs,
    i.total_wickets,
    i.overs_completed,
    i.extras
FROM innings i
JOIN teams bt
    ON i.batting_team_id = bt.team_id
JOIN teams bw
    ON i.bowling_team_id = bw.team_id
ORDER BY i.match_id, i.innings_no;


-- ============================================================
-- 13. TOTAL RUNS SCORED BY EACH PLAYER
-- ============================================================

SELECT
    p.full_name,
    SUM(bs.runs_scored) AS total_runs,
    SUM(bs.balls_faced) AS total_balls,
    SUM(bs.fours) AS total_fours,
    SUM(bs.sixes) AS total_sixes
FROM batting_scorecards bs
JOIN players p
    ON bs.player_id = p.player_id
GROUP BY p.player_id, p.full_name
ORDER BY total_runs DESC;


-- ============================================================
-- 14. PLAYER WITH HIGHEST SCORE
-- ============================================================

SELECT
    p.full_name,
    bs.runs_scored,
    bs.balls_faced,
    bs.fours,
    bs.sixes
FROM batting_scorecards bs
JOIN players p
    ON bs.player_id = p.player_id
ORDER BY bs.runs_scored DESC
LIMIT 1;


-- ============================================================
-- 15. MATCH RESULTS
-- ============================================================

SELECT
    m.match_id,
    t1.team_name AS team_1,
    t2.team_name AS team_2,
    tw.team_name AS winner,
    m.match_result
FROM matches m
JOIN teams t1
    ON m.team1_id = t1.team_id
JOIN teams t2
    ON m.team2_id = t2.team_id
LEFT JOIN teams tw
    ON m.winner_team_id = tw.team_id
ORDER BY m.match_date;