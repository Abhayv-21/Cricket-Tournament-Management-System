from flask import Blueprint, jsonify, request
from db import get_db_connection

teams_bp = Blueprint("teams", __name__)


# GET all teams
@teams_bp.route("/", methods=["GET"])
def get_teams():

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT *
        FROM teams
        ORDER BY team_id;
    """)

    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    teams = [
        dict(zip(columns, row))
        for row in rows
    ]

    return jsonify(teams)


# POST - Add a new team
@teams_bp.route("/", methods=["POST"])
def add_team():

    data = request.get_json()

    team_name = data.get("team_name")
    short_name = data.get("short_name")
    owner_name = data.get("owner_name")
    coach_name = data.get("coach_name")
    tournament_id = data.get("tournament_id")

    if not team_name or not short_name or not owner_name or not coach_name or not tournament_id:
        return jsonify({
            "error": "Team name and short name are required"
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            INSERT INTO teams (
                team_name,
                short_name,
                owner_name,
                coach_name,
                tournament_id
            )
            VALUES (%s, %s, %s, %s, %s)
            RETURNING *;
        """, (
            team_name,
            short_name,
            owner_name,
            coach_name,
            tournament_id
        ))

        new_team = cur.fetchone()

        conn.commit()

        columns = [desc[0] for desc in cur.description]

        return jsonify(
            dict(zip(columns, new_team))
        ), 201

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        cur.close()
        conn.close()

from flask import Blueprint, jsonify, request
from db import get_db_connection



@teams_bp.route("/", methods=["GET"])


@teams_bp.route("/<int:team_id>", methods=["GET"])
def get_team(team_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            SELECT *
            FROM teams
            WHERE team_id = %s;
        """, (team_id,))

        row = cur.fetchone()

        if row is None:
            return jsonify({
                "error": "Team not found"
            }), 404

        columns = [desc[0] for desc in cur.description]

        return jsonify(
            dict(zip(columns, row))
        ), 200

    except Exception as e:

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        cur.close()
        conn.close()

# UPDATE TEAM
@teams_bp.route("/<int:team_id>", methods=["PUT"])
def update_team(team_id):

    data = request.get_json()

    team_name = data.get("team_name")
    short_name = data.get("short_name")
    owner_name = data.get("owner_name")
    coach_name = data.get("coach_name")

    if not team_name or not short_name or not owner_name or not coach_name:
        return jsonify({
            "error": "All team fields are required"
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            UPDATE teams
            SET
                team_name = %s,
                short_name = %s,
                owner_name = %s,
                coach_name = %s
            WHERE team_id = %s
            RETURNING *;
        """, (
            team_name,
            short_name,
            owner_name,
            coach_name,
            team_id
        ))

        updated_team = cur.fetchone()

        if updated_team is None:
            conn.rollback()
            return jsonify({
                "error": "Team not found"
            }), 404

        columns = [desc[0] for desc in cur.description]

        conn.commit()

        return jsonify(
            dict(zip(columns, updated_team))
        ), 200

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        cur.close()
        conn.close()

@teams_bp.route("/<int:team_id>", methods=["DELETE"])
def delete_team(team_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # Check whether team exists
        cur.execute("""
            SELECT team_id, team_name
            FROM teams
            WHERE team_id = %s;
        """, (team_id,))

        team = cur.fetchone()

        if team is None:
            return jsonify({
                "error": "Team not found"
            }), 404

        # Check whether team is referenced by other tables
        cur.execute("""
            SELECT
                (SELECT COUNT(*) FROM players WHERE team_id = %s) AS players,
                (SELECT COUNT(*) FROM matches
                    WHERE team1_id = %s
                       OR team2_id = %s
                       OR winner_team_id = %s
                       OR toss_winner_id = %s) AS matches,
                (SELECT COUNT(*) FROM points_table WHERE team_id = %s) AS points,
                (SELECT COUNT(*) FROM match_squads WHERE team_id = %s) AS squads,
                (SELECT COUNT(*) FROM innings
                    WHERE batting_team_id = %s
                       OR bowling_team_id = %s) AS innings;
        """, (
            team_id,
            team_id, team_id, team_id, team_id,
            team_id,
            team_id,
            team_id, team_id
        ))

        references = cur.fetchone()

        if any(references):
            return jsonify({
                "error": "Cannot delete team because it is used in existing records.",
                "details": {
                    "players": references[0],
                    "matches": references[1],
                    "points_table": references[2],
                    "match_squads": references[3],
                    "innings": references[4]
                }
            }), 409

        # Delete team
        cur.execute("""
            DELETE FROM teams
            WHERE team_id = %s;
        """, (team_id,))

        conn.commit()

        return jsonify({
            "message": "Team deleted successfully",
            "team_id": team_id,
            "team_name": team[1]
        }), 200

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:
        cur.close()
        conn.close()