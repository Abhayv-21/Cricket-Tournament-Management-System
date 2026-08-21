from datetime import time
from flask import Blueprint, jsonify, request
from db import get_db_connection

matches_bp = Blueprint("matches", __name__)


@matches_bp.route("/", methods=["GET"])
def get_matches():

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            m.match_id,
            m.tournament_id,
            m.team1_id,
            t1.team_name AS team1,
            m.team2_id,
            t2.team_name AS team2,
            m.venue_id,
            m.match_date,
            m.match_time,
            m.status,
            m.winner_team_id,
            m.toss_winner_id,
            m.toss_decision,
            m.match_result
        FROM matches m
        JOIN teams t1 ON m.team1_id = t1.team_id
        JOIN teams t2 ON m.team2_id = t2.team_id
        ORDER BY m.match_date, m.match_time;
    """)

    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]



    cur.close()
    conn.close()

    matches = []

    for row in rows:
        match = dict(zip(columns, row))

        for key, value in match.items():
            if isinstance(value, time):
                match[key] = value.isoformat()

        matches.append(match)

    return jsonify(matches)

@matches_bp.route("/", methods=["POST"])
def add_match():
    data = request.get_json()

    tournament_id = data.get("tournament_id")
    team1_id = data.get("team1_id")
    team2_id = data.get("team2_id")
    venue_id = data.get("venue_id")
    match_date = data.get("match_date")
    match_time = data.get("match_time")

    status = data.get("status", "Scheduled")
    winner_team_id = data.get("winner_team_id")
    toss_winner_id = data.get("toss_winner_id")
    toss_decision = data.get("toss_decision")
    match_result = data.get("match_result", "Pending")

    if not tournament_id or not team1_id or not team2_id or not venue_id or not match_date or not match_time:
        return jsonify({
            "error": "Tournament, both teams, venue, date and time are required"
        }), 400

    if team1_id == team2_id:
        return jsonify({
            "error": "Team 1 and Team 2 cannot be the same"
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            INSERT INTO matches (
                tournament_id,
                team1_id,
                team2_id,
                venue_id,
                match_date,
                match_time,
                status,
                winner_team_id,
                toss_winner_id,
                toss_decision,
                match_result
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING match_id
        """, (
            tournament_id,
            team1_id,
            team2_id,
            venue_id,
            match_date,
            match_time,
            status,
            winner_team_id,
            toss_winner_id,
            toss_decision,
            match_result
        ))

        new_match_id = cur.fetchone()[0]

        conn.commit()

        return jsonify({
            "message": "Match added successfully",
            "match_id": new_match_id
        }), 201

    except Exception as e:
        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:
        cur.close()
        conn.close()


@matches_bp.route("/<int:match_id>", methods=["GET"])
def get_match(match_id):

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            m.*,
            t1.team_name AS team1_name,
            t2.team_name AS team2_name
        FROM matches m
        JOIN teams t1 ON m.team1_id = t1.team_id
        JOIN teams t2 ON m.team2_id = t2.team_id
        WHERE m.match_id = %s;
    """, (match_id,))

    row = cur.fetchone()

    if row is None:
        cur.close()
        conn.close()
        return jsonify({"error": "Match not found"}), 404

    columns = [desc[0] for desc in cur.description]

    match = dict(zip(columns, row))

    for key, value in match.items():
	if isinstance(value, time):
	match[key] = value.isoformat()

    cur.close()
    conn.close()

    return jsonify(match)

@matches_bp.route("/<int:match_id>/innings", methods=["GET"])
def get_match_innings(match_id):

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            i.innings_id,
            i.match_id,
            i.innings_no,
            i.batting_team_id,
            bt.team_name AS batting_team,
            i.bowling_team_id,
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
        WHERE i.match_id = %s
        ORDER BY i.innings_no;
    """, (match_id,))

    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    innings = [
        dict(zip(columns, row))
        for row in rows
    ]

    return jsonify(innings)

