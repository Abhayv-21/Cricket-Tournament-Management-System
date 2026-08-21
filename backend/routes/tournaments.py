from flask import Blueprint, jsonify
from db import get_db_connection

tournaments_bp = Blueprint("tournaments", __name__)


@tournaments_bp.route("/", methods=["GET"])
def get_tournaments():

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT *
        FROM tournaments
        ORDER BY tournament_id;
    """)

    rows = cur.fetchall()
    columns = [desc[0] for desc in cur.description]

    cur.close()
    conn.close()

    tournaments = [
        dict(zip(columns, row))
        for row in rows
    ]

    return jsonify(tournaments)
