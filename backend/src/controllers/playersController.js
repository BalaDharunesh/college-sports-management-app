const bcrypt = require('bcryptjs');
const db = require('../config/db');

async function getPlayers(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId) {
      return res.status(400).json({ success: false, message: 'User is not assigned to any team.' });
    }

    const { search, active } = req.query;

    let sql = `
      SELECT p.id as player_id, p.team_id, p.position, p.jersey_number, p.is_active as player_active,
             u.id as user_id, u.name, u.email, u.register_number, u.department, u.academic_year, u.phone, u.role
      FROM players p
      JOIN users u ON p.user_id = u.id
      WHERE p.team_id = ?
    `;

    const params = [teamId];

    if (active !== undefined && active !== '') {
      sql += ' AND p.is_active = ?';
      params.push(active === 'true' || active === '1' ? 1 : 0);
    }

    if (search && search.trim() !== '') {
      sql += ' AND (u.name LIKE ? OR u.register_number LIKE ? OR u.department LIKE ?)';
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    sql += ' ORDER BY u.name ASC';

    const [players] = await db.query(sql, params);
    return res.json({ success: true, count: players.length, players });
  } catch (err) {
    next(err);
  }
}

async function getPlayerById(req, res, next) {
  try {
    const playerId = req.params.id;
    const user = req.user;

    const [rows] = await db.query(
      `SELECT p.id as player_id, p.team_id, p.position, p.jersey_number, p.is_active as player_active,
              u.id as user_id, u.name, u.email, u.register_number, u.department, u.academic_year, u.phone,
              t.name as team_name, s.name as sport_name
       FROM players p
       JOIN users u ON p.user_id = u.id
       JOIN teams t ON p.team_id = t.id
       JOIN sports s ON t.sport_id = s.id
       WHERE p.id = ?`,
      [playerId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Player record not found.' });
    }

    const player = rows[0];

    // Enforce team ownership permission check
    if (user.role !== 'STAFF' && user.teamId != player.team_id && user.playerId != player.player_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to view details of a player from another team.' });
    }

    return res.json({ success: true, player });
  } catch (err) {
    next(err);
  }
}

async function createPlayer(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId) {
      return res.status(400).json({ success: false, message: 'Cannot create player: no team assigned to your account.' });
    }

    const { name, registerNumber, email, phone, department, academicYear, position, jerseyNumber, password } = req.body;

    if (!name || !registerNumber || !email || !department || !academicYear) {
      return res.status(400).json({ success: false, message: 'Name, Register Number, Email, Department, and Academic Year are required.' });
    }

    // Check duplicate email or register number
    const [existing] = await db.query(
      'SELECT id, email, register_number FROM users WHERE email = ? OR register_number = ?',
      [email.trim().toLowerCase(), registerNumber.trim()]
    );

    if (existing.length > 0) {
      const dupe = existing[0];
      if (dupe.email === email.trim().toLowerCase()) {
        return res.status(400).json({ success: false, message: 'A user with this email address already exists.' });
      }
      if (dupe.register_number === registerNumber.trim()) {
        return res.status(400).json({ success: false, message: 'A player with this register number already exists.' });
      }
    }

    const initialPassword = password || 'Password123!';
    const passwordHash = await bcrypt.hash(initialPassword, 10);

    // 1. Insert into users table
    const [userResult] = await db.query(
      `INSERT INTO users (email, password, role, name, register_number, department, academic_year, phone, is_active)
       VALUES (?, ?, 'PLAYER', ?, ?, ?, ?, ?, 1)`,
      [email.trim().toLowerCase(), passwordHash, name.trim(), registerNumber.trim(), department.trim(), academicYear.trim(), phone ? phone.trim() : null]
    );

    const newUserId = userResult.insertId;

    // 2. Insert into players table
    const [playerResult] = await db.query(
      `INSERT INTO players (user_id, team_id, position, jersey_number, is_active)
       VALUES (?, ?, ?, ?, 1)`,
      [newUserId, teamId, position ? position.trim() : null, jerseyNumber ? parseInt(jerseyNumber) : null]
    );

    return res.status(201).json({
      success: true,
      message: `Player account created successfully for ${name}. Initial password: ${initialPassword}`,
      playerId: playerResult.insertId,
      userId: newUserId
    });
  } catch (err) {
    next(err);
  }
}

async function updatePlayer(req, res, next) {
  try {
    const playerId = req.params.id;
    const user = req.user;

    const [players] = await db.query('SELECT p.*, u.id as user_id FROM players p JOIN users u ON p.user_id = u.id WHERE p.id = ?', [playerId]);
    if (players.length === 0) {
      return res.status(404).json({ success: false, message: 'Player not found.' });
    }

    const player = players[0];

    // Enforce team ownership
    if (user.role !== 'STAFF' && user.teamId != player.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to edit players belonging to another team.' });
    }

    const { name, phone, department, academicYear, position, jerseyNumber } = req.body;

    // Update users table
    if (name || phone || department || academicYear) {
      await db.query(
        `UPDATE users SET 
                name = COALESCE(?, name),
                phone = COALESCE(?, phone),
                department = COALESCE(?, department),
                academic_year = COALESCE(?, academic_year)
         WHERE id = ?`,
        [name ? name.trim() : null, phone ? phone.trim() : null, department ? department.trim() : null, academicYear ? academicYear.trim() : null, player.user_id]
      );
    }

    // Update players table
    if (position !== undefined || jerseyNumber !== undefined) {
      await db.query(
        `UPDATE players SET 
                position = COALESCE(?, position),
                jersey_number = COALESCE(?, jersey_number)
         WHERE id = ?`,
        [position ? position.trim() : null, jerseyNumber ? parseInt(jerseyNumber) : null, playerId]
      );
    }

    return res.json({ success: true, message: 'Player details updated successfully.' });
  } catch (err) {
    next(err);
  }
}

async function deactivatePlayer(req, res, next) {
  try {
    const playerId = req.params.id;
    const user = req.user;

    const [players] = await db.query('SELECT p.*, u.id as user_id FROM players p JOIN users u ON p.user_id = u.id WHERE p.id = ?', [playerId]);
    if (players.length === 0) {
      return res.status(404).json({ success: false, message: 'Player not found.' });
    }

    const player = players[0];
    if (user.role !== 'STAFF' && user.teamId != player.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to deactivate players from another team.' });
    }

    // Toggle or soft deactivate
    const newActive = player.is_active ? 0 : 1;
    await db.query('UPDATE players SET is_active = ? WHERE id = ?', [newActive, playerId]);
    await db.query('UPDATE users SET is_active = ? WHERE id = ?', [newActive, player.user_id]);

    return res.json({
      success: true,
      message: `Player has been ${newActive === 1 ? 'reactivated' : 'deactivated'} successfully.`
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getPlayers,
  getPlayerById,
  createPlayer,
  updatePlayer,
  deactivatePlayer
};
