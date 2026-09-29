const express = require('express');
const router = express.Router();
const notificationsController = require('../controllers/notificationsController');
const { authenticate } = require('../middleware/authMiddleware');

router.get('/', authenticate, notificationsController.getNotifications);
router.patch('/read-all', authenticate, notificationsController.markAllAsRead);
router.patch('/:id/read', authenticate, notificationsController.markAsRead);
router.post('/device-token', authenticate, notificationsController.registerDeviceToken);

module.exports = router;
