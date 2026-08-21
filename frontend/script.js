const API = "http://127.0.0.1:5000/api";


async function fetchData(endpoint) {
    const response = await fetch(API + endpoint);

    if (!response.ok) {
        throw new Error("Failed to fetch " + endpoint);
    }

    return await response.json();
}


// -----------------------------
// Dashboard
// -----------------------------

async function loadDashboard() {

    try {

        const tournaments = await fetchData("/tournaments/");
        const teams = await fetchData("/teams/");
        const players = await fetchData("/players/");
        const matches = await fetchData("/matches/");

        document.getElementById("tournamentCount").textContent =
            tournaments.length;

        document.getElementById("teamCount").textContent =
            teams.length;

        document.getElementById("playerCount").textContent =
            players.length;

        document.getElementById("matchCount").textContent =
            matches.length;

        const container = document.getElementById("dashboardMatches");

        container.innerHTML = "";

        matches.forEach(match => {

            const div = document.createElement("div");

            div.className = "item";

            div.innerHTML = `
                <strong>
                    ${match.team1} vs ${match.team2}
                </strong>
                <br>
                Status: ${match.status || "Pending"}
                <br>
                Result: ${match.match_result || "Pending"}
            `;

            container.appendChild(div);
        });

    } catch (error) {

        console.error(error);

    }
}


// -----------------------------
// Teams
// -----------------------------

async function loadTeams() {

    try {

        const teams = await fetchData("/teams/");

        const container = document.getElementById("teamsList");

        container.innerHTML = "";

        teams.forEach(team => {

            const div = document.createElement("div");

            div.className = "item";

            div.innerHTML = `
                <h3>${team.team_name}</h3>
                <p>Team ID: ${team.team_id}</p>
            `;

            container.appendChild(div);

        });

    } catch (error) {

        console.error(error);

    }
}


// -----------------------------
// Players
// -----------------------------

async function loadPlayers() {

    try {

        const players = await fetchData("/players/");

        const container = document.getElementById("playersList");

        container.innerHTML = "";

        players.forEach(player => {

            const div = document.createElement("div");

            div.className = "item";

            div.innerHTML = `
                <h3>${player.full_name}</h3>

                <p>
                    <strong>Player ID:</strong>
                    ${player.player_id}
                </p>

                <p>
                    <strong>Nationality:</strong>
                    ${player.nationality || ""}
                </p>

                <p>
                    <strong>Role:</strong>
                    ${player.player_role || ""}
                </p>

                <p>
                    <strong>Jersey Number:</strong>
                    ${player.jersey_number}
                </p>

                <p>
                    <strong>Team ID:</strong>
                    ${player.team_id || "Not Assigned"}
                </p>

                <button onclick="showSection('statistics'); loadPlayerStats(${player.player_id})">
                    View Stats

                </button>

                <button onclick="editPlayer(${player.player_id})">
                    Edit
                </button>

                <button onclick="deletePlayer(${player.player_id})">
                    Delete
                </button>
            `;

            container.appendChild(div);

        });

    } catch (error) {

        console.error(error);

    }
}


// -----------------------------
// Matches
// -----------------------------

async function loadMatches() {

    try {

        const matches = await fetchData("/matches/");

        const container = document.getElementById("matchesList");

        container.innerHTML = "";

        matches.forEach(match => {

            const div = document.createElement("div");

            div.className = "item";

            div.innerHTML = `
                <h3>
                    ${match.team1} vs ${match.team2}
                </h3>

                <p>
                    Match ID: ${match.match_id}
                </p>

                <p>
                    Date: ${match.match_date || "Not scheduled"}
                </p>

                <p>
                    Time: ${match.match_time || "Not scheduled"}
                </p>

                <p>
                    Status: ${match.status || "Pending"}
                </p>

                <p>
                    Result: ${match.match_result || "Pending"}
                </p>

                <button onclick="viewMatchDetails(${match.match_id})">
                    View Details
                </button>

                <button onclick="deleteMatch(${match.match_id})">
                    Delete
                </button>

                <button onclick="editMatch(${match.match_id})">
                    Edit
                </button>
            `;

            container.appendChild(div);

        });

    } catch (error) {

        console.error(error);

    }
}

