const mysql = require('mysql2/promise');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const fs = require('fs');
require('dotenv').config();

let dbMode = 'MYSQL'; // 'MYSQL' or 'SQLITE'
let mysqlPool = null;
let sqliteDb = null;

async function initDatabaseConnection() {
  const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'sports_management_db',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  };

  try {
    // Try connecting to MySQL
    const tempPool = mysql.createPool(dbConfig);
    const connection = await tempPool.getConnection();
    console.log('[DB] Connected to MySQL database successfully.');
    connection.release();
    mysqlPool = tempPool;
    dbMode = 'MYSQL';
  } catch (err) {
    console.warn('[DB] MySQL connection failed/access denied:', err.message);
    console.log('[DB] Falling back to SQLite database for instant zero-config setup...');
    
    const dbDir = path.join(__dirname, '../../data');
    if (!fs.existsSync(dbDir)) {
      fs.mkdirSync(dbDir, { recursive: true });
    }
    const dbPath = path.join(dbDir, 'sports_management.sqlite');
    
    sqliteDb = new sqlite3.Database(dbPath);
    dbMode = 'SQLITE';
    console.log(`[DB] SQLite database active at ${dbPath}`);
  }
}

// Unified query wrapper returning Promise [rows, fields]
async function query(sql, params = []) {
  if (dbMode === 'MYSQL' && mysqlPool) {
    return await mysqlPool.query(sql, params);
  } else if (dbMode === 'SQLITE' && sqliteDb) {
    return new Promise((resolve, reject) => {
      // Normalize SQL syntax differences (e.g. NOW(), AUTO_INCREMENT -> AUTOINCREMENT, ENUM etc for SQLite compatibility)
      let convertedSql = sql
        .replace(/NOW\(\)/gi, "datetime('now')")
        .replace(/CURRENT_TIMESTAMP/gi, "datetime('now')")
        .replace(/ON UPDATE CURRENT_TIMESTAMP/gi, "")
        .replace(/ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;/gi, ";")
        .replace(/ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;/gi, ";")
        .replace(/AUTO_INCREMENT/gi, "AUTOINCREMENT")
        .replace(/TINYINT\(1\)/gi, "INTEGER")
        .replace(/DECIMAL\(10,2\)/gi, "REAL");

      // Check if INSERT / UPDATE / DELETE vs SELECT
      const trimmed = convertedSql.trim().toUpperCase();
      if (trimmed.startsWith('SELECT') || trimmed.startsWith('PRAGMA') || trimmed.startsWith('SHOW')) {
        sqliteDb.all(convertedSql, params, (err, rows) => {
          if (err) return reject(err);
          resolve([rows, []]);
        });
      } else {
        sqliteDb.run(convertedSql, params, function (err) {
          if (err) return reject(err);
          resolve([{ insertId: this.lastID, affectedRows: this.changes }, []]);
        });
      }
    });
  } else {
    throw new Error('Database connection not initialized');
  }
}

function getDbMode() {
  return dbMode;
}

module.exports = {
  initDatabaseConnection,
  query,
  getDbMode
};
