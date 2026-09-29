const db = require('../config/db');
let admin = null;

try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin = require('firebase-admin');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('[NotificationService] Firebase Admin SDK initialized successfully.');
  } else {
    console.log('[NotificationService] Firebase service account not provided. Running in DB in-app notification mode.');
  }
} catch (e) {
  console.warn('[NotificationService] Firebase Admin initialization failed:', e.message);
}

/**
  Creates an in-app notification and dispatches FCM push notification if available.
 */
async function sendNotification({ userId, title, message, type = 'GENERAL', referenceId = null }) {
  try {
    // 1. Save to Database
    const [res] = await db.query(
      `INSERT INTO notifications (user_id, title, message, type, reference_id, is_read) VALUES (?, ?, ?, ?, ?, 0)`,
      [userId, title, message, type, referenceId]
    );

    // 2. Dispatch FCM Push Notification if enabled
    if (admin) {
      const [tokenRows] = await db.query(`SELECT token FROM device_tokens WHERE user_id = ?`, [userId]);
      if (tokenRows.length > 0) {
        const tokens = tokenRows.map(r => r.token);
        const payload = {
          notification: { title, body: message },
          data: {
            type: String(type),
            referenceId: referenceId ? String(referenceId) : ''
          }
        };
        await admin.messaging().sendMulticast({ tokens, ...payload });
      }
    }

    return res.insertId;
  } catch (err) {
    console.error('[NotificationService Error]', err.message);
  }
}

/**
  Notifies all players and captain of a team.
 */
async function notifyTeam({ teamId, title, message, type, referenceId, excludeUserId = null }) {
  try {
    // Get team captain & staff
    const [teamRows] = await db.query('SELECT staff_id, captain_id FROM teams WHERE id = ?', [teamId]);
    if (teamRows.length === 0) return;

    const staffId = teamRows[0].staff_id;
    const captainId = teamRows[0].captain_id;

    // Get team players' user_ids
    const [players] = await db.query('SELECT user_id FROM players WHERE team_id = ? AND is_active = 1', [teamId]);

    const targetUserIds = new Set();
    if (staffId) targetUserIds.add(staffId);
    if (captainId) targetUserIds.add(captainId);
    players.forEach(p => targetUserIds.add(p.user_id));

    if (excludeUserId) {
      targetUserIds.delete(excludeUserId);
    }

    for (const uId of targetUserIds) {
      await sendNotification({ userId: uId, title, message, type, referenceId });
    }
  } catch (err) {
    console.error('[NotificationService notifyTeam Error]', err.message);
  }
}

module.exports = {
  sendNotification,
  notifyTeam
};
