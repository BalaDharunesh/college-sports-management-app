const mysql = require('mysql2/promise');
const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function initDb() {
  const dbName = process.env.DB_NAME || 'sports_management_db';

  console.log('[DB Init] Attempting connection to MySQL...');
  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      multipleStatements: true
    });

    console.log('[DB Init] MySQL connected. Creating database schema...');
    const schemaPath = path.join(__dirname, '../config/schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    await connection.query(schemaSql);
    await connection.query(`USE \`${dbName}\`;`);

    await seedMySQLData(connection);
    await connection.end();
    console.log('[DB Init] MySQL Initialization & Seed completed successfully!');
    return;
  } catch (err) {
    console.warn('[DB Init] MySQL not available or access denied:', err.message);
    console.log('[DB Init] Initializing SQLite database schema and seed data...');
    await initSQLite();
  }
}

async function seedMySQLData(connection) {
  const [existingSports] = await connection.query('SELECT COUNT(*) as count FROM sports');
  if (existingSports[0].count === 0) {
    console.log('[DB Init - MySQL] Seeding 8 sports...');
    const sports = [
      ['Cricket', 'College Cricket Team & Tournaments'],
      ['Football', 'College Football Team & Inter-College Leagues'],
      ['Basketball', 'Men & Women Basketball Teams'],
      ['Volleyball', 'College Volleyball Squad'],
      ['Tennis', 'Lawn Tennis Singles & Doubles'],
      ['Badminton', 'Badminton Racket Sports'],
      ['Table Tennis', 'Indoor Table Tennis Championships'],
      ['Athletics', 'Track & Field Athletics Events']
    ];
    for (const [name, desc] of sports) {
      await connection.query('INSERT INTO sports (name, description) VALUES (?, ?)', [name, desc]);
    }
  }

  const [existingUsers] = await connection.query('SELECT COUNT(*) as count FROM users');
  if (existingUsers[0].count === 0) {
    console.log('[DB Init - MySQL] Seeding sample users, teams, matches, selections...');
    const passwordHash = await bcrypt.hash('Password123!', 10);

    // Staff 1 (Cricket)
    const [s1] = await connection.query(
      `INSERT INTO users (email, password, role, name, department, phone) VALUES (?, ?, 'STAFF', ?, ?, ?)`,
      ['staff.cricket@college.edu', passwordHash, 'Prof. Robert Vance', 'Physical Education', '+19876543210']
    );
    // Captain 1 (Cricket)
    const [c1] = await connection.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'CAPTAIN', ?, ?, ?, ?, ?)`,
      ['captain.cricket@college.edu', passwordHash, 'Rahul Sharma', '21CS001', 'Computer Science & Engineering', '4th Year', '+19876543211']
    );
    // Player 1 (Cricket)
    const [p1U] = await connection.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`,
      ['player.virat@college.edu', passwordHash, 'Virat K', '22CS045', 'Computer Science & Engineering', '3rd Year', '+19876543212']
    );
    // Player 2 (Cricket)
    const [p2U] = await connection.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`,
      ['player.rohit@college.edu', passwordHash, 'Rohit S', '22ME012', 'Mechanical Engineering', '3rd Year', '+19876543213']
    );
    // Player 3 (Cricket)
    const [p3U] = await connection.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`,
      ['player.jasprit@college.edu', passwordHash, 'Jasprit B', '23ECE088', 'Electronics & Communication', '2nd Year', '+19876543214']
    );

    // Football Staff & Captain
    const [s2] = await connection.query(
      `INSERT INTO users (email, password, role, name, department, phone) VALUES (?, ?, 'STAFF', ?, ?, ?)`,
      ['staff.football@college.edu', passwordHash, 'Dr. Sarah Jenkins', 'Sports Science', '+19876543215']
    );
    const [c2] = await connection.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'CAPTAIN', ?, ?, ?, ?, ?)`,
      ['captain.football@college.edu', passwordHash, 'Alex Morgan', '21ECE002', 'Electronics & Communication', '4th Year', '+19876543216']
    );

    // Create Teams
    const [cricketSport] = await connection.query('SELECT id FROM sports WHERE name = "Cricket"');
    const [footballSport] = await connection.query('SELECT id FROM sports WHERE name = "Football"');

    const [t1] = await connection.query(
      `INSERT INTO teams (name, sport_id, staff_id, captain_id) VALUES (?, ?, ?, ?)`,
      ['Strikers Cricket XI', cricketSport[0].id, s1.insertId, c1.insertId]
    );
    const [t2] = await connection.query(
      `INSERT INTO teams (name, sport_id, staff_id, captain_id) VALUES (?, ?, ?, ?)`,
      ['Panthers Football FC', footballSport[0].id, s2.insertId, c2.insertId]
    );

    // Create Player records
    const [p1] = await connection.query(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p1U.insertId, t1.insertId, 'Top-Order Batsman', 18]);
    const [p2] = await connection.query(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p2U.insertId, t1.insertId, 'Opening Batsman', 45]);
    const [p3] = await connection.query(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p3U.insertId, t1.insertId, 'Fast Bowler', 93]);

    // Matches
    const today = new Date();
    const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const pastDate = new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const deadline = new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000).toISOString().slice(0, 19).replace('T', ' ');

    const [m1] = await connection.query(
      `INSERT INTO matches (title, sport_id, team_id, opponent_name, match_date, start_time, venue, selection_deadline, description, status)
       VALUES (?, ?, ?, ?, ?, '09:30:00', ?, ?, ?, 'SCHEDULED')`,
      ['Inter-College T20 Trophy Quarter-Final', cricketSport[0].id, t1.insertId, 'Loyola College XI', nextWeek, 'Main University Sports Complex Ground A', deadline, 'Crucial knockout match for university championship ranking.']
    );

    const [m2] = await connection.query(
      `INSERT INTO matches (title, sport_id, team_id, opponent_name, match_date, start_time, venue, selection_deadline, description, status)
       VALUES (?, ?, ?, ?, ?, '14:00:00', ?, ?, ?, 'COMPLETED')`,
      ['Friendly Warmup Match', cricketSport[0].id, t1.insertId, 'St. Xavier XI', pastDate, 'College Oval Ground', deadline, 'Warmup match before tournament.']
    );

    await connection.query(
      `INSERT INTO match_results (match_id, team_score, opponent_score, outcome, remarks) VALUES (?, 185, 162, 'WIN', ?)`,
      [m2.insertId, 'Strikers XI won by 23 runs. Virat K scored 72*.']
    );

    // Selections
    await connection.query(`INSERT INTO match_selections (match_id, player_id, status, reviewed_by, review_timestamp) VALUES (?, ?, 'APPROVED', ?, NOW())`, [m1.insertId, p1.insertId, s1.insertId]);
    await connection.query(`INSERT INTO match_selections (match_id, player_id, status) VALUES (?, ?, 'PENDING')`, [m1.insertId, p2.insertId]);
    await connection.query(`INSERT INTO match_selections (match_id, player_id, status) VALUES (?, ?, 'PENDING')`, [m1.insertId, p3.insertId]);

    // Training
    const trainDate = new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    await connection.query(
      `INSERT INTO training_schedules (title, team_id, training_date, start_time, end_time, venue, description) VALUES (?, ?, ?, '06:30:00', '08:30:00', ?, ?)`,
      ['Batting & Bowling Net Practice', t1.insertId, trainDate, 'University Nets - Pitch 2 & 3', 'Focus on death overs bowling and spin response. Mandatory attendance for selected squad.']
    );

    // OD Request
    const [od] = await connection.query(
      `INSERT INTO od_requests (match_id, team_id, captain_id, reason, request_date, remarks, status) VALUES (?, ?, ?, ?, ?, ?, 'PENDING')`,
      [m1.insertId, t1.insertId, c1.insertId, 'Inter-College T20 Tournament Quarter-Final participation requiring lab session exemption.', nextWeek, 'Covers 3 players for full day academic credit.']
    );
    await connection.query(`INSERT INTO od_request_players (od_request_id, player_id) VALUES (?, ?), (?, ?), (?, ?)`, [od.insertId, p1.insertId, od.insertId, p2.insertId, od.insertId, p3.insertId]);

    // TA/DA Request
    const [tada] = await connection.query(
      `INSERT INTO tada_requests (match_id, team_id, captain_id, travel_details, estimated_amount, remarks, status) VALUES (?, ?, ?, ?, 2450.00, ?, 'PENDING')`,
      [m1.insertId, t1.insertId, c1.insertId, 'Bus transport for 15 squad members + energy drinks & lunch allowances.', 'Receipts will be provided post-match.']
    );
    await connection.query(`INSERT INTO tada_request_players (tada_request_id, player_id) VALUES (?, ?), (?, ?)`, [tada.insertId, p1.insertId, tada.insertId, p2.insertId]);

    // Notifications
    await connection.query(
      `INSERT INTO notifications (user_id, title, message, type, reference_id, is_read) VALUES (?, ?, ?, 'MATCH_SELECTION', ?, 0)`,
      [p1U.insertId, 'Official Match Squad Selection!', 'Congratulations! You have been officially approved by staff for Inter-College T20 Trophy Quarter-Final.', m1.insertId]
    );
  }
}

async function initSQLite() {
  const dbDir = path.join(__dirname, '../../data');
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }
  const dbPath = path.join(dbDir, 'sports_management.sqlite');
  const db = new sqlite3.Database(dbPath);

  const runSql = (sql, params = []) => new Promise((res, rej) => db.run(sql, params, function(err) { if (err) rej(err); else res(this); }));
  const getSql = (sql, params = []) => new Promise((res, rej) => db.get(sql, params, (err, row) => err ? rej(err) : res(row)));
  const allSql = (sql, params = []) => new Promise((res, rej) => db.all(sql, params, (err, rows) => err ? rej(err) : res(rows)));

  await runSql(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role TEXT NOT NULL,
    name TEXT NOT NULL,
    register_number TEXT UNIQUE,
    department TEXT,
    academic_year TEXT,
    phone TEXT,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS sports (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS teams (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    sport_id INTEGER NOT NULL,
    staff_id INTEGER UNIQUE,
    captain_id INTEGER UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER UNIQUE NOT NULL,
    team_id INTEGER NOT NULL,
    position TEXT,
    jersey_number INTEGER,
    is_active INTEGER DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS matches (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    sport_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    opponent_name TEXT NOT NULL,
    match_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    venue TEXT NOT NULL,
    selection_deadline TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'SCHEDULED',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS match_selections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    status TEXT DEFAULT 'PENDING',
    reviewed_by INTEGER,
    review_timestamp TEXT,
    rejection_reason TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(match_id, player_id)
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS match_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER UNIQUE NOT NULL,
    team_score INTEGER DEFAULT 0,
    opponent_score INTEGER DEFAULT 0,
    outcome TEXT NOT NULL,
    remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS training_schedules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    team_id INTEGER NOT NULL,
    training_date TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    venue TEXT NOT NULL,
    description TEXT,
    is_cancelled INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS od_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    captain_id INTEGER NOT NULL,
    reason TEXT NOT NULL,
    request_date TEXT NOT NULL,
    remarks TEXT,
    status TEXT DEFAULT 'PENDING',
    reviewed_by INTEGER,
    review_timestamp TEXT,
    staff_remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS tada_requests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    captain_id INTEGER NOT NULL,
    travel_details TEXT NOT NULL,
    estimated_amount REAL NOT NULL,
    actual_amount REAL,
    remarks TEXT,
    status TEXT DEFAULT 'PENDING',
    reviewed_by INTEGER,
    review_timestamp TEXT,
    staff_remarks TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS od_request_players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    od_request_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    UNIQUE(od_request_id, player_id)
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS tada_request_players (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tada_request_id INTEGER NOT NULL,
    player_id INTEGER NOT NULL,
    UNIQUE(tada_request_id, player_id)
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS match_feedback (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    match_id INTEGER NOT NULL,
    team_id INTEGER NOT NULL,
    captain_id INTEGER NOT NULL,
    category TEXT NOT NULL,
    feedback_text TEXT NOT NULL,
    suggestions TEXT,
    staff_response TEXT,
    responded_at TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    reference_id INTEGER,
    is_read INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  await runSql(`CREATE TABLE IF NOT EXISTS device_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    token TEXT UNIQUE NOT NULL,
    platform TEXT DEFAULT 'android',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);

  // Seed Sports if empty
  const sportsCount = await getSql('SELECT COUNT(*) as count FROM sports');
  if (sportsCount.count === 0) {
    const sports = [
      ['Cricket', 'College Cricket Team & Tournaments'],
      ['Football', 'College Football Team & Inter-College Leagues'],
      ['Basketball', 'Men & Women Basketball Teams'],
      ['Volleyball', 'College Volleyball Squad'],
      ['Tennis', 'Lawn Tennis Singles & Doubles'],
      ['Badminton', 'Badminton Racket Sports'],
      ['Table Tennis', 'Indoor Table Tennis Championships'],
      ['Athletics', 'Track & Field Athletics Events']
    ];
    for (const [n, d] of sports) {
      await runSql('INSERT INTO sports (name, description) VALUES (?, ?)', [n, d]);
    }
  }

  // Seed Users if empty
  const usersCount = await getSql('SELECT COUNT(*) as count FROM users');
  if (usersCount.count === 0) {
    const passwordHash = await bcrypt.hash('Password123!', 10);

    const s1 = await runSql(`INSERT INTO users (email, password, role, name, department, phone) VALUES (?, ?, 'STAFF', ?, ?, ?)`, ['staff.cricket@college.edu', passwordHash, 'Prof. Robert Vance', 'Physical Education', '+19876543210']);
    const c1 = await runSql(`INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'CAPTAIN', ?, ?, ?, ?, ?)`, ['captain.cricket@college.edu', passwordHash, 'Rahul Sharma', '21CS001', 'Computer Science & Engineering', '4th Year', '+19876543211']);
    const p1U = await runSql(`INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`, ['player.virat@college.edu', passwordHash, 'Virat K', '22CS045', 'Computer Science & Engineering', '3rd Year', '+19876543212']);
    const p2U = await runSql(`INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`, ['player.rohit@college.edu', passwordHash, 'Rohit S', '22ME012', 'Mechanical Engineering', '3rd Year', '+19876543213']);
    const p3U = await runSql(`INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?)`, ['player.jasprit@college.edu', passwordHash, 'Jasprit B', '23ECE088', 'Electronics & Communication', '2nd Year', '+19876543214']);

    const s2 = await runSql(`INSERT INTO users (email, password, role, name, department, phone) VALUES (?, ?, 'STAFF', ?, ?, ?)`, ['staff.football@college.edu', passwordHash, 'Dr. Sarah Jenkins', 'Sports Science', '+19876543215']);
    const c2 = await runSql(`INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone) VALUES (?, ?, 'CAPTAIN', ?, ?, ?, ?, ?)`, ['captain.football@college.edu', passwordHash, 'Alex Morgan', '21ECE002', 'Electronics & Communication', '4th Year', '+19876543216']);

    const cricket = await getSql('SELECT id FROM sports WHERE name = "Cricket"');
    const football = await getSql('SELECT id FROM sports WHERE name = "Football"');

    const t1 = await runSql(`INSERT INTO teams (name, sport_id, staff_id, captain_id) VALUES (?, ?, ?, ?)`, ['Strikers Cricket XI', cricket.id, s1.lastID, c1.lastID]);
    const t2 = await runSql(`INSERT INTO teams (name, sport_id, staff_id, captain_id) VALUES (?, ?, ?, ?)`, ['Panthers Football FC', football.id, s2.lastID, c2.lastID]);

    const p1 = await runSql(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p1U.lastID, t1.lastID, 'Top-Order Batsman', 18]);
    const p2 = await runSql(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p2U.lastID, t1.lastID, 'Opening Batsman', 45]);
    const p3 = await runSql(`INSERT INTO players (user_id, team_id, position, jersey_number) VALUES (?, ?, ?, ?)`, [p3U.lastID, t1.lastID, 'Fast Bowler', 93]);

    const today = new Date();
    const nextWeek = new Date(today.getTime() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const pastDate = new Date(today.getTime() - 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const deadline = new Date(today.getTime() + 5 * 24 * 60 * 60 * 1000).toISOString().slice(0, 19).replace('T', ' ');

    const m1 = await runSql(`INSERT INTO matches (title, sport_id, team_id, opponent_name, match_date, start_time, venue, selection_deadline, description, status) VALUES (?, ?, ?, ?, ?, '09:30:00', ?, ?, ?, 'SCHEDULED')`, ['Inter-College T20 Trophy Quarter-Final', cricket.id, t1.lastID, 'Loyola College XI', nextWeek, 'Main University Sports Complex Ground A', deadline, 'Crucial knockout match for university championship ranking.']);
    const m2 = await runSql(`INSERT INTO matches (title, sport_id, team_id, opponent_name, match_date, start_time, venue, selection_deadline, description, status) VALUES (?, ?, ?, ?, ?, '14:00:00', ?, ?, ?, 'COMPLETED')`, ['Friendly Warmup Match', cricket.id, t1.lastID, 'St. Xavier XI', pastDate, 'College Oval Ground', deadline, 'Warmup match before tournament.']);

    await runSql(`INSERT INTO match_results (match_id, team_score, opponent_score, outcome, remarks) VALUES (?, 185, 162, 'WIN', ?)`, [m2.lastID, 'Strikers XI won by 23 runs. Virat K scored 72*.']);

    await runSql(`INSERT INTO match_selections (match_id, player_id, status, reviewed_by, review_timestamp) VALUES (?, ?, 'APPROVED', ?, datetime('now'))`, [m1.lastID, p1.lastID, s1.lastID]);
    await runSql(`INSERT INTO match_selections (match_id, player_id, status) VALUES (?, ?, 'PENDING')`, [m1.lastID, p2.lastID]);
    await runSql(`INSERT INTO match_selections (match_id, player_id, status) VALUES (?, ?, 'PENDING')`, [m1.lastID, p3.lastID]);

    const trainDate = new Date(today.getTime() + 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    await runSql(`INSERT INTO training_schedules (title, team_id, training_date, start_time, end_time, venue, description) VALUES (?, ?, ?, '06:30:00', '08:30:00', ?, ?)`, ['Batting & Bowling Net Practice', t1.lastID, trainDate, 'University Nets - Pitch 2 & 3', 'Focus on death overs bowling and spin response. Mandatory attendance for selected squad.']);

    const od = await runSql(`INSERT INTO od_requests (match_id, team_id, captain_id, reason, request_date, remarks, status) VALUES (?, ?, ?, ?, ?, ?, 'PENDING')`, [m1.lastID, t1.lastID, c1.lastID, 'Inter-College T20 Tournament Quarter-Final participation requiring lab session exemption.', nextWeek, 'Covers 3 players for full day academic credit.']);
    await runSql(`INSERT INTO od_request_players (od_request_id, player_id) VALUES (?, ?)`, [od.lastID, p1.lastID]);
    await runSql(`INSERT INTO od_request_players (od_request_id, player_id) VALUES (?, ?)`, [od.lastID, p2.lastID]);
    await runSql(`INSERT INTO od_request_players (od_request_id, player_id) VALUES (?, ?)`, [od.lastID, p3.lastID]);

    const tada = await runSql(`INSERT INTO tada_requests (match_id, team_id, captain_id, travel_details, estimated_amount, remarks, status) VALUES (?, ?, ?, ?, 2450.00, ?, 'PENDING')`, [m1.lastID, t1.lastID, c1.lastID, 'Bus transport for 15 squad members + energy drinks & lunch allowances.', 'Receipts will be provided post-match.']);
    await runSql(`INSERT INTO tada_request_players (tada_request_id, player_id) VALUES (?, ?)`, [tada.lastID, p1.lastID]);
    await runSql(`INSERT INTO tada_request_players (tada_request_id, player_id) VALUES (?, ?)`, [tada.lastID, p2.lastID]);

    await runSql(`INSERT INTO notifications (user_id, title, message, type, reference_id, is_read) VALUES (?, ?, ?, 'MATCH_SELECTION', ?, 0)`, [p1U.lastID, 'Official Match Squad Selection!', 'Congratulations! You have been officially approved by staff for Inter-College T20 Trophy Quarter-Final.', m1.lastID]);
  }

  // Populate 5 teams: Cricket (15 players), Football (15 players), Tennis (10 players), Badminton (10 players), Basketball (10 players)
  try {
    const passwordHash = await bcrypt.hash('Password123!', 10);
    const runSql = (sql, params = []) => new Promise((res, rej) => db.run(sql, params, function(err) { if (err) rej(err); else res(this); }));
    const getSql = (sql, params = []) => new Promise((res, rej) => db.get(sql, params, (err, row) => err ? rej(err) : res(row)));

    async function upsertUser({ email, role, name, register_number, department, academic_year, phone }) {
      let existing = await getSql('SELECT id FROM users WHERE email = ?', [email]);
      if (existing) {
        await runSql(
          `UPDATE users SET name = ?, role = ?, register_number = ?, department = ?, academic_year = ?, phone = ?, is_active = 1 WHERE id = ?`,
          [name, role, register_number || null, department || null, academic_year || null, phone || null, existing.id]
        );
        return existing.id;
      } else {
        let res = await runSql(
          `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone, is_active)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
          [email, passwordHash, role, name, register_number || null, department || null, academic_year || null, phone || null]
        );
        return res.lastID;
      }
    }

    async function upsertTeam(name, sportName, staffId, captainId) {
      let sport = await getSql('SELECT id FROM sports WHERE name = ?', [sportName]);
      if (!sport) {
        let sRes = await runSql('INSERT INTO sports (name, description) VALUES (?, ?)', [sportName, `${sportName} College Squad`]);
        sport = { id: sRes.lastID };
      }
      let team = await getSql('SELECT id FROM teams WHERE name = ? OR sport_id = ?', [name, sport.id]);
      if (team) {
        await runSql('UPDATE teams SET name = ?, staff_id = ?, captain_id = ? WHERE id = ?', [name, staffId, captainId, team.id]);
        return team.id;
      } else {
        let tRes = await runSql('INSERT INTO teams (name, sport_id, staff_id, captain_id) VALUES (?, ?, ?, ?)', [name, sport.id, staffId, captainId]);
        return tRes.lastID;
      }
    }

    async function upsertPlayer(userId, teamId, position, jerseyNumber) {
      let player = await getSql('SELECT id FROM players WHERE user_id = ?', [userId]);
      if (player) {
        await runSql('UPDATE players SET team_id = ?, position = ?, jersey_number = ?, is_active = 1 WHERE id = ?', [teamId, position, jerseyNumber, player.id]);
        return player.id;
      } else {
        let pRes = await runSql('INSERT INTO players (user_id, team_id, position, jersey_number, is_active) VALUES (?, ?, ?, ?, 1)', [userId, teamId, position, jerseyNumber]);
        return pRes.lastID;
      }
    }

    // Cricket (15 Players)
    const cStaff = await upsertUser({ email: 'staff.cricket@college.edu', role: 'STAFF', name: 'Prof. Robert Vance', department: 'Physical Education', phone: '+19876543210' });
    const cCapt = await upsertUser({ email: 'captain.cricket@college.edu', role: 'CAPTAIN', name: 'Rahul Sharma', register_number: '21CS001', department: 'Computer Science & Engineering', academic_year: '4th Year', phone: '+19876543211' });
    const cTeam = await upsertTeam('Strikers Cricket XI', 'Cricket', cStaff, cCapt);

    const cPlayers = [
      { name: 'Virat K', email: 'player.virat@college.edu', reg: '22CS045', dept: 'Computer Science & Engineering', year: '3rd Year', pos: 'Top-Order Batsman', jersey: 18 },
      { name: 'Rohit S', email: 'player.rohit@college.edu', reg: '22ME012', dept: 'Mechanical Engineering', year: '3rd Year', pos: 'Opening Batsman', jersey: 45 },
      { name: 'Jasprit B', email: 'player.jasprit@college.edu', reg: '23ECE088', dept: 'Electronics & Communication', year: '2nd Year', pos: 'Fast Bowler', jersey: 93 },
      { name: 'Rishabh P', email: 'player.rishabh@college.edu', reg: '22CS101', dept: 'Computer Science & Engineering', year: '3rd Year', pos: 'Wicketkeeper Batsman', jersey: 17 },
      { name: 'Hardik P', email: 'player.hardik@college.edu', reg: '21EEE034', dept: 'Electrical Engineering', year: '4th Year', pos: 'All-Rounder', jersey: 33 },
      { name: 'Ravindra J', email: 'player.ravindra@college.edu', reg: '21CIV055', dept: 'Civil Engineering', year: '4th Year', pos: 'Spin All-Rounder', jersey: 8 },
      { name: 'Shubman G', email: 'player.shubman@college.edu', reg: '23CS019', dept: 'Computer Science & Engineering', year: '2nd Year', pos: 'Top-Order Batsman', jersey: 77 },
      { name: 'Suryakumar Y', email: 'player.surya@college.edu', reg: '22ME089', dept: 'Mechanical Engineering', year: '3rd Year', pos: 'Middle-Order Batsman', jersey: 63 },
      { name: 'Mohammed S', email: 'player.shami@college.edu', reg: '21ECE102', dept: 'Electronics & Communication', year: '4th Year', pos: 'Fast Bowler', jersey: 11 },
      { name: 'Kuldeep Y', email: 'player.kuldeep@college.edu', reg: '23CIV041', dept: 'Civil Engineering', year: '2nd Year', pos: 'Left-Arm Wrist Spinner', jersey: 23 },
      { name: 'Shreyas I', email: 'player.shreyas@college.edu', reg: '22EEE067', dept: 'Electrical Engineering', year: '3rd Year', pos: 'Middle-Order Batsman', jersey: 41 },
      { name: 'Mohammed Siraj', email: 'player.siraj@college.edu', reg: '23ME055', dept: 'Mechanical Engineering', year: '2nd Year', pos: 'Fast Bowler', jersey: 73 },
      { name: 'Axar P', email: 'player.axar@college.edu', reg: '22ECE044', dept: 'Electronics & Communication', year: '3rd Year', pos: 'Spin All-Rounder', jersey: 20 },
      { name: 'Yashasvi J', email: 'player.yashasvi@college.edu', reg: '24CS005', dept: 'Computer Science & Engineering', year: '1st Year', pos: 'Opening Batsman', jersey: 64 },
      { name: 'Arshdeep S', email: 'player.arshdeep@college.edu', reg: '23EEE091', dept: 'Electrical Engineering', year: '2nd Year', pos: 'Left-Arm Fast Bowler', jersey: 28 }
    ];
    for (const p of cPlayers) {
      const uId = await upsertUser({ email: p.email, role: 'PLAYER', name: p.name, register_number: p.reg, department: p.dept, academic_year: p.year, phone: '+19876543200' });
      await upsertPlayer(uId, cTeam, p.pos, p.jersey);
    }

    // Football (15 Players)
    const fStaff = await upsertUser({ email: 'staff.football@college.edu', role: 'STAFF', name: 'Dr. Sarah Jenkins', department: 'Sports Science', phone: '+19876543215' });
    const fCapt = await upsertUser({ email: 'captain.football@college.edu', role: 'CAPTAIN', name: 'Alex Morgan', register_number: '21ECE002', department: 'Electronics & Communication', academic_year: '4th Year', phone: '+19876543216' });
    const fTeam = await upsertTeam('Panthers Football FC', 'Football', fStaff, fCapt);

    const fPlayers = [
      { name: 'Marcus Rashford', email: 'player.marcus@college.edu', reg: '22CS201', dept: 'Computer Science & Engineering', year: '3rd Year', pos: 'Forward', jersey: 10 },
      { name: 'Bruno Fernandes', email: 'player.bruno@college.edu', reg: '21ME202', dept: 'Mechanical Engineering', year: '4th Year', pos: 'Attacking Midfielder', jersey: 8 },
      { name: 'Casemiro Santos', email: 'player.casemiro@college.edu', reg: '21EEE203', dept: 'Electrical Engineering', year: '4th Year', pos: 'Defensive Midfielder', jersey: 18 },
      { name: 'Lisandro Martinez', email: 'player.lisandro@college.edu', reg: '22CIV204', dept: 'Civil Engineering', year: '3rd Year', pos: 'Center Back', jersey: 6 },
      { name: 'Diogo Dalot', email: 'player.diogo@college.edu', reg: '23ECE205', dept: 'Electronics & Communication', year: '2nd Year', pos: 'Right Back', jersey: 20 },
      { name: 'Luke Shaw', email: 'player.luke@college.edu', reg: '21CS206', dept: 'Computer Science & Engineering', year: '4th Year', pos: 'Left Back', jersey: 23 },
      { name: 'Andre Onana', email: 'player.onana@college.edu', reg: '22ME207', dept: 'Mechanical Engineering', year: '3rd Year', pos: 'Goalkeeper', jersey: 24 },
      { name: 'Alejandro Garnacho', email: 'player.garnacho@college.edu', reg: '24CS208', dept: 'Computer Science & Engineering', year: '1st Year', pos: 'Left Winger', jersey: 17 },
      { name: 'Rasmus Hojlund', email: 'player.rasmus@college.edu', reg: '23ECE209', dept: 'Electronics & Communication', year: '2nd Year', pos: 'Striker', jersey: 9 },
      { name: 'Kobbie Mainoo', email: 'player.kobbie@college.edu', reg: '24EEE210', dept: 'Electrical Engineering', year: '1st Year', pos: 'Central Midfielder', jersey: 37 },
      { name: 'Harry Maguire', email: 'player.maguire@college.edu', reg: '21CIV211', dept: 'Civil Engineering', year: '4th Year', pos: 'Center Back', jersey: 5 },
      { name: 'Amad Diallo', email: 'player.amad@college.edu', reg: '23CS212', dept: 'Computer Science & Engineering', year: '2nd Year', pos: 'Right Winger', jersey: 16 },
      { name: 'Christian Eriksen', email: 'player.eriksen@college.edu', reg: '21ME213', dept: 'Mechanical Engineering', year: '4th Year', pos: 'Central Midfielder', jersey: 14 },
      { name: 'Mason Mount', email: 'player.mount@college.edu', reg: '22ECE214', dept: 'Electronics & Communication', year: '3rd Year', pos: 'Attacking Midfielder', jersey: 7 },
      { name: 'Altay Bayindir', email: 'player.altay@college.edu', reg: '23CIV215', dept: 'Civil Engineering', year: '2nd Year', pos: 'Substitute Goalkeeper', jersey: 1 }
    ];
    for (const p of fPlayers) {
      const uId = await upsertUser({ email: p.email, role: 'PLAYER', name: p.name, register_number: p.reg, department: p.dept, academic_year: p.year, phone: '+19876543210' });
      await upsertPlayer(uId, fTeam, p.pos, p.jersey);
    }

    // Tennis (10 Players)
    const tStaff = await upsertUser({ email: 'staff.tennis@college.edu', role: 'STAFF', name: 'Prof. David Miller', department: 'Physical Education', phone: '+19876543230' });
    const tCapt = await upsertUser({ email: 'captain.tennis@college.edu', role: 'CAPTAIN', name: 'Carlos Alcaraz', register_number: '21CS301', department: 'Computer Science & Engineering', academic_year: '4th Year', phone: '+19876543231' });
    const tTeam = await upsertTeam('Aces Tennis Squad', 'Tennis', tStaff, tCapt);

    const tPlayers = [
      { name: 'Jannik Sinner', email: 'player.jannik@college.edu', reg: '22CS302', dept: 'Computer Science & Engineering', year: '3rd Year', pos: 'Singles Specialist', jersey: 1 },
      { name: 'Daniil Medvedev', email: 'player.daniil@college.edu', reg: '21ME303', dept: 'Mechanical Engineering', year: '4th Year', pos: 'Baseline Specialist', jersey: 2 },
      { name: 'Alexander Zverev', email: 'player.zverev@college.edu', reg: '22ECE304', dept: 'Electronics & Communication', year: '3rd Year', pos: 'Serve & Volleyer', jersey: 3 },
      { name: 'Stefanos Tsitsipas', email: 'player.stefanos@college.edu', reg: '21CIV305', dept: 'Civil Engineering', year: '4th Year', pos: 'All-Court Player', jersey: 4 },
      { name: 'Casper Ruud', email: 'player.casper@college.edu', reg: '22EEE306', dept: 'Electrical Engineering', year: '3rd Year', pos: 'Clay-Court Specialist', jersey: 5 },
      { name: 'Andrey Rublev', email: 'player.andrey@college.edu', reg: '23CS307', dept: 'Computer Science & Engineering', year: '2nd Year', pos: 'Hard-Court Specialist', jersey: 6 },
      { name: 'Alex de Minaur', email: 'player.deminaur@college.edu', reg: '23ECE308', dept: 'Electronics & Communication', year: '2nd Year', pos: 'Speed & Counter-Puncher', jersey: 7 },
      { name: 'Grigor Dimitrov', email: 'player.grigor@college.edu', reg: '21ME309', dept: 'Mechanical Engineering', year: '4th Year', pos: 'Doubles Specialist', jersey: 8 },
      { name: 'Taylor Fritz', email: 'player.fritz@college.edu', reg: '22CIV310', dept: 'Civil Engineering', year: '3rd Year', pos: 'Power Server', jersey: 9 },
      { name: 'Tommy Paul', email: 'player.tommy@college.edu', reg: '23EEE311', dept: 'Electrical Engineering', year: '2nd Year', pos: 'Doubles Specialist', jersey: 10 }
    ];
    for (const p of tPlayers) {
      const uId = await upsertUser({ email: p.email, role: 'PLAYER', name: p.name, register_number: p.reg, department: p.dept, academic_year: p.year, phone: '+19876543230' });
      await upsertPlayer(uId, tTeam, p.pos, p.jersey);
    }

    // Badminton (10 Players)
    const bStaff = await upsertUser({ email: 'staff.badminton@college.edu', role: 'STAFF', name: 'Prof. Emma Watson', department: 'Physical Education', phone: '+19876543240' });
    const bCapt = await upsertUser({ email: 'captain.badminton@college.edu', role: 'CAPTAIN', name: 'Lakshya Sen', register_number: '21ECE401', department: 'Electronics & Communication', academic_year: '4th Year', phone: '+19876543241' });
    const bTeam = await upsertTeam('Smashers Badminton XI', 'Badminton', bStaff, bCapt);

    const bPlayers = [
      { name: 'Viktor Axelsen', email: 'player.viktor@college.edu', reg: '21CS402', dept: 'Computer Science & Engineering', year: '4th Year', pos: "Men's Singles Specialist", jersey: 1 },
      { name: 'Shi Yu Qi', email: 'player.shiyuqi@college.edu', reg: '22ME403', dept: 'Mechanical Engineering', year: '3rd Year', pos: "Men's Singles Specialist", jersey: 2 },
      { name: 'Jonatan Christie', email: 'player.jonatan@college.edu', reg: '22ECE404', dept: 'Electronics & Communication', year: '3rd Year', pos: 'Singles Attacker', jersey: 3 },
      { name: 'Anders Antonsen', email: 'player.anders@college.edu', reg: '21CIV405', dept: 'Civil Engineering', year: '4th Year', pos: 'Singles Tactical Player', jersey: 4 },
      { name: 'Satwiksairaj Rankireddy', email: 'player.satwik@college.edu', reg: '22EEE406', dept: 'Electrical Engineering', year: '3rd Year', pos: "Men's Doubles Specialist", jersey: 5 },
      { name: 'Chirag Shetty', email: 'player.chirag@college.edu', reg: '22CS407', dept: 'Computer Science & Engineering', year: '3rd Year', pos: "Men's Doubles Specialist", jersey: 6 },
      { name: 'Kunlavut Vitidsarn', email: 'player.kunlavut@college.edu', reg: '23ECE408', dept: 'Electronics & Communication', year: '2nd Year', pos: 'Singles Defensive Specialist', jersey: 7 },
      { name: 'Lee Zii Jia', email: 'player.lee@college.edu', reg: '23ME409', dept: 'Mechanical Engineering', year: '2nd Year', pos: 'Power Smasher', jersey: 8 },
      { name: 'Chou Tien Chen', email: 'player.chou@college.edu', reg: '21CIV410', dept: 'Civil Engineering', year: '4th Year', pos: 'Veteran Singles Player', jersey: 9 },
      { name: 'Loh Kean Yew', email: 'player.loh@college.edu', reg: '23EEE411', dept: 'Electrical Engineering', year: '2nd Year', pos: 'Speed & Counter Attacker', jersey: 10 }
    ];
    for (const p of bPlayers) {
      const uId = await upsertUser({ email: p.email, role: 'PLAYER', name: p.name, register_number: p.reg, department: p.dept, academic_year: p.year, phone: '+19876543240' });
      await upsertPlayer(uId, bTeam, p.pos, p.jersey);
    }

    // Basketball (10 Players)
    const bkStaff = await upsertUser({ email: 'staff.basketball@college.edu', role: 'STAFF', name: 'Coach Phil Jackson', department: 'Physical Education', phone: '+19876543250' });
    const bkCapt = await upsertUser({ email: 'captain.basketball@college.edu', role: 'CAPTAIN', name: 'LeBron James', register_number: '21CS501', department: 'Computer Science & Engineering', academic_year: '4th Year', phone: '+19876543251' });
    const bkTeam = await upsertTeam('Titans Basketball Squad', 'Basketball', bkStaff, bkCapt);

    const bkPlayers = [
      { name: 'Stephen Curry', email: 'player.curry@college.edu', reg: '21ME502', dept: 'Mechanical Engineering', year: '4th Year', pos: 'Point Guard', jersey: 30 },
      { name: 'Kevin Durant', email: 'player.durant@college.edu', reg: '21ECE503', dept: 'Electronics & Communication', year: '4th Year', pos: 'Small Forward', jersey: 35 },
      { name: 'Giannis Antetokounmpo', email: 'player.giannis@college.edu', reg: '22CIV504', dept: 'Civil Engineering', year: '3rd Year', pos: 'Power Forward', jersey: 34 },
      { name: 'Nikola Jokic', email: 'player.jokic@college.edu', reg: '22EEE505', dept: 'Electrical Engineering', year: '3rd Year', pos: 'Center', jersey: 15 },
      { name: 'Luka Doncic', email: 'player.luka@college.edu', reg: '23CS506', dept: 'Computer Science & Engineering', year: '2nd Year', pos: 'Shooting Guard', jersey: 77 },
      { name: 'Jayson Tatum', email: 'player.tatum@college.edu', reg: '22ECE507', dept: 'Electronics & Communication', year: '3rd Year', pos: 'Small Forward', jersey: 0 },
      { name: 'Anthony Edwards', email: 'player.edwards@college.edu', reg: '24ME508', dept: 'Mechanical Engineering', year: '1st Year', pos: 'Shooting Guard', jersey: 5 },
      { name: 'Joel Embiid', email: 'player.embiid@college.edu', reg: '21CIV509', dept: 'Civil Engineering', year: '4th Year', pos: 'Center', jersey: 21 },
      { name: 'Shai Gilgeous-Alexander', email: 'player.shai@college.edu', reg: '23EEE510', dept: 'Electrical Engineering', year: '2nd Year', pos: 'Point Guard', jersey: 2 },
      { name: 'Anthony Davis', email: 'player.ad@college.edu', reg: '22CS511', dept: 'Computer Science & Engineering', year: '3rd Year', pos: 'Power Forward / Center', jersey: 3 }
    ];
    for (const p of bkPlayers) {
      const uId = await upsertUser({ email: p.email, role: 'PLAYER', name: p.name, register_number: p.reg, department: p.dept, academic_year: p.year, phone: '+19876543250' });
      await upsertPlayer(uId, bkTeam, p.pos, p.jersey);
    }
  } catch (err) {
    console.error('[DB Init] Error seeding teams:', err);
  }

  db.close();
  console.log('[DB Init - SQLite] Schema and seed initialized!');
}

if (require.main === module) {
  initDb();
}

module.exports = initDb;
