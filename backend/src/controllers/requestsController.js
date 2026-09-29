const db = require('../config/db');
const { sendNotification } = require('../services/notificationService');

// ================= OD REQUESTS =================

async function createOdRequest(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId || user.role !== 'CAPTAIN') {
      return res.status(403).json({ success: false, message: 'Only team captains can submit On-Duty (OD) requests.' });
    }

    const { matchId, reason, requestDate, remarks, playerIds } = req.body;

    if (!matchId || !reason || !requestDate || !Array.isArray(playerIds) || playerIds.length === 0) {
      return res.status(400).json({ success: false, message: 'Match ID, reason, request date, and playerIds array are required.' });
    }

    // Verify match belongs to captain's team
    const [matches] = await db.query('SELECT m.*, t.staff_id FROM matches m JOIN teams t ON m.team_id = t.id WHERE m.id = ? AND m.team_id = ?', [matchId, teamId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found for your assigned team.' });
    }

    const match = matches[0];

    // Validate players belong to team
    const [validPlayers] = await db.query(
      'SELECT id FROM players WHERE team_id = ? AND id IN (?)',
      [teamId, playerIds]
    );

    if (validPlayers.length !== new Set(playerIds).size) {
      return res.status(400).json({ success: false, message: 'Invalid player selection in OD request.' });
    }

    // Insert OD request
    const [result] = await db.query(
      `INSERT INTO od_requests (match_id, team_id, captain_id, reason, request_date, remarks, status)
       VALUES (?, ?, ?, ?, ?, ?, 'PENDING')`,
      [matchId, teamId, user.id, reason.trim(), requestDate, remarks ? remarks.trim() : null]
    );

    const odRequestId = result.insertId;

    // Insert player relationships into explicit junction table
    for (const pId of playerIds) {
      await db.query('INSERT INTO od_request_players (od_request_id, player_id) VALUES (?, ?)', [odRequestId, pId]);
    }

    // Notify Staff
    if (match.staff_id) {
      await sendNotification({
        userId: match.staff_id,
        title: 'New OD Approval Request',
        message: `Captain ${user.name} submitted an On-Duty request covering ${playerIds.length} players for "${match.title}".`,
        type: 'OD_SUBMITTED',
        referenceId: odRequestId
      });
    }

    return res.status(201).json({
      success: true,
      message: 'OD request submitted successfully for staff approval.',
      odRequestId
    });
  } catch (err) {
    next(err);
  }
}

async function getOdRequests(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId && user.role !== 'STAFF') {
      return res.status(400).json({ success: false, message: 'No team assigned.' });
    }

    let sql = `
      SELECT od.*, m.title as match_title, m.match_date, t.name as team_name, u_capt.name as captain_name
      FROM od_requests od
      JOIN matches m ON od.match_id = m.id
      JOIN teams t ON od.team_id = t.id
      JOIN users u_capt ON od.captain_id = u_capt.id
    `;
    const params = [];

    if (teamId) {
      sql += ' WHERE od.team_id = ?';
      params.push(teamId);
    }

    sql += ' ORDER BY od.created_at DESC';

    const [odRequests] = await db.query(sql, params);

    // Attach covered players list
    for (const reqObj of odRequests) {
      const [players] = await db.query(
        `SELECT p.id as player_id, p.jersey_number, p.position,
                u.name as player_name, u.register_number, u.department
         FROM od_request_players odp
         JOIN players p ON odp.player_id = p.id
         JOIN users u ON p.user_id = u.id
         WHERE odp.od_request_id = ?`,
        [reqObj.id]
      );
      reqObj.players = players;
    }

    return res.json({ success: true, count: odRequests.length, odRequests });
  } catch (err) {
    next(err);
  }
}

