const express = require('express');
const router = express.Router();
const feedbackController = require('../controllers/feedbackController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/', authenticate, feedbackController.getFeedbackList);
router.post('/', authenticate, authorize('CAPTAIN'), feedbackController.submitFeedback);
router.post('/:id/respond', authenticate, authorize('STAFF'), feedbackController.respondToFeedback);

module.exports = router;
