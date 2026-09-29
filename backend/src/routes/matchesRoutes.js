const express = require('express');
const router = express.Router();
const matchesController = require('../controllers/matchesController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/', authenticate, matchesController.getMatches);
router.get('/:id', authenticate, matchesController.getMatchById);
router.post('/', authenticate, authorize('STAFF', 'CAPTAIN'), matchesController.createMatch);
router.put('/:id', authenticate, authorize('STAFF', 'CAPTAIN'), matchesController.updateMatch);
router.patch('/:id/cancel', authenticate, authorize('STAFF', 'CAPTAIN'), matchesController.cancelMatch);

// Selections
router.post('/:id/selections', authenticate, authorize('CAPTAIN'), matchesController.submitMatchSelections);
router.get('/:id/selections', authenticate, matchesController.getMatchSelections);

// Selection approval endpoints (Note: route path matched to /api/selections/:id/approve & reject via subrouter or root mount)
router.patch('/selections/:id/approve', authenticate, authorize('STAFF'), matchesController.approveSelection);
router.patch('/selections/:id/reject', authenticate, authorize('STAFF'), matchesController.rejectSelection);

// Results
router.post('/:id/result', authenticate, authorize('STAFF'), matchesController.submitMatchResult);
router.put('/:id/result', authenticate, authorize('STAFF'), matchesController.submitMatchResult);

module.exports = router;