@matches_bp.route("/<int:match_id>/innings/<int:innings_id>/balls", methods=["GET"])
def get_ball_events(match_id, innings_id):

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            b.ball_event_id,
            b.innings_id,
            b.over_number,
            b.ball_number,

            b.striker_id,
            s.full_name AS striker,

            b.non_striker_id,
            ns.full_name AS non_striker,

            b.bowler_id,
            bw.full_name AS bowler,

            b.batsman_runs,
            b.extras,
            b.total_runs,

            b.is_wicket,
            b.batsman_out_id,
            outp.full_name AS batsman_out,

            b.dismissal_type,
            b.fielder_id,
            f.full_name AS fielder,

            b.extra_type

        FROM ball_events b

        JOIN innings i
            ON b.innings_id = i.innings_id

        JOIN players s
            ON b.striker_id = s.player_id

        JOIN players ns
            ON b.non_striker_id = ns.player_id

        JOIN players bw
            ON b.bowler_id = bw.player_id

        LEFT JOIN players outp
            ON b.batsman_out_id = outp.player_id

        LEFT JOIN players f
            ON b.fielder_id = f.player_id

        WHERE b.innings_id = %s
        AND i.match_id = %s

        ORDER BY b.over_number, b.ball_number;
    """, (innings_id, match_id))

    rows = cur.fetchall()

    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    balls = [
        dict(zip(columns, row))
        for row in rows
    ]

    return jsonify(balls)

@matches_bp.route("/innings/<int:innings_id>/balls", methods=["GET"])
def get_innings_balls(innings_id):

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            b.ball_event_id,
            b.innings_id,
            b.over_number,
            b.ball_number,

            b.striker_id,
            s.full_name AS striker,

            b.non_striker_id,
            ns.full_name AS non_striker,

            b.bowler_id,
            bo.full_name AS bowler,

            b.batsman_runs,
            b.extras,
            b.total_runs,

            b.is_wicket,
            b.batsman_out_id,
            outp.full_name AS batsman_out,

            b.dismissal_type,
            b.fielder_id,
            f.full_name AS fielder,

            b.extra_type

        FROM ball_events b

        JOIN players s
            ON b.striker_id = s.player_id

        JOIN players ns
            ON b.non_striker_id = ns.player_id

        JOIN players bo
            ON b.bowler_id = bo.player_id

        LEFT JOIN players outp
            ON b.batsman_out_id = outp.player_id

        LEFT JOIN players f
            ON b.fielder_id = f.player_id

        WHERE b.innings_id = %s

        ORDER BY
            b.over_number,
            b.ball_number;
    """, (innings_id,))

    rows = cur.fetchall()

    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    balls = [
        dict(zip(columns, row))
        for row in rows
    ]

    return jsonify(balls)

@matches_bp.route("/<int:match_id>/end", methods=["POST"])
def end_match(match_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute(
            "CALL end_match(%s);",
            (match_id,)
        )

        conn.commit()

        return jsonify({
            "message": "Match ended successfully",
            "match_id": match_id
        }), 200

    except Exception as e:
        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 400

    finally:
        cur.close()
        conn.close()


@matches_bp.route("/<int:match_id>", methods=["PUT"])
def update_match(match_id):

    data = request.get_json()

    tournament_id = data.get("tournament_id")
    team1_id = data.get("team1_id")
    team2_id = data.get("team2_id")
    venue_id = data.get("venue_id")
    match_date = data.get("match_date")
    match_time = data.get("match_time")
    status = data.get("status")
    winner_team_id = data.get("winner_team_id")
    toss_winner_id = data.get("toss_winner_id")
    toss_decision = data.get("toss_decision")
    match_result = data.get("match_result")

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            UPDATE matches
            SET
                tournament_id = %s,
                team1_id = %s,
                team2_id = %s,
                venue_id = %s,
                match_date = %s,
                match_time = %s,
                status = %s,
                winner_team_id = %s,
                toss_winner_id = %s,
                toss_decision = %s,
                match_result = %s
            WHERE match_id = %s;
        """, (
            tournament_id,
            team1_id,
            team2_id,
            venue_id,
            match_date,
            match_time,
            status,
            winner_team_id,
            toss_winner_id,
            toss_decision,
            match_result,
            match_id
        ))

        if cur.rowcount == 0:
            conn.rollback()
            return jsonify({"error": "Match not found"}), 404

        conn.commit()

        return jsonify({
            "message": "Match updated successfully",
            "match_id": match_id
        })

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 400

    finally:

        cur.close()
        conn.close()

@matches_bp.route("/<int:match_id>", methods=["DELETE"])
def delete_match(match_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        # Check whether match exists
        cur.execute(
            "SELECT match_id FROM matches WHERE match_id = %s;",
            (match_id,)
        )

        match = cur.fetchone()

        if match is None:
            return jsonify({
                "error": "Match not found"
            }), 404


        # Check for dependent match_squads records
        cur.execute(
            "SELECT COUNT(*) FROM match_squads WHERE match_id = %s;",
            (match_id,)
        )

        squad_count = cur.fetchone()[0]


        # Check for dependent innings records
        cur.execute(
            "SELECT COUNT(*) FROM innings WHERE match_id = %s;",
            (match_id,)
        )

        innings_count = cur.fetchone()[0]


        if squad_count > 0 or innings_count > 0:

            return jsonify({
                "error": "Cannot delete match because it has related records."
            }), 409


        # Safe to delete
        cur.execute(
            "DELETE FROM matches WHERE match_id = %s;",
            (match_id,)
        )

        conn.commit()

        return jsonify({
            "message": "Match deleted successfully",
            "match_id": match_id
        }), 200


    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500


    finally:

        cur.close()
        conn.close()