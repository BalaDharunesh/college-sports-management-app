const db = require('../config/db');
const { sendNotification, notifyTeam } = require('../services/notificationService');

async function getMatches(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId && user.role !== 'STAFF') {
      return res.status(400).json({ success: false, message: 'No team assigned to user account.' });
    }

    const { status } = req.query;
    let sql = `
      SELECT m.*, s.name as sport_name, t.name as team_name,
             mr.team_score, mr.opponent_score, mr.outcome, mr.remarks as result_remarks
      FROM matches m
      JOIN sports s ON m.sport_id = s.id
      JOIN teams t ON m.team_id = t.id
      LEFT JOIN match_results mr ON mr.match_id = m.id
    `;
    const params = [];

    if (teamId) {
      sql += ' WHERE m.team_id = ?';
      params.push(teamId);
      if (status) {
        sql += ' AND m.status = ?';
        params.push(status);
      }
    } else if (status) {
      sql += ' WHERE m.status = ?';
      params.push(status);
    }

    sql += ' ORDER BY m.match_date ASC, m.start_time ASC';

    const [matches] = await db.query(sql, params);

    // Attach selections for all matches so STAFF and CAPTAINS can see match selections
    for (const m of matches) {
      const [selections] = await db.query(
        `SELECT ms.*, p.jersey_number, p.position,
                u.name as player_name, u.register_number, u.department, u.academic_year, u.email
         FROM match_selections ms
         JOIN players p ON ms.player_id = p.id
         JOIN users u ON p.user_id = u.id
         WHERE ms.match_id = ?
         ORDER BY u.name ASC`,
        [m.id]
      );
      m.selections = selections;

      // If caller is player, attach their personal selection status for each match
      if (user.role === 'PLAYER' && user.playerId) {
        const mySel = selections.find(s => s.player_id == user.playerId);
        if (mySel) {
          m.my_selection_status = mySel.status;
          m.my_rejection_reason = mySel.rejection_reason;
        } else {
          m.my_selection_status = 'NOT_SELECTED';
        }
      }
    }

    return res.json({ success: true, count: matches.length, matches });
  } catch (err) {
    next(err);
  }
}

async function getMatchById(req, res, next) {
  try {
    const matchId = req.params.id;
    const user = req.user;

    const [matches] = await db.query(
      `SELECT m.*, s.name as sport_name, t.name as team_name, t.staff_id, t.captain_id,
              mr.team_score, mr.opponent_score, mr.outcome, mr.remarks as result_remarks
       FROM matches m
       JOIN sports s ON m.sport_id = s.id
       JOIN teams t ON m.team_id = t.id
       LEFT JOIN match_results mr ON mr.match_id = m.id
       WHERE m.id = ?`,
      [matchId]
    );

    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    const match = matches[0];

    // Get selections
    const [selections] = await db.query(
      `SELECT ms.*, p.jersey_number, p.position,
              u.name as player_name, u.register_number, u.department, u.academic_year, u.email
       FROM match_selections ms
       JOIN players p ON ms.player_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE ms.match_id = ?
       ORDER BY u.name ASC`,
      [matchId]
    );

    match.selections = selections;

    // Check personal player selection status
    if (user.role === 'PLAYER' && user.playerId) {
      const mySel = selections.find(s => s.player_id == user.playerId);
      match.my_selection_status = mySel ? mySel.status : 'NOT_SELECTED';
    }

    return res.json({ success: true, match });
  } catch (err) {
    next(err);
  }
}