async function deleteMatch(matchId) {

    const confirmDelete = confirm(
        "Are you sure you want to delete this match?"
    );

    if (!confirmDelete) {
        return;
    }

    try {

        const response = await fetch(API + `/matches/${matchId}`, {
            method: "DELETE"
        });

        const data = await response.json();

        console.log("Delete response:", data);

        if (!response.ok) {
            alert(data.error || "Failed to delete match.");
            return;
        }

        alert("Match deleted successfully!");

        loadMatches();

    } catch (error) {

        console.error("Delete match error:", error);

        alert("Failed to delete match.");
    }
}

async function editMatch(matchId) {

    try {

        const response = await fetchData(`/matches/${matchId}`);

        // Show the edit form
        const container = document.getElementById("matchDetails");

        container.innerHTML = `
            <div class="form-box">

                <h3>Edit Match #${response.match_id}</h3>

                <input
                    type="number"
                    id="editMatchTournamentId"
                    value="${response.tournament_id}"
                    placeholder="Tournament ID"
                >

                <input
                    type="number"
                    id="editMatchTeam1Id"
                    value="${response.team1_id}"
                    placeholder="Team 1 ID"
                >

                <input
                    type="number"
                    id="editMatchTeam2Id"
                    value="${response.team2_id}"
                    placeholder="Team 2 ID"
                >

                <input
                    type="number"
                    id="editMatchVenueId"
                    value="${response.venue_id}"
                    placeholder="Venue ID"
                >

                <input
                    type="date"
                    id="editMatchDate"
                    value="${response.match_date || ""}"
                >

                <input
                    type="time"
                    id="editMatchTime"
                    value="${response.match_time || ""}"
                >

                <select id="editMatchStatus">

                    <option value="Scheduled"
                        ${response.status === "Scheduled" ? "selected" : ""}>
                        Scheduled
                    </option>

                    <option value="Live"
                        ${response.status === "Live" ? "selected" : ""}>
                        Live
                    </option>

                    <option value="Completed"
                        ${response.status === "Completed" ? "selected" : ""}>
                        Completed
                    </option>

                    <option value="Cancelled"
                        ${response.status === "Cancelled" ? "selected" : ""}>
                        Cancelled
                    </option>

                </select>

                <input
                    type="number"
                    id="editMatchWinnerTeamId"
                    value="${response.winner_team_id || ""}"
                    placeholder="Winner Team ID"
                >

                <input
                    type="number"
                    id="editMatchTossWinnerId"
                    value="${response.toss_winner_id || ""}"
                    placeholder="Toss Winner Team ID"
                >

                <select id="editMatchTossDecision">

                    <option value="">Toss Decision</option>

                    <option value="Batting"
                        ${response.toss_decision === "Batting" ? "selected" : ""}>
                        Batting
                    </option>

                    <option value="Bowling"
                        ${response.toss_decision === "Bowling" ? "selected" : ""}>
                        Bowling
                    </option>

                </select>

                <input
                    type="text"
                    id="editMatchResult"
                    value="${response.match_result || ""}"
                    placeholder="Match Result"
                >

                <button onclick="updateMatch(${matchId})">
                    Save Changes
                </button>

                <button onclick="cancelEditMatch()">
                    Cancel
                </button>

            </div>
        `;

    } catch (error) {

        console.error("Edit match error:", error);

        alert("Failed to load match details.");
    }
}

