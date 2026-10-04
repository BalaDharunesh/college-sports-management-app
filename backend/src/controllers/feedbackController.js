const db = require('../config/db');
const { sendNotification } = require('../services/notificationService');

async function submitFeedback(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId || user.role !== 'CAPTAIN') {
      return res.status(403).json({ success: false, message: 'Only team captains can submit match feedback.' });
    }

    const { matchId, category, feedbackText, suggestions } = req.body;

    if (!matchId || !category || !feedbackText) {
      return res.status(400).json({ success: false, message: 'Match ID, category, and feedback text are required.' });
    }

    const [matches] = await db.query('SELECT m.*, t.staff_id FROM matches m JOIN teams t ON m.team_id = t.id WHERE m.id = ? AND m.team_id = ?', [matchId, teamId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found for your team.' });
    }

    const match = matches[0];

    const [result] = await db.query(
      `INSERT INTO match_feedback (match_id, team_id, captain_id, category, feedback_text, suggestions)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [matchId, teamId, user.id, category.trim(), feedbackText.trim(), suggestions ? suggestions.trim() : null]
    );

    const feedbackId = result.insertId;

    // Notify Staff
    if (match.staff_id) {
      await sendNotification({
        userId: match.staff_id,
        title: 'New Captain Match Feedback',
        message: `Captain ${user.name} submitted feedback for "${match.title}" (Category: ${category}).`,
        type: 'FEEDBACK_SUBMITTED',
        referenceId: feedbackId
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Match feedback submitted successfully to staff.',
      feedbackId
    });
  } catch (err) {
    next(err);
  }
}

async function getFeedbackList(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId && user.role !== 'STAFF') {
      return res.status(400).json({ success: false, message: 'No team assigned.' });
    }

    let sql = `
      SELECT fb.*, m.title as match_title, m.match_date, t.name as team_name, u_capt.name as captain_name
      FROM match_feedback fb
      JOIN matches m ON fb.match_id = m.id
      JOIN teams t ON fb.team_id = t.id
      JOIN users u_capt ON fb.captain_id = u_capt.id
    `;
    const params = [];

    if (teamId) {
      sql += ' WHERE fb.team_id = ?';
      params.push(teamId);
    }

    sql += ' ORDER BY fb.created_at DESC';

    const [feedbackList] = await db.query(sql, params);
    return res.json({ success: true, count: feedbackList.length, feedbackList });
  } catch (err) {
    next(err);
  }
}

async function respondToFeedback(req, res, next) {
  try {
    const feedbackId = req.params.id;
    const staffId = req.user.id;
    const { response } = req.body;

    if (!response || response.trim() === '') {
      return res.status(400).json({ success: false, message: 'Response text is required.' });
    }

    const [rows] = await db.query('SELECT fb.*, m.title as match_title FROM match_feedback fb JOIN matches m ON fb.match_id = m.id WHERE fb.id = ?', [feedbackId]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Feedback entry not found.' });
    }

    const fb = rows[0];
    if (req.user.role === 'STAFF' && req.user.teamId && req.user.teamId != fb.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to respond to feedback for another team.' });
    }

    await db.query(
      `UPDATE match_feedback SET staff_response = ?, responded_at = NOW() WHERE id = ?`,
      [response.trim(), feedbackId]
    );

    // Notify Captain
    await sendNotification({
      userId: fb.captain_id,
      title: 'Staff Responded to Match Feedback',
      message: `Sports staff responded to your feedback for match "${fb.match_title}".`,
      type: 'FEEDBACK_RESPONSE',
      referenceId: feedbackId
    });

    return res.json({ success: true, message: 'Response submitted successfully.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  submitFeedback,
  getFeedbackList,
  respondToFeedback
};
