const db = require('../config/db');
const { notifyTeam } = require('../services/notificationService');

async function getTrainingSchedules(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId && user.role !== 'STAFF') {
      return res.status(400).json({ success: false, message: 'No team assigned.' });
    }

    let sql = `
      SELECT ts.*, t.name as team_name
      FROM training_schedules ts
      JOIN teams t ON ts.team_id = t.id
    `;
    const params = [];

    if (teamId) {
      sql += ' WHERE ts.team_id = ?';
      params.push(teamId);
    }

    sql += ' ORDER BY ts.training_date ASC, ts.start_time ASC';

    const [schedules] = await db.query(sql, params);
    return res.json({ success: true, count: schedules.length, schedules });
  } catch (err) {
    next(err);
  }
}

async function createTrainingSchedule(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId || user.role !== 'STAFF') {
      return res.status(403).json({ success: false, message: 'Only team staff members can schedule training sessions.' });
    }

    const { title, trainingDate, startTime, endTime, venue, description } = req.body;

    if (!title || !trainingDate || !startTime || !endTime || !venue) {
      return res.status(400).json({ success: false, message: 'Title, Training Date, Start Time, End Time, and Venue are required.' });
    }

    const [result] = await db.query(
      `INSERT INTO training_schedules (title, team_id, training_date, start_time, end_time, venue, description, is_cancelled)
       VALUES (?, ?, ?, ?, ?, ?, ?, 0)`,
      [title.trim(), teamId, trainingDate, startTime, endTime, venue.trim(), description ? description.trim() : null]
    );

    const trainingId = result.insertId;

    // Notify team members
    await notifyTeam({
      teamId,
      title: 'New Training Schedule Announced',
      message: `Training session "${title}" scheduled for ${trainingDate} at ${startTime} - ${endTime} (${venue}).`,
      type: 'TRAINING_SCHEDULE',
      referenceId: trainingId,
      excludeUserId: user.id
    });

    return res.status(201).json({
      success: true,
      message: 'Training schedule created and team notified.',
      trainingId
    });
  } catch (err) {
    next(err);
  }
}

async function updateTrainingSchedule(req, res, next) {
  try {
    const trainingId = req.params.id;
    const user = req.user;

    const [rows] = await db.query('SELECT * FROM training_schedules WHERE id = ?', [trainingId]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Training schedule not found.' });
    }

    const ts = rows[0];
    if (user.role !== 'STAFF' && user.teamId != ts.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to edit training for another team.' });
    }

    const { title, trainingDate, startTime, endTime, venue, description } = req.body;

    await db.query(
      `UPDATE training_schedules SET
              title = COALESCE(?, title),
              training_date = COALESCE(?, training_date),
              start_time = COALESCE(?, start_time),
              end_time = COALESCE(?, end_time),
              venue = COALESCE(?, venue),
              description = COALESCE(?, description)
       WHERE id = ?`,
      [
        title ? title.trim() : null,
        trainingDate || null,
        startTime || null,
        endTime || null,
        venue ? venue.trim() : null,
        description ? description.trim() : null,
        trainingId
      ]
    );

    // Notify team members of update
    await notifyTeam({
      teamId: ts.team_id,
      title: 'Training Schedule Updated',
      message: `Schedule details for training session "${title || ts.title}" have been updated by staff.`,
      type: 'TRAINING_UPDATED',
      referenceId: trainingId,
      excludeUserId: user.id
    });

    return res.json({ success: true, message: 'Training schedule updated successfully.' });
  } catch (err) {
    next(err);
  }
}

async function cancelTrainingSchedule(req, res, next) {
  try {
    const trainingId = req.params.id;
    const user = req.user;

    const [rows] = await db.query('SELECT * FROM training_schedules WHERE id = ?', [trainingId]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Training schedule not found.' });
    }

    const ts = rows[0];
    if (user.role !== 'STAFF' && user.teamId != ts.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized.' });
    }

    await db.query('UPDATE training_schedules SET is_cancelled = 1 WHERE id = ?', [trainingId]);

    await notifyTeam({
      teamId: ts.team_id,
      title: 'Training Session Cancelled',
      message: `Training session "${ts.title}" scheduled for ${ts.training_date} has been cancelled.`,
      type: 'TRAINING_CANCELLED',
      referenceId: trainingId,
      excludeUserId: user.id
    });

    return res.json({ success: true, message: 'Training schedule cancelled.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getTrainingSchedules,
  createTrainingSchedule,
  updateTrainingSchedule,
  cancelTrainingSchedule
};
