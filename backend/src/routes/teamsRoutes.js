const express = require('express');
const router = express.Router();
const sportsController = require('../controllers/sportsController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/my-team', authenticate, sportsController.getMyTeam);
router.get('/:id', authenticate, sportsController.getTeamById);

module.exports = router;