async function updateMatch(matchId) {

    const tournamentId =
        document.getElementById("editMatchTournamentId").value;

    const team1Id =
        document.getElementById("editMatchTeam1Id").value;

    const team2Id =
        document.getElementById("editMatchTeam2Id").value;

    const venueId =
        document.getElementById("editMatchVenueId").value;

    const matchDate =
        document.getElementById("editMatchDate").value;

    const matchTime =
        document.getElementById("editMatchTime").value;

    const status =
        document.getElementById("editMatchStatus").value;

    const winnerTeamId =
        document.getElementById("editMatchWinnerTeamId").value;

    const tossWinnerId =
        document.getElementById("editMatchTossWinnerId").value;

    const tossDecision =
        document.getElementById("editMatchTossDecision").value;

    const matchResult =
        document.getElementById("editMatchResult").value;


    if (!tournamentId ||
        !team1Id ||
        !team2Id ||
        !venueId ||
        !matchDate ||
        !matchTime) {

        alert("Please fill all required fields.");
        return;
    }


    if (team1Id === team2Id) {

        alert("Team 1 and Team 2 cannot be the same.");
        return;
    }


    try {

        const response = await fetch(`${API}/matches/${matchId}`, {

            method: "PUT",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({

                tournament_id: parseInt(tournamentId),

                team1_id: parseInt(team1Id),

                team2_id: parseInt(team2Id),

                venue_id: parseInt(venueId),

                match_date: matchDate,

                match_time: matchTime,

                status: status,

                winner_team_id:
                    winnerTeamId
                        ? parseInt(winnerTeamId)
                        : null,

                toss_winner_id:
                    tossWinnerId
                        ? parseInt(tossWinnerId)
                        : null,

                toss_decision:
                    tossDecision || null,

                match_result:
                    matchResult || null
            })
        });


        const data = await response.json();


        if (!response.ok) {

            throw new Error(
                data.error || "Failed to update match"
            );
        }


        alert("Match updated successfully!");


        // Refresh matches
        loadMatches();


        // Clear details/edit area
        document.getElementById("matchDetails").innerHTML = "";

    } catch (error) {

        console.error("Update match error:", error);

        alert(error.message);
    }
}

function cancelEditMatch() {

    document.getElementById("matchDetails").innerHTML = "";

}

async function viewMatchDetails(matchId) {
    try {

        // Fetch match details
        const matchResponse = await fetch(
            `${API}/matches/${matchId}`
        );

        if (!matchResponse.ok) {
            throw new Error("Match not found");
        }

        const match = await matchResponse.json();


        // Fetch innings details
        const inningsResponse = await fetch(
            `${API}/matches/${matchId}/innings`
        );

        if (!inningsResponse.ok) {
            throw new Error("Innings not found");
        }

        const innings = await inningsResponse.json();


        const details = document.getElementById("matchDetails");


        // Build innings HTML
        let inningsHTML = "";

        if (innings.length === 0) {

            inningsHTML = `
                <p>
                    <strong>Innings:</strong> No innings data available.
                </p>
            `;

        } else {

            inningsHTML = `
                <h3>Innings Summary</h3>
            `;

            innings.forEach((inning, index) => {

                inningsHTML += `
                    <div class="innings-card">

                        <h4>
                            Innings ${inning.innings_no}
                        </h4>

                        <p>
                            <strong>Batting Team:</strong>
                            ${inning.batting_team}
                        </p>

                        <p>
                            <strong>Bowling Team:</strong>
                            ${inning.bowling_team}
                        </p>

                        <p>
                            <strong>Score:</strong>
                            ${inning.total_runs}/${inning.total_wickets}
                        </p>

                        <p>
                            <strong>Overs:</strong>
                            ${inning.overs_completed}
                        </p>

                        <p>
                            <strong>Extras:</strong>
                            ${inning.extras}
                        </p>

                    </div>
                `;
            });
        }


        // Display complete match details
        details.innerHTML = `

            <div class="match-details-card">

                <h2>
                    ${match.team1_name}
                    <span>VS</span>
                    ${match.team2_name}
                </h2>


                <p>
                    <strong>Match ID:</strong>
                    ${match.match_id}
                </p>


                <p>
                    <strong>Date:</strong>
                    ${match.match_date || "N/A"}
                </p>


                <p>
                    <strong>Time:</strong>
                    ${match.match_time || "N/A"}
                </p>


                <p>
                    <strong>Status:</strong>
                    ${match.status || "N/A"}
                </p>


                <p>
                    <strong>Toss Winner:</strong>
                    ${match.toss_winner_id || "N/A"}
                </p>


                <p>
                    <strong>Toss Decision:</strong>
                    ${match.toss_decision || "N/A"}
                </p>


                <p>
                    <strong>Result:</strong>
                    ${match.match_result || "Pending"}
                </p>


                <p>
                    <strong>Winner Team ID:</strong>
                    ${match.winner_team_id || "N/A"}
                </p>


                ${inningsHTML}

            </div>
        `;


        details.scrollIntoView({
            behavior: "smooth"
        });


    } catch (error) {

        console.error(error);

        document.getElementById("matchDetails").innerHTML = `
            <p class="error">
                Unable to load match details.
            </p>
        `;
    }
}
// -----------------------------
// Points Table
// -----------------------------

