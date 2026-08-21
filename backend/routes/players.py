from flask import Blueprint, jsonify, request
from db import get_db_connection

players_bp = Blueprint("players", __name__)


# GET - All players
@players_bp.route("/", methods=["GET"])
def get_players():

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT *
            FROM players
            ORDER BY player_id;
        """)

        rows = cur.fetchall()
        columns = [desc[0] for desc in cur.description]

        players = [
            dict(zip(columns, row))
            for row in rows
        ]

        return jsonify(players)

    finally:
        cur.close()
        conn.close()


# GET - Single player
@players_bp.route("/<int:player_id>", methods=["GET"])
def get_player(player_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:
        cur.execute("""
            SELECT *
            FROM players
            WHERE player_id = %s;
        """, (player_id,))

        row = cur.fetchone()

        if row is None:
            return jsonify({"error": "Player not found"}), 404

        columns = [desc[0] for desc in cur.description]

        return jsonify(dict(zip(columns, row)))

    finally:
        cur.close()
        conn.close()


# POST - Add a new player
@players_bp.route("/", methods=["POST"])
def add_player():

    data = request.get_json()

    # Required fields
    full_name = data.get("full_name")
    dob = data.get("dob")
    nationality = data.get("nationality")
    jersey_number = data.get("jersey_number")
    email = data.get("email")
    phone_number = data.get("phone_number")

    # Optional fields
    batting_style = data.get("batting_style")
    bowling_style = data.get("bowling_style")
    player_role = data.get("player_role")
    team_id = data.get("team_id")
    height_cm = data.get("height_cm")
    weight_kg = data.get("weight_kg")

    # Check required fields
    if not all([
        full_name,
        dob,
        nationality,
        jersey_number,
        email,
        phone_number
    ]):
        return jsonify({
            "error": "Full name, DOB, nationality, jersey number, email and phone number are required"
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            INSERT INTO players (
                full_name,
                dob,
                nationality,
                batting_style,
                bowling_style,
                player_role,
                jersey_number,
                email,
                phone_number,
                height_cm,
                weight_kg,
                team_id
            )
            VALUES (
                %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s
            )
            RETURNING *;
        """, (
            full_name,
            dob,
            nationality,
            batting_style,
            bowling_style,
            player_role,
            jersey_number,
            email,
            phone_number,
            height_cm,
            weight_kg,
            team_id
        ))

        new_player = cur.fetchone()

        conn.commit()

        columns = [desc[0] for desc in cur.description]

        return jsonify(
            dict(zip(columns, new_player))
        ), 201

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:
        cur.close()
        conn.close()

# UPDATE - Player
@players_bp.route("/<int:player_id>", methods=["PUT"])
def update_player(player_id):

    data = request.get_json()

    full_name = data.get("full_name")
    dob = data.get("dob")
    nationality = data.get("nationality")
    batting_style = data.get("batting_style")
    bowling_style = data.get("bowling_style")
    player_role = data.get("player_role")
    jersey_number = data.get("jersey_number")
    email = data.get("email")
    phone_number = data.get("phone_number")
    height_cm = data.get("height_cm")
    weight_kg = data.get("weight_kg")
    team_id = data.get("team_id")

    if not full_name or not dob or not nationality or not jersey_number or not email or not phone_number:
        return jsonify({
            "error": "All required player fields must be provided"
        }), 400

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        cur.execute("""
            UPDATE players
            SET
                full_name = %s,
                dob = %s,
                nationality = %s,
                batting_style = %s,
                bowling_style = %s,
                player_role = %s,
                jersey_number = %s,
                email = %s,
                phone_number = %s,
                height_cm = %s,
                weight_kg = %s,
                team_id = %s
            WHERE player_id = %s
            RETURNING *;
        """, (
            full_name,
            dob,
            nationality,
            batting_style,
            bowling_style,
            player_role,
            jersey_number,
            email,
            phone_number,
            height_cm,
            weight_kg,
            team_id,
            player_id
        ))

        updated_player = cur.fetchone()

        if updated_player is None:
            conn.rollback()

            return jsonify({
                "error": "Player not found"
            }), 404

        columns = [desc[0] for desc in cur.description]

        conn.commit()

        return jsonify(
            dict(zip(columns, updated_player))
        ), 200

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        cur.close()
        conn.close()

# Delete - Player
@players_bp.route("/<int:player_id>", methods=["DELETE"])
def delete_player(player_id):

    conn = get_db_connection()
    cur = conn.cursor()

    try:

        # Check if player exists
        cur.execute("""
            SELECT player_id, full_name
            FROM players
            WHERE player_id = %s;
        """, (player_id,))

        player = cur.fetchone()

        if player is None:
            return jsonify({
                "error": "Player not found"
            }), 404

        # Check whether player is used in match_squads
        cur.execute("""
            SELECT COUNT(*)
            FROM match_squads
            WHERE player_id = %s;
        """, (player_id,))

        squad_count = cur.fetchone()[0]

        if squad_count > 0:

            return jsonify({
                "error": "Cannot delete player because the player is assigned to a match.",
                "player_id": player_id,
                "full_name": player[1],
                "match_squads": squad_count
            }), 409

        # Delete player
        cur.execute("""
            DELETE FROM players
            WHERE player_id = %s;
        """, (player_id,))

        conn.commit()

        return jsonify({
            "message": "Player deleted successfully",
            "player_id": player_id,
            "full_name": player[1]
        }), 200

    except Exception as e:

        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:

        cur.close()
        conn.close()