async function approveOdRequest(req, res, next) {
  try {
    const odId = req.params.id;
    const staffId = req.user.id;
    const { staffRemarks } = req.body;

    const [requests] = await db.query('SELECT od.*, m.title as match_title FROM od_requests od JOIN matches m ON od.match_id = m.id WHERE od.id = ?', [odId]);
    if (requests.length === 0) {
      return res.status(404).json({ success: false, message: 'OD request not found.' });
    }

    const reqObj = requests[0];
    if (req.user.role === 'STAFF' && req.user.teamId != reqObj.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to approve request for another team.' });
    }

    await db.query(
      `UPDATE od_requests SET status = "APPROVED", reviewed_by = ?, review_timestamp = NOW(), staff_remarks = ? WHERE id = ?`,
      [staffId, staffRemarks ? staffRemarks.trim() : null, odId]
    );

    // Notify captain
    await sendNotification({
      userId: reqObj.captain_id,
      title: 'OD Request Approved!',
      message: `Your On-Duty request for match "${reqObj.match_title}" has been approved by staff.`,
      type: 'OD_DECISION',
      referenceId: odId
    });

    return res.json({ success: true, message: 'OD Request approved successfully.' });
  } catch (err) {
    next(err);
  }
}

async function rejectOdRequest(req, res, next) {
  try {
    const odId = req.params.id;
    const staffId = req.user.id;
    const { staffRemarks } = req.body;

    const [requests] = await db.query('SELECT od.*, m.title as match_title FROM od_requests od JOIN matches m ON od.match_id = m.id WHERE od.id = ?', [odId]);
    if (requests.length === 0) {
      return res.status(404).json({ success: false, message: 'OD request not found.' });
    }

    const reqObj = requests[0];
    if (req.user.role === 'STAFF' && req.user.teamId != reqObj.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to reject request for another team.' });
    }

    await db.query(
      `UPDATE od_requests SET status = "REJECTED", reviewed_by = ?, review_timestamp = NOW(), staff_remarks = ? WHERE id = ?`,
      [staffId, staffRemarks ? staffRemarks.trim() : 'Does not fulfill OD criteria', odId]
    );

    // Notify captain
    await sendNotification({
      userId: reqObj.captain_id,
      title: 'OD Request Rejected',
      message: `Your On-Duty request for match "${reqObj.match_title}" was rejected by staff. Remarks: ${staffRemarks || 'None'}`,
      type: 'OD_DECISION',
      referenceId: odId
    });

    return res.json({ success: true, message: 'OD Request rejected.' });
  } catch (err) {
    next(err);
  }
}

// ================= TA/DA REQUESTS =================

async function createTadaRequest(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId || user.role !== 'CAPTAIN') {
      return res.status(403).json({ success: false, message: 'Only team captains can submit TA/DA requests.' });
    }

    const { matchId, travelDetails, estimatedAmount, remarks, playerIds } = req.body;

    if (!matchId || !travelDetails || estimatedAmount === undefined || !Array.isArray(playerIds) || playerIds.length === 0) {
      return res.status(400).json({ success: false, message: 'Match ID, travel details, estimated amount, and playerIds are required.' });
    }

    const [matches] = await db.query('SELECT m.*, t.staff_id FROM matches m JOIN teams t ON m.team_id = t.id WHERE m.id = ? AND m.team_id = ?', [matchId, teamId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found for your assigned team.' });
    }

    const match = matches[0];

    const [result] = await db.query(
      `INSERT INTO tada_requests (match_id, team_id, captain_id, travel_details, estimated_amount, remarks, status)
       VALUES (?, ?, ?, ?, ?, ?, 'PENDING')`,
      [matchId, teamId, user.id, travelDetails.trim(), parseFloat(estimatedAmount), remarks ? remarks.trim() : null]
    );

    const tadaRequestId = result.insertId;

    for (const pId of playerIds) {
      await db.query('INSERT INTO tada_request_players (tada_request_id, player_id) VALUES (?, ?)', [tadaRequestId, pId]);
    }

    // Notify staff
    if (match.staff_id) {
      await sendNotification({
        userId: match.staff_id,
        title: 'New TA/DA Approval Request',
        message: `Captain ${user.name} submitted a TA/DA claim for estimated $${estimatedAmount} for "${match.title}".`,
        type: 'TADA_SUBMITTED',
        referenceId: tadaRequestId
      });
    }

    return res.status(201).json({
      success: true,
      message: 'TA/DA request submitted successfully for staff approval.',
      tadaRequestId
    });
  } catch (err) {
    next(err);
  }
}

