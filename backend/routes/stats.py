from flask import Blueprint, jsonify
from db import get_db_connection

stats_bp = Blueprint("stats", __name__)


@stats_bp.route("/points-table/<int:tournament_id>", methods=["GET"])
def points_table(tournament_id):

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            pt.team_id,
            t.team_name,
            pt.matches_played,
            pt.wins,
            pt.losses,
            pt.ties,
            pt.no_results
        FROM points_table pt
        JOIN teams t ON pt.team_id = t.team_id
        WHERE pt.tournament_id = %s
        ORDER BY pt.wins DESC;
    """, (tournament_id,))

    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    return jsonify([
        dict(zip(columns, row))
        for row in rows
    ])


@stats_bp.route("/player/<int:player_id>", methods=["GET"])
def player_stats(player_id):

    conn = get_db_connection()
    cur = conn.cursor()

    # Check whether player exists
    cur.execute("""
        SELECT
            player_id,
            full_name
        FROM players
        WHERE player_id = %s;
    """, (player_id,))

    player = cur.fetchone()

    if player is None:
        cur.close()
        conn.close()
        return jsonify({"error": "Player not found"}), 404

    player_id_value, full_name = player


    # -------------------------
    # Batting Statistics
    # -------------------------

    cur.execute("""
        SELECT
            COALESCE(SUM(runs_scored), 0),
            COALESCE(SUM(balls_faced), 0),
            COALESCE(SUM(fours), 0),
            COALESCE(SUM(sixes), 0)
        FROM batting_scorecards
        WHERE player_id = %s;
    """, (player_id,))

    batting = cur.fetchone()

    total_runs = batting[0]
    total_balls = batting[1]
    total_fours = batting[2]
    total_sixes = batting[3]

    if total_balls > 0:
        strike_rate = round((total_runs / total_balls) * 100, 2)
    else:
        strike_rate = 0


    # -------------------------
    # Bowling Statistics
    # -------------------------

    cur.execute("""
        SELECT
            COALESCE(SUM(overs_bowled), 0),
            COALESCE(SUM(maidens), 0),
            COALESCE(SUM(runs_conceded), 0),
            COALESCE(SUM(wickets), 0),
            COALESCE(SUM(no_balls), 0),
            COALESCE(SUM(wides), 0)
        FROM bowling_scorecards
        WHERE player_id = %s;
    """, (player_id,))

    bowling = cur.fetchone()

    total_overs = float(bowling[0])
    total_maidens = bowling[1]
    total_runs_conceded = bowling[2]
    total_wickets = bowling[3]
    total_no_balls = bowling[4]
    total_wides = bowling[5]

    if total_overs > 0:
        economy = round(total_runs_conceded / total_overs, 2)
    else:
        economy = 0


    cur.close()
    conn.close()


    # -------------------------
    # Final Response
    # -------------------------

    return jsonify({
        "player_id": player_id_value,
        "full_name": full_name,

        "batting": {
            "runs": total_runs,
            "balls": total_balls,
            "fours": total_fours,
            "sixes": total_sixes,
            "strike_rate": strike_rate
        },

        "bowling": {
            "overs": total_overs,
            "maidens": total_maidens,
            "runs_conceded": total_runs_conceded,
            "wickets": total_wickets,
            "no_balls": total_no_balls,
            "wides": total_wides,
            "economy": economy
        }
    })
