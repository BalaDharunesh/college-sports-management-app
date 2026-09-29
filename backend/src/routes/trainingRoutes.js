const express = require('express');
const router = express.Router();
const trainingController = require('../controllers/trainingController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

router.get('/', authenticate, trainingController.getTrainingSchedules);
router.post('/', authenticate, authorize('STAFF'), trainingController.createTrainingSchedule);
router.put('/:id', authenticate, authorize('STAFF'), trainingController.updateTrainingSchedule);
router.patch('/:id/cancel', authenticate, authorize('STAFF'), trainingController.cancelTrainingSchedule);

module.exports = router;
