const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Email and password are required.' });
    }

    const [users] = await db.query(
      `SELECT u.*, 
              p.id as player_id, p.team_id as player_team_id, p.position, p.jersey_number,
              t_staff.id as staff_team_id, t_capt.id as captain_team_id
       FROM users u
       LEFT JOIN players p ON p.user_id = u.id
       LEFT JOIN teams t_staff ON t_staff.staff_id = u.id
       LEFT JOIN teams t_capt ON t_capt.captain_id = u.id
       WHERE u.email = ?`,
      [email.trim().toLowerCase()]
    );

    if (users.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    const user = users[0];

    if (!user.is_active) {
      return res.status(403).json({ success: false, message: 'Your account is deactivated. Please contact college sports staff.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password.' });
    }

    let teamId = null;
    let playerId = null;

    if (user.role === 'STAFF') teamId = user.staff_team_id;
    else if (user.role === 'CAPTAIN') teamId = user.captain_team_id;
    else if (user.role === 'PLAYER') {
      teamId = user.player_team_id;
      playerId = user.player_id;
    }

    // Fetch team name and sport name if teamId exists
    let teamName = null;
    let sportName = null;
    if (teamId) {
      const [teams] = await db.query(
        `SELECT t.name as team_name, s.name as sport_name 
         FROM teams t JOIN sports s ON t.sport_id = s.id 
         WHERE t.id = ?`,
        [teamId]
      );
      if (teams.length > 0) {
        teamName = teams[0].team_name;
        sportName = teams[0].sport_name;
      }
    }

    const payload = { id: user.id, role: user.role, email: user.email };
    const secret = process.env.JWT_SECRET || 'sportsync_jwt_secret_key_2026';
    const token = jwt.sign(payload, secret, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });

    return res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        name: user.name,
        registerNumber: user.register_number,
        department: user.department,
        academicYear: user.academic_year,
        phone: user.phone,
        teamId,
        teamName,
        sportName,
        playerId,
        position: user.position,
        jerseyNumber: user.jersey_number
      }
    });
  } catch (err) {
    next(err);
  }
}

async function getMe(req, res, next) {
  try {
    const userId = req.user.id;
    const [users] = await db.query(
      `SELECT u.id, u.email, u.role, u.name, u.register_number, u.department, u.academic_year, u.phone, u.is_active,
              p.id as player_id, p.team_id as player_team_id, p.position, p.jersey_number,
              t_staff.id as staff_team_id, t_capt.id as captain_team_id
       FROM users u
       LEFT JOIN players p ON p.user_id = u.id
       LEFT JOIN teams t_staff ON t_staff.staff_id = u.id
       LEFT JOIN teams t_capt ON t_capt.captain_id = u.id
       WHERE u.id = ?`,
      [userId]
    );

    if (users.length === 0) {
      return res.status(44).json({ success: false, message: 'User not found.' });
    }

    const user = users[0];
    let teamId = null;
    let playerId = null;

    if (user.role === 'STAFF') teamId = user.staff_team_id;
    else if (user.role === 'CAPTAIN') teamId = user.captain_team_id;
    else if (user.role === 'PLAYER') {
      teamId = user.player_team_id;
      playerId = user.player_id;
    }

    let teamName = null;
    let sportName = null;
    if (teamId) {
      const [teams] = await db.query(
        `SELECT t.name as team_name, s.name as sport_name 
         FROM teams t JOIN sports s ON t.sport_id = s.id 
         WHERE t.id = ?`,
        [teamId]
      );
      if (teams.length > 0) {
        teamName = teams[0].team_name;
        sportName = teams[0].sport_name;
      }
    }

    return res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        name: user.name,
        registerNumber: user.register_number,
        department: user.department,
        academicYear: user.academic_year,
        phone: user.phone,
        teamId,
        teamName,
        sportName,
        playerId,
        position: user.position,
        jerseyNumber: user.jersey_number
      }
    });
  } catch (err) {
    next(err);
  }
}

async function forgotPassword(req, res, next) {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ success: false, message: 'Email address is required.' });
    }

    const [users] = await db.query('SELECT id FROM users WHERE email = ?', [email.trim().toLowerCase()]);
    if (users.length === 0) {
      return res.json({
        success: true,
        message: 'If the email is registered in SportSync, a password reset link has been dispatched.'
      });
    }

    return res.json({
      success: true,
      message: 'Password reset code generated successfully. Check your college email inbox.',
      resetToken: 'RESET_DEMO_CODE_123456'
    });
  } catch (err) {
    next(err);
  }
}

async function resetPassword(req, res, next) {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email and new password are required.' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long.' });
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    const [result] = await db.query('UPDATE users SET password = ? WHERE email = ?', [passwordHash, email.trim().toLowerCase()]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'User not found.' });
    }

    return res.json({ success: true, message: 'Password reset successfully. You can now login with your new password.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  login,
  getMe,
  forgotPassword,
  resetPassword
};