async function getTadaRequests(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId && user.role !== 'STAFF') {
      return res.status(400).json({ success: false, message: 'No team assigned.' });
    }

    let sql = `
      SELECT td.*, m.title as match_title, m.match_date, t.name as team_name, u_capt.name as captain_name
      FROM tada_requests td
      JOIN matches m ON td.match_id = m.id
      JOIN teams t ON td.team_id = t.id
      JOIN users u_capt ON td.captain_id = u_capt.id
    `;
    const params = [];

    if (teamId) {
      sql += ' WHERE td.team_id = ?';
      params.push(teamId);
    }

    sql += ' ORDER BY td.created_at DESC';

    const [tadaRequests] = await db.query(sql, params);

    for (const reqObj of tadaRequests) {
      const [players] = await db.query(
        `SELECT p.id as player_id, p.jersey_number, p.position,
                u.name as player_name, u.register_number, u.department
         FROM tada_request_players tdp
         JOIN players p ON tdp.player_id = p.id
         JOIN users u ON p.user_id = u.id
         WHERE tdp.tada_request_id = ?`,
        [reqObj.id]
      );
      reqObj.players = players;
    }

    return res.json({ success: true, count: tadaRequests.length, tadaRequests });
  } catch (err) {
    next(err);
  }
}

async function approveTadaRequest(req, res, next) {
  try {
    const tadaId = req.params.id;
    const staffId = req.user.id;
    const { actualAmount, staffRemarks } = req.body;

    const [requests] = await db.query('SELECT td.*, m.title as match_title FROM tada_requests td JOIN matches m ON td.match_id = m.id WHERE td.id = ?', [tadaId]);
    if (requests.length === 0) {
      return res.status(404).json({ success: false, message: 'TA/DA request not found.' });
    }

    const reqObj = requests[0];
    if (req.user.role === 'STAFF' && req.user.teamId != reqObj.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to approve request for another team.' });
    }

    const approvedAmount = actualAmount !== undefined ? parseFloat(actualAmount) : reqObj.estimated_amount;

    await db.query(
      `UPDATE tada_requests SET status = "APPROVED", actual_amount = ?, reviewed_by = ?, review_timestamp = NOW(), staff_remarks = ? WHERE id = ?`,
      [approvedAmount, staffId, staffRemarks ? staffRemarks.trim() : null, tadaId]
    );

    // Notify captain
    await sendNotification({
      userId: reqObj.captain_id,
      title: 'TA/DA Request Approved!',
      message: `Your TA/DA claim for "${reqObj.match_title}" was approved by staff. Approved amount: $${approvedAmount}`,
      type: 'TADA_DECISION',
      referenceId: tadaId
    });

    return res.json({ success: true, message: 'TA/DA Request approved.' });
  } catch (err) {
    next(err);
  }
}

async function rejectTadaRequest(req, res, next) {
  try {
    const tadaId = req.params.id;
    const staffId = req.user.id;
    const { staffRemarks } = req.body;

    const [requests] = await db.query('SELECT td.*, m.title as match_title FROM tada_requests td JOIN matches m ON td.match_id = m.id WHERE td.id = ?', [tadaId]);
    if (requests.length === 0) {
      return res.status(404).json({ success: false, message: 'TA/DA request not found.' });
    }

    const reqObj = requests[0];
    if (req.user.role === 'STAFF' && req.user.teamId != reqObj.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to reject request for another team.' });
    }

    await db.query(
      `UPDATE tada_requests SET status = "REJECTED", reviewed_by = ?, review_timestamp = NOW(), staff_remarks = ? WHERE id = ?`,
      [staffId, staffRemarks ? staffRemarks.trim() : 'Does not fulfill TA/DA policy', tadaId]
    );

    await sendNotification({
      userId: reqObj.captain_id,
      title: 'TA/DA Request Rejected',
      message: `Your TA/DA claim for "${reqObj.match_title}" was rejected by staff. Remarks: ${staffRemarks || 'None'}`,
      type: 'TADA_DECISION',
      referenceId: tadaId
    });

    return res.json({ success: true, message: 'TA/DA Request rejected.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createOdRequest,
  getOdRequests,
  approveOdRequest,
  rejectOdRequest,
  createTadaRequest,
  getTadaRequests,
  approveTadaRequest,
  rejectTadaRequest
};
