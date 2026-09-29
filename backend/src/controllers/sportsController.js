const db = require('../config/db');

async function getSports(req, res, next) {
  try {
    const [sports] = await db.query('SELECT * FROM sports ORDER BY name ASC');
    return res.json({ success: true, sports });
  } catch (err) {
    next(err);
  }
}

async function getMyTeam(req, res, next) {
  try {
    const user = req.user;
    let teamId = user.teamId;

    if (!teamId) {
      return res.status(404).json({ success: false, message: 'No assigned team found for your user account.' });
    }

    const [teams] = await db.query(
      `SELECT t.*, s.name as sport_name,
              u_staff.name as staff_name, u_staff.email as staff_email, u_staff.phone as staff_phone,
              u_capt.name as captain_name, u_capt.email as captain_email, u_capt.phone as captain_phone, u_capt.register_number as captain_reg
       FROM teams t
       JOIN sports s ON t.sport_id = s.id
       LEFT JOIN users u_staff ON t.staff_id = u_staff.id
       LEFT JOIN users u_capt ON t.captain_id = u_capt.id
       WHERE t.id = ?`,
      [teamId]
    );

    if (teams.length === 0) {
      return res.status(404).json({ success: false, message: 'Team details not found.' });
    }

    const team = teams[0];

    // Get count of active players
    const [pCount] = await db.query('SELECT COUNT(*) as active_count FROM players WHERE team_id = ? AND is_active = 1', [teamId]);
    team.active_players_count = pCount[0].active_count;

    return res.json({ success: true, team });
  } catch (err) {
    next(err);
  }
}

async function getTeamById(req, res, next) {
  try {
    const teamId = req.params.id;

    // Enforce role authorization access check
    if (req.user.role !== 'STAFF' && req.user.teamId != teamId) {
      return res.status(403).json({ success: false, message: 'Unauthorized to view another team management data.' });
    }

    const [teams] = await db.query(
      `SELECT t.*, s.name as sport_name,
              u_staff.name as staff_name, u_staff.email as staff_email,
              u_capt.name as captain_name, u_capt.email as captain_email
       FROM teams t
       JOIN sports s ON t.sport_id = s.id
       LEFT JOIN users u_staff ON t.staff_id = u_staff.id
       LEFT JOIN users u_capt ON t.captain_id = u_capt.id
       WHERE t.id = ?`,
      [teamId]
    );

    if (teams.length === 0) {
      return res.status(404).json({ success: false, message: 'Team not found.' });
    }

    return res.json({ success: true, team: teams[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getSports,
  getMyTeam,
  getTeamById
};
