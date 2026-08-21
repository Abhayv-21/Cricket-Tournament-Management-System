from flask import Flask, jsonify
from flask_cors import CORS

from routes.tournaments import tournaments_bp
from routes.teams import teams_bp
from routes.players import players_bp
from routes.matches import matches_bp
from routes.stats import stats_bp


app = Flask(__name__)
CORS(app)


@app.route("/")
def home():
    return jsonify({
        "message": "Cricket Tournament Management System API",
        "status": "running"
    })


@app.route("/api/health")
def health():
    return jsonify({
        "status": "OK",
        "database": "PostgreSQL"
    })


app.register_blueprint(tournaments_bp, url_prefix="/api/tournaments")
app.register_blueprint(teams_bp, url_prefix="/api/teams")
app.register_blueprint(players_bp, url_prefix="/api/players")
app.register_blueprint(matches_bp, url_prefix="/api/matches")
app.register_blueprint(stats_bp, url_prefix="/api/stats")


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
