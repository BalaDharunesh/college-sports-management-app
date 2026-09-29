const db = require('../config/db');

async function getNotifications(req, res, next) {
  try {
    const userId = req.user.id;
    const [notifications] = await db.query(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    const [unread] = await db.query(
      'SELECT COUNT(*) as unread_count FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId]
    );

    return res.json({
      success: true,
      unreadCount: unread[0].unread_count,
      notifications
    });
  } catch (err) {
    next(err);
  }
}

async function markAsRead(req, res, next) {
  try {
    const notificationId = req.params.id;
    const userId = req.user.id;

    await db.query('UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?', [notificationId, userId]);
    return res.json({ success: true, message: 'Notification marked as read.' });
  } catch (err) {
    next(err);
  }
}

async function markAllAsRead(req, res, next) {
  try {
    const userId = req.user.id;
    await db.query('UPDATE notifications SET is_read = 1 WHERE user_id = ?', [userId]);
    return res.json({ success: true, message: 'All notifications marked as read.' });
  } catch (err) {
    next(err);
  }
}

async function registerDeviceToken(req, res, next) {
  try {
    const userId = req.user.id;
    const { token, platform } = req.body;

    if (!token) {
      return res.status(400).json({ success: false, message: 'Device token is required.' });
    }

    // Upsert token
    const [exist] = await db.query('SELECT id FROM device_tokens WHERE token = ?', [token]);
    if (exist.length > 0) {
      await db.query('UPDATE device_tokens SET user_id = ?, platform = ? WHERE token = ?', [userId, platform || 'android', token]);
    } else {
      await db.query('INSERT INTO device_tokens (user_id, token, platform) VALUES (?, ?, ?)', [userId, token, platform || 'android']);
    }

    return res.json({ success: true, message: 'Device token registered successfully.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  registerDeviceToken
};
