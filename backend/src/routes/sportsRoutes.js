const express = require('express');
const router = express.Router();
const sportsController = require('../controllers/sportsController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, sportsController.getSports);

module.exports = router;