async function loadPointsTable() {

    try {

        const data = await fetchData("/stats/points-table/1");

        const table = document.getElementById("pointsTable");

        table.innerHTML = "";

        data.forEach(team => {

            const row = document.createElement("tr");

            const points =
                (team.wins * 2) +
                (team.ties * 1) +
                (team.no_results * 1);

            row.innerHTML = `
                <td>${team.team_name}</td>
                <td>${team.matches_played}</td>
                <td>${team.wins}</td>
                <td>${team.losses}</td>
                <td>${team.ties}</td>
                <td>${team.no_results}</td>
                <td><strong>${points}</strong></td>
            `;

            table.appendChild(row);

        });

    } catch (error) {

        console.error(error);

    }
}


// -----------------------------
// Navigation
// ------------0
// -----------------

function showSection(sectionName) {

    document.querySelectorAll(".section").forEach(section => {
        section.classList.remove("active");
    });

    document.getElementById(sectionName).classList.add("active");

    if (sectionName === "teams") {
        loadTeams();
    }

    if (sectionName === "players") {
        loadPlayers();
    }

    if (sectionName === "matches") {
        loadMatches();
    }

    if (sectionName === "points") {
        loadPointsTable();
    }

}


// -----------------------------
// Start application
// -----------------------------

loadDashboard();


// ------------------------------
// Teams Page
// ------------------------------

async function loadTeams() {

    try {

        const teams = await fetchData("/teams/");

        const container = document.getElementById("teamsList");

        container.innerHTML = "";

        teams.forEach(team => {

            const item = document.createElement("div");

            item.className = "item";

            item.innerHTML = `
                <h3>${team.team_name}</h3>

                <p>
                    <strong>Team ID:</strong> ${team.team_id}
                </p>

                <p>
                    <strong>Short Name:</strong> ${team.short_name || ""}
                </p>

                <p>
                    <strong>Owner:</strong> ${team.owner_name || ""}
                </p>

                <p>
                    <strong>Coach:</strong> ${team.coach_name || ""}
                </p>

                <button onclick="editTeam(${team.team_id})">
                    Edit
                </button>

                <button onclick="deleteTeam(${team.team_id})">
                    Delete
                </button>
            `;

            container.appendChild(item);

        });

    } catch (error) {

        console.error(error);

        document.getElementById("teamsList").innerHTML =
            "<p>Failed to load teams.</p>";
    }
}

// async function addTeam() {
//     const teamName = document.getElementById("teamName").value.trim();
//     const shortName = document.getElementById("teamshortName").value.trim();
//     const ownerName = document.getElementById("ownerName").value.trim();
//     const coachName = document.getElementById("coachName").value.trim();
//     const tournamentId = document.getElementById("tournamentId").value;

//     if (!teamName || !shortName || !ownerName || !coachName || !tournamentId) {
//         alert("Please fill all required fields.");
//         return;
//     }

//     try {
//         const response = await fetch(API + "/teams/", {
//             method: "POST",
//             headers: {
//                 "Content-Type": "application/json"
//             },
//             body: JSON.stringify({
//                 team_name: teamName,
//                 short_name: shortName,
//                 owner_name: ownerName,
//                 coach_name: coachName,
//                 tournament_id: parseInt(tournamentId)
//             })
//         });

//         const data = await response.json();

//         if (!response.ok) {
//             throw new Error(data.error || "Failed to add team");
//         }

//         alert("Team added successfully!");

//         // Clear form
//         document.getElementById("teamName").value = "";
//         document.getElementById("shortName").value = "";
//         document.getElementById("ownerName").value = "";
//         document.getElementById("coachName").value = "";
//         document.getElementById("tournamentId").value = "";

//         // Reload teams
//         loadTeams();