async function createMatch(req, res, next) {
  try {
    const user = req.user;
    const teamId = user.teamId;

    if (!teamId) {
      return res.status(400).json({ success: false, message: 'Cannot create match: user is not assigned to a team.' });
    }

    const { title, opponentName, matchDate, startTime, venue, selectionDeadline, description } = req.body;

    if (!title || !matchDate || !startTime || !venue) {
      return res.status(400).json({
        success: false,
        message: 'Title, Match Date, Start Time, and Venue are required.'
      });
    }

    const finalOpponent = opponentName && opponentName.trim() ? opponentName.trim() : 'TBD';
    const finalDeadline = selectionDeadline && selectionDeadline.trim() ? selectionDeadline.trim() : `${matchDate} 18:00:00`;

    // Get sport_id from team
    const [teams] = await db.query('SELECT sport_id, staff_id FROM teams WHERE id = ?', [teamId]);
    if (teams.length === 0) {
      return res.status(404).json({ success: false, message: 'Assigned team not found.' });
    }

    const sportId = teams[0].sport_id;
    const staffId = teams[0].staff_id;

    const [result] = await db.query(
      `INSERT INTO matches (title, sport_id, team_id, opponent_name, match_date, start_time, venue, selection_deadline, description, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'SCHEDULED')`,
      [title.trim(), sportId, teamId, finalOpponent, matchDate, startTime, venue.trim(), finalDeadline, description ? description.trim() : null]
    );

    const matchId = result.insertId;

    // Notify staff if match created by captain
    if (user.role === 'CAPTAIN' && staffId) {
      await sendNotification({
        userId: staffId,
        title: 'New Match Created by Captain',
        message: `Captain ${user.name} created match "${title}" vs ${opponentName} scheduled for ${matchDate}.`,
        type: 'MATCH_CREATED',
        referenceId: matchId
      });
    }

    return res.status(201).json({
      success: true,
      message: 'Match created successfully.',
      matchId
    });
  } catch (err) {
    next(err);
  }
}

