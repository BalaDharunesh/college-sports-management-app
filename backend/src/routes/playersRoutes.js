const express = require('express');
const router = express.Router();
const playersController = require('../controllers/playersController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/', authenticate, playersController.getPlayers);
router.get('/:id', authenticate, playersController.getPlayerById);
router.post('/', authenticate, authorize('STAFF', 'CAPTAIN'), playersController.createPlayer);
router.put('/:id', authenticate, authorize('STAFF', 'CAPTAIN'), playersController.updatePlayer);
router.patch('/:id/deactivate', authenticate, authorize('STAFF', 'CAPTAIN'), playersController.deactivatePlayer);

module.exports = router;