//     } catch (error) {
//         console.error(error);
//         alert("Failed to add team: " + error.message);
//     }
// }

async function addTeam() {

    console.log("addTeam() called");
    if (window.editingTeamId) {
    return updateTeam(window.editingTeamId);
    }

    const teamNameElement = document.getElementById("teamName");
    const shortNameElement = document.getElementById("teamShortName");
    const ownerNameElement = document.getElementById("ownerName");
    const coachNameElement = document.getElementById("coachName");
    const tournamentIdElement = document.getElementById("tournamentId");

    console.log("teamName:", teamNameElement);
    console.log("shortName:", shortNameElement);
    console.log("ownerName:", ownerNameElement);
    console.log("coachName:", coachNameElement);
    console.log("tournamentId:", tournamentIdElement);

    if (
        !teamNameElement ||
        !shortNameElement ||
        !ownerNameElement ||
        !coachNameElement ||
        !tournamentIdElement
    ) {
        console.error("One or more HTML elements were NOT found.");
        return;
    }

    const teamName = teamNameElement.value.trim();
    const shortName = shortNameElement.value.trim();
    const ownerName = ownerNameElement.value.trim();
    const coachName = coachNameElement.value.trim();
    const tournamentId = tournamentIdElement.value;

    if (!teamName || !shortName || !ownerName || !coachName || !tournamentId) {
        alert("Please fill all required fields.");
        return;
    }

    try {

        const response = await fetch(API + "/teams/", {
            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                team_name: teamName,
                short_name: shortName,
                owner_name: ownerName,
                coach_name: coachName,
                tournament_id: parseInt(tournamentId)
            })
        });

        const body = await response.json();

        console.log("Server response:", body);

        if (!response.ok) {
            alert("Failed to add team: " + (body.error || "Unknown error"));
            return;
        }

        alert("Team added successfully!");

        await loadTeams();

    } catch (error) {

        console.error("Add team error:", error);
        alert("Error adding team: " + error.message);
    }
}

async function addMatch() {

    const tournamentId = document.getElementById("matchTournamentId").value;
    const team1Id = document.getElementById("matchTeam1Id").value;
    const team2Id = document.getElementById("matchTeam2Id").value;
    const venueId = document.getElementById("matchVenueId").value;
    const matchDate = document.getElementById("matchDate").value;
    const matchTime = document.getElementById("matchTime").value;
    const status = document.getElementById("matchStatus").value;
    const winnerTeamId = document.getElementById("matchWinnerTeamId").value;
    const tossWinnerId = document.getElementById("matchTossWinnerId").value;
    const tossDecision = document.getElementById("matchTossDecision").value;
    const matchResult = document.getElementById("matchResult").value;

    if (
        !tournamentId ||
        !team1Id ||
        !team2Id ||
        !venueId ||
        !matchDate ||
        !matchTime
    ) {
        alert("Please fill all required fields.");
        return;
    }

    if (team1Id === team2Id) {
        alert("Team 1 and Team 2 cannot be the same.");
        return;
    }

    try {

        const response = await fetch(API + "/matches/", {
            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                tournament_id: parseInt(tournamentId),
                team1_id: parseInt(team1Id),
                team2_id: parseInt(team2Id),
                venue_id: parseInt(venueId),
                match_date: matchDate,
                match_time: matchTime,
                status: status,
                winner_team_id: winnerTeamId
                    ? parseInt(winnerTeamId)
                    : null,
                toss_winner_id: tossWinnerId
                    ? parseInt(tossWinnerId)
                    : null,
                toss_decision: tossDecision || null,
                match_result: matchResult
            })
        });

        const data = await response.json();

        console.log("Server response:", data);

        if (!response.ok) {
            throw new Error(data.error || "Failed to add match");
        }

        alert("Match added successfully!");

        loadMatches();

    } catch (error) {

        console.error("Add match error:", error);

        alert(error.message);
    }
}