async function updateMatch(req, res, next) {
  try {
    const matchId = req.params.id;
    const user = req.user;

    const [matches] = await db.query('SELECT * FROM matches WHERE id = ?', [matchId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    const match = matches[0];
    if (user.role !== 'STAFF' && user.teamId != match.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to edit matches for another team.' });
    }

    const { title, opponentName, matchDate, startTime, venue, selectionDeadline, description } = req.body;

    await db.query(
      `UPDATE matches SET
              title = COALESCE(?, title),
              opponent_name = COALESCE(?, opponent_name),
              match_date = COALESCE(?, match_date),
              start_time = COALESCE(?, start_time),
              venue = COALESCE(?, venue),
              selection_deadline = COALESCE(?, selection_deadline),
              description = COALESCE(?, description)
       WHERE id = ?`,
      [
        title ? title.trim() : null,
        opponentName ? opponentName.trim() : null,
        matchDate || null,
        startTime || null,
        venue ? venue.trim() : null,
        selectionDeadline || null,
        description ? description.trim() : null,
        matchId
      ]
    );

    return res.json({ success: true, message: 'Match details updated successfully.' });
  } catch (err) {
    next(err);
  }
}

async function cancelMatch(req, res, next) {
  try {
    const matchId = req.params.id;
    const user = req.user;

    const [matches] = await db.query('SELECT * FROM matches WHERE id = ?', [matchId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    const match = matches[0];
    if (user.role !== 'STAFF' && user.teamId != match.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to cancel match for another team.' });
    }

    await db.query('UPDATE matches SET status = "CANCELLED" WHERE id = ?', [matchId]);

    // Notify team
    await notifyTeam({
      teamId: match.team_id,
      title: 'Match Cancelled',
      message: `The match "${match.title}" vs ${match.opponent_name} scheduled for ${match.match_date} has been cancelled.`,
      type: 'MATCH_CANCELLED',
      referenceId: matchId,
      excludeUserId: user.id
    });

    return res.json({ success: true, message: 'Match cancelled successfully.' });
  } catch (err) {
    next(err);
  }
}

// CAPTAIN SUBMITS MATCH SQUAD SELECTIONS
async function submitMatchSelections(req, res, next) {
  try {
    const matchId = req.params.id;
    const user = req.user;
    const { playerIds } = req.body; // Array of player_id numbers

    if (!Array.isArray(playerIds) || playerIds.length === 0) {
      return res.status(400).json({ success: false, message: 'playerIds array is required and must contain at least one player.' });
    }

    // 1. Fetch match and team details
    const [matches] = await db.query(
      'SELECT m.*, t.staff_id FROM matches m JOIN teams t ON m.team_id = t.id WHERE m.id = ?',
      [matchId]
    );

    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    const match = matches[0];

    // Enforce team ownership
    if (user.teamId != match.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to submit squad selections for another team.' });
    }

    // Check selection deadline if present
    if (match.selection_deadline) {
      const now = new Date();
      const deadline = new Date(match.selection_deadline);
      // Only block if match is not SCHEDULED or if match_date has already passed
      const matchDate = new Date(match.match_date);
      if (match.status !== 'SCHEDULED' && now > matchDate) {
        return res.status(400).json({ success: false, message: 'Selection deadline for this match has expired.' });
      }
    }

    // 2. Validate all submitted players belong to captain's team and are ACTIVE
    const placeholders = playerIds.map(() => '?').join(',');
    const [validPlayers] = await db.query(
      `SELECT id FROM players WHERE team_id = ? AND is_active = 1 AND id IN (${placeholders})`,
      [match.team_id, ...playerIds]
    );

    if (validPlayers.length !== new Set(playerIds).size) {
      return res.status(400).json({
        success: false,
        message: 'Invalid selection: One or more selected players do not belong to your team or are deactivated.'
      });
    }

    // 3. Upsert selections into PENDING status
    for (const pId of playerIds) {
      // Check existing selection record
      const [exist] = await db.query('SELECT id, status FROM match_selections WHERE match_id = ? AND player_id = ?', [matchId, pId]);
      if (exist.length > 0) {
        // If rejected previously, reset to PENDING for re-review
        await db.query(
          'UPDATE match_selections SET status = "PENDING", rejection_reason = NULL, reviewed_by = NULL, review_timestamp = NULL WHERE id = ?',
          [exist[0].id]
        );
      } else {
        await db.query(
          'INSERT INTO match_selections (match_id, player_id, status) VALUES (?, ?, "PENDING")',
          [matchId, pId]
        );
      }
    }

    // Remove any players no longer in playerIds if in PENDING state
    await db.query(
      `DELETE FROM match_selections WHERE match_id = ? AND status = "PENDING" AND player_id NOT IN (${placeholders})`,
      [matchId, ...playerIds]
    );

    // 4. Notify Staff
    if (match.staff_id) {
      await sendNotification({
        userId: match.staff_id,
        title: 'New Match Squad Selection Submitted',
        message: `Captain ${user.name} submitted ${playerIds.length} players for "${match.title}". Pending your approval.`,
        type: 'SELECTION_SUBMITTED',
        referenceId: matchId
      });
    } else {
      // Notify all active STAFF members if team has no specific staff_id assigned
      const [staffUsers] = await db.query('SELECT id FROM users WHERE role = "STAFF" AND is_active = 1');
      for (const sUser of staffUsers) {
        await sendNotification({
          userId: sUser.id,
          title: 'New Match Squad Selection Submitted',
          message: `Captain ${user.name} submitted ${playerIds.length} players for "${match.title}". Pending approval.`,
          type: 'SELECTION_SUBMITTED',
          referenceId: matchId
        });
      }
    }

    return res.json({
      success: true,
      message: `Successfully submitted ${playerIds.length} players for staff approval.`
    });
  } catch (err) {
    next(err);
  }
}

async function getMatchSelections(req, res, next) {
  try {
    const matchId = req.params.id;

    const [selections] = await db.query(
      `SELECT ms.*, p.jersey_number, p.position,
              u.name as player_name, u.register_number, u.department, u.academic_year, u.phone, u.email
       FROM match_selections ms
       JOIN players p ON ms.player_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE ms.match_id = ?
       ORDER BY u.name ASC`,
      [matchId]
    );

    return res.json({ success: true, count: selections.length, selections });
  } catch (err) {
    next(err);
  }
}

// STAFF APPROVES PLAYER SELECTION
async function approveSelection(req, res, next) {
  try {
    const selectionId = req.params.id;
    const staffId = req.user.id;

    const [selections] = await db.query(
      `SELECT ms.*, m.title as match_title, m.team_id, p.user_id as player_user_id, u.name as player_name
       FROM match_selections ms
       JOIN matches m ON ms.match_id = m.id
       JOIN players p ON ms.player_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE ms.id = ?`,
      [selectionId]
    );

    if (selections.length === 0) {
      return res.status(404).json({ success: false, message: 'Selection record not found.' });
    }

    const sel = selections[0];

    // Enforce team ownership
    if (req.user.role === 'STAFF' && req.user.teamId && req.user.teamId != sel.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to approve selections for another team.' });
    }

    await db.query(
      `UPDATE match_selections SET status = "APPROVED", reviewed_by = ?, review_timestamp = NOW(), rejection_reason = NULL WHERE id = ?`,
      [staffId, selectionId]
    );

    // Notify approved player ONLY NOW!
    await sendNotification({
      userId: sel.player_user_id,
      title: 'Official Match Squad Selection!',
      message: `Congratulations ${sel.player_name}! You have been officially approved by sports staff for match "${sel.match_title}".`,
      type: 'MATCH_SELECTION',
      referenceId: sel.match_id
    });

    return res.json({ success: true, message: `Player ${sel.player_name} approved for match selection.` });
  } catch (err) {
    next(err);
  }
}

// STAFF REJECTS PLAYER SELECTION
async function rejectSelection(req, res, next) {
  try {
    const selectionId = req.params.id;
    const staffId = req.user.id;
    const { reason } = req.body;

    const [selections] = await db.query(
      `SELECT ms.*, m.title as match_title, m.team_id, t.captain_id, u.name as player_name
       FROM match_selections ms
       JOIN matches m ON ms.match_id = m.id
       JOIN teams t ON m.team_id = t.id
       JOIN players p ON ms.player_id = p.id
       JOIN users u ON p.user_id = u.id
       WHERE ms.id = ?`,
      [selectionId]
    );

    if (selections.length === 0) {
      return res.status(404).json({ success: false, message: 'Selection record not found.' });
    }

    const sel = selections[0];

    if (req.user.role === 'STAFF' && req.user.teamId && req.user.teamId != sel.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to reject selections for another team.' });
    }

    const rejectionReason = reason || 'Not meeting physical fitness or strategic criteria.';

    await db.query(
      `UPDATE match_selections SET status = "REJECTED", reviewed_by = ?, review_timestamp = NOW(), rejection_reason = ? WHERE id = ?`,
      [staffId, rejectionReason, selectionId]
    );

    // Notify Captain about rejection
    if (sel.captain_id) {
      await sendNotification({
        userId: sel.captain_id,
        title: 'Player Selection Rejected',
        message: `Selection of ${sel.player_name} for "${sel.match_title}" was rejected by staff. Reason: ${rejectionReason}`,
        type: 'SELECTION_REJECTED',
        referenceId: sel.match_id
      });
    }

    return res.json({ success: true, message: `Player selection rejected.` });
  } catch (err) {
    next(err);
  }
}

// MATCH RESULT SUBMISSION
async function submitMatchResult(req, res, next) {
  try {
    const matchId = req.params.id;
    const user = req.user;
    const { teamScore, opponentScore, outcome, remarks } = req.body;

    if (teamScore === undefined || teamScore === null || opponentScore === undefined || opponentScore === null || !outcome) {
      return res.status(400).json({ success: false, message: 'Team score, opponent score, and outcome (WIN/LOSS/DRAW) are required.' });
    }

    const [matches] = await db.query('SELECT * FROM matches WHERE id = ?', [matchId]);
    if (matches.length === 0) {
      return res.status(404).json({ success: false, message: 'Match not found.' });
    }

    const match = matches[0];
    if (user.role !== 'STAFF' && user.teamId != match.team_id) {
      return res.status(403).json({ success: false, message: 'Unauthorized to submit results for another team.' });
    }

    const tScore = String(teamScore).trim();
    const oScore = String(opponentScore).trim();

    // Upsert match result
    const [exist] = await db.query('SELECT id FROM match_results WHERE match_id = ?', [matchId]);
    if (exist.length > 0) {
      await db.query(
        'UPDATE match_results SET team_score = ?, opponent_score = ?, outcome = ?, remarks = ? WHERE match_id = ?',
        [tScore, oScore, outcome, remarks || null, matchId]
      );
    } else {
      await db.query(
        'INSERT INTO match_results (match_id, team_score, opponent_score, outcome, remarks) VALUES (?, ?, ?, ?, ?)',
        [matchId, tScore, oScore, outcome, remarks || null]
      );
    }

    // Mark match COMPLETED
    await db.query('UPDATE matches SET status = "COMPLETED" WHERE id = ?', [matchId]);

    // Notify whole team
    await notifyTeam({
      teamId: match.team_id,
      title: 'Match Results Published!',
      message: `Results for "${match.title}" vs ${match.opponent_name}: ${match.title} ${outcome} (${tScore} - ${oScore}).`,
      type: 'MATCH_RESULT',
      referenceId: matchId
    });

    return res.json({ success: true, message: 'Match result recorded and published successfully.' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMatches,
  getMatchById,
  createMatch,
  updateMatch,
  cancelMatch,
  submitMatchSelections,
  getMatchSelections,
  approveSelection,
  rejectSelection,
  submitMatchResult
};
