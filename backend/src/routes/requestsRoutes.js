const express = require('express');
const router = express.Router();
const requestsController = require('../controllers/requestsController');
const { authenticate, authorize } = require('../middleware/authMiddleware');

// OD Requests
router.post('/od-requests', authenticate, authorize('CAPTAIN'), requestsController.createOdRequest);
router.get('/od-requests', authenticate, requestsController.getOdRequests);
router.patch('/od-requests/:id/approve', authenticate, authorize('STAFF'), requestsController.approveOdRequest);
router.patch('/od-requests/:id/reject', authenticate, authorize('STAFF'), requestsController.rejectOdRequest);

// TA/DA Requests
router.post('/tada-requests', authenticate, authorize('CAPTAIN'), requestsController.createTadaRequest);
router.get('/tada-requests', authenticate, requestsController.getTadaRequests);
router.patch('/tada-requests/:id/approve', authenticate, authorize('STAFF'), requestsController.approveTadaRequest);
router.patch('/tada-requests/:id/reject', authenticate, authorize('STAFF'), requestsController.rejectTadaRequest);

module.exports = router;