async function editTeam(teamId) {

    try {

        const response = await fetch(API + `/teams/${teamId}`);

        if (!response.ok) {
            throw new Error("Failed to fetch team");
        }

        const team = await response.json();

        document.getElementById("teamName").value =
            team.team_name || "";

        document.getElementById("teamShortName").value =
            team.short_name || "";

        document.getElementById("ownerName").value =
            team.owner_name || "";

        document.getElementById("coachName").value =
            team.coach_name || "";

        document.getElementById("tournamentId").value =
            team.tournament_id || "";

        window.editingTeamId = teamId;

        document.getElementById("teamSubmitButton").textContent =
            "Update Team";

        alert("Team loaded for editing.");

    } catch (error) {

        console.error(error);

        alert("Failed to load team.");
    }
}

async function updateTeam(teamId) {

    const teamName =
        document.getElementById("teamName").value.trim();

    const shortName =
        document.getElementById("teamShortName").value.trim();

    const ownerName =
        document.getElementById("ownerName").value.trim();

    const coachName =
        document.getElementById("coachName").value.trim();

    const tournamentId =
        document.getElementById("tournamentId").value;

    if (!teamName || !shortName || !ownerName || !coachName || !tournamentId) {
        alert("Please fill all required fields.");
        return;
    }

    try {

        const response = await fetch(API + `/teams/${teamId}`, {
            method: "PUT",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                team_name: teamName,
                short_name: shortName,
                owner_name: ownerName,
                coach_name: coachName,
                tournament_id: parseInt(tournamentId)
            })
        });

        const data = await response.json();

        console.log("Update response:", data);

        if (!response.ok) {
            alert(data.error || "Failed to update team.");
            return;
        }

        alert("Team updated successfully!");

        // Exit edit mode
        window.editingTeamId = null;

        // Change button back to Add Team
        document.getElementById("teamSubmitButton").textContent = "Add Team";

        // Clear form
        document.getElementById("teamName").value = "";
        document.getElementById("teamShortName").value = "";
        document.getElementById("ownerName").value = "";
        document.getElementById("coachName").value = "";
        document.getElementById("tournamentId").value = "";

        // Reload teams
        loadTeams();

    } catch (error) {

        console.error("Update error:", error);

        alert("Failed to update team.");
    }
}


async function deleteTeam(teamId) {

    const confirmed = confirm(
        "Are you sure you want to delete this team?"
    );

    if (!confirmed) {
        return;
    }

    try {

        const response = await fetch(
            API + `/teams/${teamId}`,
            {
                method: "DELETE"
            }
        );

        const data = await response.json();

        console.log("Delete response:", data);

        if (!response.ok) {

            if (data.details) {

                alert(
                    data.error +
                    "\n\nPlayers: " + data.details.players +
                    "\nMatches: " + data.details.matches +
                    "\nPoints Table: " + data.details.points_table +
                    "\nMatch Squads: " + data.details.match_squads +
                    "\nInnings: " + data.details.innings
                );

            } else {
                alert(data.error || "Failed to delete team.");
            }

            return;
        }

        alert("Team deleted successfully!");

        loadTeams();

    } catch (error) {

        console.error("Delete error:", error);

        alert("Failed to delete team.");
    }
}


