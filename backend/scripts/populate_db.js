const sqlite3 = require('sqlite3').verbose();
const bcrypt = require('bcryptjs');
const path = require('path');
const fs = require('fs');

async function populateDatabase() {
  console.log('--- Populating Database with Teams, Staff, Captains, and Players ---');
  
  const dbDir = path.join(__dirname, '../data');
  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }
  const dbPath = path.join(dbDir, 'sports_management.sqlite');
  const db = new sqlite3.Database(dbPath);

  const runSql = (sql, params = []) => new Promise((res, rej) => db.run(sql, params, function(err) { if (err) rej(err); else res(this); }));
  const getSql = (sql, params = []) => new Promise((res, rej) => db.get(sql, params, (err, row) => err ? rej(err) : res(row)));

  const passwordHash = await bcrypt.hash('Password123!', 10);

  // Helper to upsert user
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

  // Helper to upsert team
  async function upsertTeam(name, sportName, staffId, captainId) {
    let sport = await getSql('SELECT id FROM sports WHERE name = ?', [sportName]);
    if (!sport) {
      let sRes = await runSql('INSERT INTO sports (name, description) VALUES (?, ?)', [sportName, `${sportName} College Squad & Tournaments`]);
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

  // Helper to upsert player
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

  // Ensure initial sports exist
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
    let existing = await getSql('SELECT id FROM sports WHERE name = ?', [n]);
    if (!existing) {
      await runSql('INSERT INTO sports (name, description) VALUES (?, ?)', [n, d]);
    }
  }

  // -------------------------------------------------------------
  // 1. CRICKET TEAM (15 Players, 1 Staff, 1 Captain)
  // -------------------------------------------------------------
  console.log('Seeding Cricket Team...');
  const cricketStaffId = await upsertUser({
    email: 'staff.cricket@college.edu',
    role: 'STAFF',
    name: 'Prof. Robert Vance',
    department: 'Physical Education',
    phone: '+19876543210'
  });

  const cricketCaptainId = await upsertUser({
    email: 'captain.cricket@college.edu',
    role: 'CAPTAIN',
    name: 'Rahul Sharma',
    register_number: '21CS001',
    department: 'Computer Science & Engineering',
    academic_year: '4th Year',
    phone: '+19876543211'
  });

  const cricketTeamId = await upsertTeam('Strikers Cricket XI', 'Cricket', cricketStaffId, cricketCaptainId);

  const cricketPlayersData = [
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

  for (const p of cricketPlayersData) {
    const userId = await upsertUser({
      email: p.email,
      role: 'PLAYER',
      name: p.name,
      register_number: p.reg,
      department: p.dept,
      academic_year: p.year,
      phone: '+1987654' + Math.floor(1000 + Math.random() * 9000)
    });
    await upsertPlayer(userId, cricketTeamId, p.pos, p.jersey);
  }

  // -------------------------------------------------------------
  // 2. FOOTBALL TEAM (15 Players, 1 Staff, 1 Captain)
  // -------------------------------------------------------------
  console.log('Seeding Football Team...');
  const footballStaffId = await upsertUser({
    email: 'staff.football@college.edu',
    role: 'STAFF',
    name: 'Dr. Sarah Jenkins',
    department: 'Sports Science',
    phone: '+19876543215'
  });

  const footballCaptainId = await upsertUser({
    email: 'captain.football@college.edu',
    role: 'CAPTAIN',
    name: 'Alex Morgan',
    register_number: '21ECE002',
    department: 'Electronics & Communication',
    academic_year: '4th Year',
    phone: '+19876543216'
  });

  const footballTeamId = await upsertTeam('Panthers Football FC', 'Football', footballStaffId, footballCaptainId);

  const footballPlayersData = [
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

  for (const p of footballPlayersData) {
    const userId = await upsertUser({
      email: p.email,
      role: 'PLAYER',
      name: p.name,
      register_number: p.reg,
      department: p.dept,
      academic_year: p.year,
      phone: '+1987654' + Math.floor(1000 + Math.random() * 9000)
    });
    await upsertPlayer(userId, footballTeamId, p.pos, p.jersey);
  }

  // -------------------------------------------------------------
  // 3. TENNIS TEAM (10 Players, 1 Staff, 1 Captain)
  // -------------------------------------------------------------
  console.log('Seeding Tennis Team...');
  const tennisStaffId = await upsertUser({
    email: 'staff.tennis@college.edu',
    role: 'STAFF',
    name: 'Prof. David Miller',
    department: 'Physical Education',
    phone: '+19876543230'
  });

  const tennisCaptainId = await upsertUser({
    email: 'captain.tennis@college.edu',
    role: 'CAPTAIN',
    name: 'Carlos Alcaraz',
    register_number: '21CS301',
    department: 'Computer Science & Engineering',
    academic_year: '4th Year',
    phone: '+19876543231'
  });

  const tennisTeamId = await upsertTeam('Aces Tennis Squad', 'Tennis', tennisStaffId, tennisCaptainId);

  const tennisPlayersData = [
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

  for (const p of tennisPlayersData) {
    const userId = await upsertUser({
      email: p.email,
      role: 'PLAYER',
      name: p.name,
      register_number: p.reg,
      department: p.dept,
      academic_year: p.year,
      phone: '+1987654' + Math.floor(1000 + Math.random() * 9000)
    });
    await upsertPlayer(userId, tennisTeamId, p.pos, p.jersey);
  }

  // -------------------------------------------------------------
  // 4. BADMINTON TEAM (10 Players, 1 Staff, 1 Captain)
  // -------------------------------------------------------------
  console.log('Seeding Badminton Team...');
  const badmintonStaffId = await upsertUser({
    email: 'staff.badminton@college.edu',
    role: 'STAFF',
    name: 'Prof. Emma Watson',
    department: 'Physical Education',
    phone: '+19876543240'
  });

  const badmintonCaptainId = await upsertUser({
    email: 'captain.badminton@college.edu',
    role: 'CAPTAIN',
    name: 'Lakshya Sen',
    register_number: '21ECE401',
    department: 'Electronics & Communication',
    academic_year: '4th Year',
    phone: '+19876543241'
  });

  const badmintonTeamId = await upsertTeam('Smashers Badminton XI', 'Badminton', badmintonStaffId, badmintonCaptainId);

  const badmintonPlayersData = [
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

  for (const p of badmintonPlayersData) {
    const userId = await upsertUser({
      email: p.email,
      role: 'PLAYER',
      name: p.name,
      register_number: p.reg,
      department: p.dept,
      academic_year: p.year,
      phone: '+1987654' + Math.floor(1000 + Math.random() * 9000)
    });
    await upsertPlayer(userId, badmintonTeamId, p.pos, p.jersey);
  }

  // -------------------------------------------------------------
  // 5. BASKETBALL TEAM (10 Players, 1 Staff, 1 Captain)
  // -------------------------------------------------------------
  console.log('Seeding Basketball Team...');
  const basketballStaffId = await upsertUser({
    email: 'staff.basketball@college.edu',
    role: 'STAFF',
    name: 'Coach Phil Jackson',
    department: 'Physical Education',
    phone: '+19876543250'
  });

  const basketballCaptainId = await upsertUser({
    email: 'captain.basketball@college.edu',
    role: 'CAPTAIN',
    name: 'LeBron James',
    register_number: '21CS501',
    department: 'Computer Science & Engineering',
    academic_year: '4th Year',
    phone: '+19876543251'
  });

  const basketballTeamId = await upsertTeam('Titans Basketball Squad', 'Basketball', basketballStaffId, basketballCaptainId);

  const basketballPlayersData = [
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

  for (const p of basketballPlayersData) {
    const userId = await upsertUser({
      email: p.email,
      role: 'PLAYER',
      name: p.name,
      register_number: p.reg,
      department: p.dept,
      academic_year: p.year,
      phone: '+1987654' + Math.floor(1000 + Math.random() * 9000)
    });
    await upsertPlayer(userId, basketballTeamId, p.pos, p.jersey);
  }

  db.close();
  console.log(' Successfully populated all 5 teams, staff, captains, and players!');
}

populateDatabase().catch(err => {
  console.error('Error populating database:', err);
  process.exit(1);
});
