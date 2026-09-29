const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/authRoutes');
const sportsRoutes = require('./routes/sportsRoutes');
const teamsRoutes = require('./routes/teamsRoutes');
const playersRoutes = require('./routes/playersRoutes');
const matchesRoutes = require('./routes/matchesRoutes');
const requestsRoutes = require('./routes/requestsRoutes');
const trainingRoutes = require('./routes/trainingRoutes');
const feedbackRoutes = require('./routes/feedbackRoutes');
const notificationsRoutes = require('./routes/notificationsRoutes');

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health Check & Root API
app.get('/api/health', (req, res) => {
  res.json({
    status: 'UP',
    app: 'SportSync Backend Service',
    timestamp: new Date().toISOString()
  });
});

// API Routes Mounting
app.use('/api/auth', authRoutes);
app.use('/api/sports', sportsRoutes);
app.use('/api/teams', teamsRoutes);
app.use('/api/players', playersRoutes);
app.use('/api/matches', matchesRoutes);
app.use('/api', requestsRoutes); // Handles /api/od-requests and /api/tada-requests
app.use('/api/selections', matchesRoutes); // Handles /api/selections/:id/approve & reject
app.use('/api/training', trainingRoutes);
app.use('/api/feedback', feedbackRoutes);
app.use('/api/notifications', notificationsRoutes);

// 404 Handler
app.use((req, res, next) => {
  res.status(404).json({
    success: false,
    message: `API Route '${req.originalUrl}' not found on SportSync backend.`
  });
});

// Centralized Error Handler Middleware
app.use(errorHandler);

module.exports = app;