async function addPlayer() {

    if (window.editingPlayerId) {
        return updatePlayer(window.editingPlayerId);
    }

    const fullName = document.getElementById("playerFullName").value.trim();
    const dob = document.getElementById("playerDob").value;
    const nationality = document.getElementById("playerNationality").value.trim();

    const battingStyle =
        document.getElementById("playerBattingStyle").value || null;

    const bowlingStyle =
        document.getElementById("playerBowlingStyle").value || null;

    const playerRole =
        document.getElementById("playerRole").value || null;

    const jerseyNumber =
        document.getElementById("playerJerseyNumber").value;

    const email =
        document.getElementById("playerEmail").value.trim();

    const phoneNumber =
        document.getElementById("playerPhone").value.trim();

    const height =
        document.getElementById("playerHeight").value || null;

    const weight =
        document.getElementById("playerWeight").value || null;

    const teamId =
        document.getElementById("playerTeamId").value || null;


    // Required fields
    if (
        !fullName ||
        !dob ||
        !nationality ||
        !jerseyNumber ||
        !email ||
        !phoneNumber
    ) {
        alert(
            "Please fill Full Name, DOB, Nationality, Jersey Number, Email and Phone Number."
        );
        return;
    }


    try {

        const response = await fetch(API + "/players/", {
            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                full_name: fullName,
                dob: dob,
                nationality: nationality,
                batting_style: battingStyle,
                bowling_style: bowlingStyle,
                player_role: playerRole,
                jersey_number: parseInt(jerseyNumber),
                email: email,
                phone_number: phoneNumber,
                height_cm: height ? parseFloat(height) : null,
                weight_kg: weight ? parseFloat(weight) : null,
                team_id: teamId ? parseInt(teamId) : null
            })
        });


        const data = await response.json();

        console.log("Server response:", data);


        if (!response.ok) {

            alert(
                "Failed to add player: " +
                (data.error || "Unknown error")
            );

            return;
        }


        alert("Player added successfully!");

        // Clear form
        document.getElementById("playerFullName").value = "";
        document.getElementById("playerDob").value = "";
        document.getElementById("playerNationality").value = "";
        document.getElementById("playerBattingStyle").value = "";
        document.getElementById("playerBowlingStyle").value = "";
        document.getElementById("playerRole").value = "";
        document.getElementById("playerJerseyNumber").value = "";
        document.getElementById("playerEmail").value = "";
        document.getElementById("playerPhone").value = "";
        document.getElementById("playerHeight").value = "";
        document.getElementById("playerWeight").value = "";
        document.getElementById("playerTeamId").value = "";

        // Reload players
        loadPlayers();

    } catch (error) {

        console.error(error);

        alert("Error adding player: " + error);
    }
}

async function editPlayer(playerId) {

    try {

        const response = await fetch(
            API + `/players/${playerId}`
        );

        if (!response.ok) {
            throw new Error("Failed to fetch player");
        }

        const player = await response.json();

        document.getElementById("playerFullName").value =
            player.full_name || "";

        document.getElementById("playerDob").value =
            player.dob ? player.dob.substring(0, 10) : "";

        document.getElementById("playerNationality").value =
            player.nationality || "";

        document.getElementById("playerBattingStyle").value =
            player.batting_style || "";

        document.getElementById("playerBowlingStyle").value =
            player.bowling_style || "";

        document.getElementById("playerRole").value =
            player.player_role || "";

        document.getElementById("playerJerseyNumber").value =
            player.jersey_number || "";

        document.getElementById("playerEmail").value =
            player.email || "";

        document.getElementById("playerPhone").value =
            player.phone_number || "";

        document.getElementById("playerHeight").value =
            player.height_cm || "";

        document.getElementById("playerWeight").value =
            player.weight_kg || "";

        document.getElementById("playerTeamId").value =
            player.team_id || "";

        window.editingPlayerId = playerId;

        // Change button text
        const button = document.querySelector(
            '#players button[onclick="addPlayer()"]'
        );

        if (button) {
            button.textContent = "Update Player";
        }

        alert("Player loaded for editing.");

    } catch (error) {

        console.error(error);

        alert("Failed to load player.");
    }
}

