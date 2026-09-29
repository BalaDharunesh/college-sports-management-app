const jwt = require('jsonwebtoken');
const db = require('../config/db');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, message: 'Authentication required. No token provided.' });
    }

    const token = authHeader.split(' ')[1];
    const secret = process.env.JWT_SECRET || 'sportsync_jwt_secret_key_2026';
    const decoded = jwt.verify(token, secret);

    // Fetch user from DB to ensure account is active and obtain latest role/team details
    const [rows] = await db.query('SELECT id, email, role, name, is_active FROM users WHERE id = ?', [decoded.id]);
    if (!rows || rows.length === 0) {
      return res.status(401).json({ success: false, message: 'User session invalid or user not found.' });
    }

    const user = rows[0];
    if (!user.is_active) {
      return res.status(403).json({ success: false, message: 'Your account has been deactivated. Please contact staff.' });
    }

    // Attach user team assignment details if staff or captain or player
    let teamId = null;
    let playerId = null;
    if (user.role === 'STAFF') {
      const [tRows] = await db.query('SELECT id FROM teams WHERE staff_id = ?', [user.id]);
      if (tRows.length > 0) teamId = tRows[0].id;
    } else if (user.role === 'CAPTAIN') {
      const [tRows] = await db.query('SELECT id FROM teams WHERE captain_id = ?', [user.id]);
      if (tRows.length > 0) teamId = tRows[0].id;
    } else if (user.role === 'PLAYER') {
      const [pRows] = await db.query('SELECT id, team_id FROM players WHERE user_id = ?', [user.id]);
      if (pRows.length > 0) {
        playerId = pRows[0].id;
        teamId = pRows[0].team_id;
      }
    }

    req.user = {
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      teamId: teamId,
      playerId: playerId
    };

    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, message: 'Token expired. Please log in again.' });
    }
    return res.status(401).json({ success: false, message: 'Invalid token authentication.' });
  }
}

function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden. Role '${req.user ? req.user.role : 'UNKNOWN'}' is not authorized for this resource.`
      });
    }
    next();
  };
}

module.exports = {
  authenticate,
  authorize
};
