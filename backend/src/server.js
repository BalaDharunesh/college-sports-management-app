const app = require('./app');
const { initDatabaseConnection } = require('./config/db');
const initDb = require('./utils/initDb');
require('dotenv').config();

const PORT = process.env.PORT || 5000;

async function startServer() {
  try {
    console.log('==================================================');
    console.log('       SportSync Backend REST API Server          ');
    console.log('==================================================');

    // Initialize database pool / connection
    await initDatabaseConnection();

    // Verify & seed database tables
    await initDb();

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`[SportSync] Server is running on port ${PORT}`);
      console.log(`[SportSync] Health check available at: http://localhost:${PORT}/api/health`);
    });
  } catch (err) {
    console.error('[SportSync Server Fatal Error]', err);
    process.exit(1);
  }
}

startServer();