async function updatePlayer(playerId) {

    const fullName =
        document.getElementById("playerFullName").value.trim();

    const dob =
        document.getElementById("playerDob").value;

    const nationality =
        document.getElementById("playerNationality").value.trim();

    const battingStyle =
        document.getElementById("playerBattingStyle").value || null;

    const bowlingStyle =
        document.getElementById("playerBowlingStyle").value || null;

    const playerRole =
        document.getElementById("playerRole").value || null;

    const jerseyNumber =
        document.getElementById("playerJerseyNumber").value;

    const email =
        document.getElementById("playerEmail").value.trim();

    const phoneNumber =
        document.getElementById("playerPhone").value.trim();

    const height =
        document.getElementById("playerHeight").value || null;

    const weight =
        document.getElementById("playerWeight").value || null;

    const teamId =
        document.getElementById("playerTeamId").value || null;


    if (
        !fullName ||
        !dob ||
        !nationality ||
        !jerseyNumber ||
        !email ||
        !phoneNumber
    ) {
        alert("Please fill all required fields.");
        return;
    }


    try {

        const response = await fetch(
            API + `/players/${playerId}`,
            {
                method: "PUT",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify({
                    full_name: fullName,
                    dob: dob,
                    nationality: nationality,
                    batting_style: battingStyle,
                    bowling_style: bowlingStyle,
                    player_role: playerRole,
                    jersey_number: parseInt(jerseyNumber),
                    email: email,
                    phone_number: phoneNumber,
                    height_cm: height ? parseFloat(height) : null,
                    weight_kg: weight ? parseFloat(weight) : null,
                    team_id: teamId ? parseInt(teamId) : null
                })
            }
        );


        const data = await response.json();

        console.log("Update player response:", data);


        if (!response.ok) {

            alert(
                data.error || "Failed to update player."
            );

            return;
        }


        alert("Player updated successfully!");


        // Exit edit mode
        window.editingPlayerId = null;


        // Change button back
        const button = document.querySelector(
            '#players button[onclick="addPlayer()"]'
        );

        if (button) {
            button.textContent = "Add Player";
        }


        // Clear form
        document.getElementById("playerFullName").value = "";
        document.getElementById("playerDob").value = "";
        document.getElementById("playerNationality").value = "";
        document.getElementById("playerBattingStyle").value = "";
        document.getElementById("playerBowlingStyle").value = "";
        document.getElementById("playerRole").value = "";
        document.getElementById("playerJerseyNumber").value = "";
        document.getElementById("playerEmail").value = "";
        document.getElementById("playerPhone").value = "";
        document.getElementById("playerHeight").value = "";
        document.getElementById("playerWeight").value = "";
        document.getElementById("playerTeamId").value = "";


        // Reload players
        loadPlayers();

    } catch (error) {

        console.error("Update player error:", error);

        alert("Failed to update player.");
    }
}

async function deletePlayer(playerId) {

    const confirmed = confirm(
        "Are you sure you want to delete this player?"
    );

    if (!confirmed) {
        return;
    }

    try {

        const response = await fetch(
            API + `/players/${playerId}`,
            {
                method: "DELETE"
            }
        );

        const data = await response.json();

        console.log("Delete player response:", data);

        if (!response.ok) {

            if (data.details) {

                alert(
                    data.error +
                    "\n\nMatch Squads: " +
                    data.details.match_squads +
                    "\nBatting Performance: " +
                    data.details.batting_performance +
                    "\nBowling Performance: " +
                    data.details.bowling_performance
                );

            } else {

                alert(
                    data.error ||
                    "Failed to delete player."
                );
            }

            return;
        }

        alert("Player deleted successfully!");

        loadPlayers();

    } catch (error) {

        console.error("Delete player error:", error);

        alert("Failed to delete player.");
    }
}

async function loadPlayerStats(playerId) {

    console.log("loadPlayerStats called with:", playerId);

    if (!playerId) {
        alert("Please enter a Player ID");
        return;
    }

    try {

        const response = await fetch(
            `${API}/stats/player/${playerId}`
        );

        console.log("Response status:", response.status);

        if (!response.ok) {
            throw new Error("Player stats not found");
        }

        const data = await response.json();

        console.log("Stats received:", data);

        const container = document.getElementById("statisticsResult");

        if (!container) {
            console.error("playerStats container not found!");
            return;
        }

        container.innerHTML = `
            <div class="stats-card">

                <h3>${data.full_name}</h3>

                <h4>Batting</h4>

                <p>Runs: ${data.batting.runs}</p>

                <p>Balls Faced: ${data.batting.balls}</p>

                <p>Fours: ${data.batting.fours}</p>

                <p>Sixes: ${data.batting.sixes}</p>

                <p>Strike Rate: ${data.batting.strike_rate}</p>

                <h4>Bowling</h4>

                <p>Overs: ${data.bowling.overs}</p>

                <p>Runs Conceded: ${data.bowling.runs_conceded}</p>

                <p>Wickets: ${data.bowling.wickets}</p>

                <p>Economy: ${data.bowling.economy}</p>

            </div>
        `;

    } catch (error) {

        console.error("Error loading player stats:", error);

        document.getElementById("statisticsResult").innerHTML = `
            <div class="error">
                Unable to load player statistics.
            </div>
        `;
    }
}