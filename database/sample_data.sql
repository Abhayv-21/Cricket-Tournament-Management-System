-- TOURNAMENT
INSERT INTO tournaments (
    tournament_name,
    season,
    start_date,
    location,
    status
)
VALUES (
    'Sahyadri Super League',
    2026,
    '2026-08-20',
    'IIT Palakkad',
    'Upcoming'
);

-- TEAMS
INSERT INTO teams (
    team_name,
    short_name,
    owner_name,
    coach_name,
    captain_id,
    home_venue_id,
    tournament_id
)
VALUES
(
    'Royal Challengers',
    'RC',
    'Kavya',
    'Muru',
    NULL,
    NULL,
    1
),
(
    'Super Kings',
    'SK',
    'Tarun',
    'Arjun',
    NULL,
    NULL,
    1
);

-- VENUES
INSERT INTO venues (
    venue_name,
    city,
    state,
    country,
    capacity,
    pitch_type,
    tournament_id
)
VALUES
(
    'IIT Palakkad Cricket Ground',
    'Palakkad',
    'Kerala',
    'INDIA',
    5000,
    'Turf',
    1
),
(
    'Main Cricket Ground',
    'Palakkad',
    'Kerala',
    'INDIA',
    3000,
    'Turf',
    1
);

-- assigning the HOME Venues
UPDATE teams
SET home_venue_id = 1
WHERE team_id = 1;

UPDATE teams
SET home_venue_id = 2
WHERE team_id = 2;

-- Adding 22 players

-- ROYAL CHALLENGERS
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
VALUES
('Abhay', '2002-01-10', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'Batsman', 1, 'rc1@test.com', '9000000001', 180, 75, 1),
('VAMSI', '2001-02-15', 'Indian', 'Left-Hand Bat', 'Right-arm Medium', 'Batsman', 2, 'rc2@test.com', '9000000002', 178, 72, 1),
('SANTU', '2003-03-20', 'Indian', 'Right-hand Bat', 'Right-arm Spin', 'All-Rounder', 3, 'rc3@test.com', '9000000003', 182, 78, 1),
('GOKUL', '2002-04-12', 'Indian', 'Right-hand Bat', 'Right-arm Fast', 'Bowler', 4, 'rc4@test.com', '9000000004', 185, 82, 1),
('SAKET', '2001-05-18', 'Indian', 'Left-Hand Bat', 'Left-arm Fast', 'All-Rounder', 5, 'rc5@test.com', '9000000005', 183, 80, 1),
('SURENDRA', '2003-06-22', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'Wicket-Keeper', 6, 'rc6@test.com', '9000000006', 176, 74, 1),
('YUVRAJ', '2002-07-14', 'Indian', 'Right-hand Bat', 'Right-arm Fast', 'Bowler', 7, 'rc7@test.com', '9000000007', 188, 84, 1),
('RAJESH', '2001-08-25', 'Indian', 'Left-Hand Bat', 'Left-arm Spin', 'Bowler', 8, 'rc8@test.com', '9000000008', 181, 76, 1),
('SANJIV', '2003-09-11', 'Indian', 'Right-hand Bat', 'Right-arm Spin', 'Bowler', 9, 'rc9@test.com', '9000000009', 179, 73, 1),
('SANJAY', '2002-10-19', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'All-Rounder', 10, 'rc10@test.com', '9000000010', 184, 79, 1),
('ANKESH', '2001-11-30', 'Indian', 'Left-Hand Bat', 'Left-arm Fast', 'Bowler', 11, 'rc11@test.com', '9000000011', 187, 81, 1);



-- SUPER KINGS
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
VALUES
('Gowtham', '2002-01-11', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'Batsman', 12, 'sk1@test.com', '9000000012', 180, 75, 2),
('Pavan', '2001-02-16', 'Indian', 'Left-Hand Bat', 'Left-arm Medium', 'Batsman', 13, 'sk2@test.com', '9000000013', 178, 72, 2),
('Sreeraj', '2003-03-21', 'Indian', 'Right-hand Bat', 'Right-arm Spin', 'All-Rounder', 14, 'sk3@test.com', '9000000014', 182, 78, 2),
('Daggu', '2002-04-13', 'Indian', 'Right-hand Bat', 'Right-arm Fast', 'Bowler', 15, 'sk4@test.com', '9000000015', 185, 82, 2),
('Kartik', '2001-05-19', 'Indian', 'Left-Hand Bat', 'Left-arm Fast', 'All-Rounder', 16, 'sk5@test.com', '9000000016', 183, 80, 2),
('Akshay', '2003-06-23', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'Wicket-Keeper', 17, 'sk6@test.com', '9000000017', 176, 74, 2),
('JD', '2002-07-15', 'Indian', 'Right-hand Bat', 'Right-arm Fast', 'Bowler', 18, 'sk7@test.com', '9000000018', 188, 84, 2),
('Sreeraj', '2001-08-26', 'Indian', 'Left-Hand Bat', 'Left-arm Spin', 'Bowler', 19, 'sk8@test.com', '9000000019', 181, 76, 2),
('Shashank', '2003-09-12', 'Indian', 'Right-hand Bat', 'Right-arm Spin', 'Bowler', 20, 'sk9@test.com', '9000000020', 179, 73, 2),
('Tarun', '2002-10-20', 'Indian', 'Right-hand Bat', 'Right-arm Medium', 'All-Rounder', 21, 'sk10@test.com', '9000000021', 184, 79, 2),
('Ganesh', '2001-11-29', 'Indian', 'Left-Hand Bat', 'Left-arm Fast', 'Bowler', 22, 'sk11@test.com', '9000000022', 187, 81, 2);

-- ASSIGN CAPTAINS

UPDATE teams
SET captain_id = 1
WHERE team_id = 1;

UPDATE teams
SET captain_id = 12
WHERE team_id = 2;


-- CREATEING THE TESRT MATCH
INSERT INTO matches (
    tournament_id,
    team1_id,
    team2_id,
    venue_id,
    match_date,
    status,
    match_result,
    match_time
)
VALUES (
    1,
    1,
    2,
    1,
    '2026-08-20',
    'Scheduled',
    'Pending',
    '14:00:00'
);