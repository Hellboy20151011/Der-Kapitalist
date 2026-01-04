import pg from 'pg';
import { config } from './config.js';

// Configure connection pool with reasonable defaults to prevent resource exhaustion
export const pool = new pg.Pool({
  connectionString: config.dbUrl,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 10000, // Return an error if connection takes longer than 10 seconds
  // Note: These are conservative defaults. Adjust based on load testing and production requirements.
});

// Handle pool errors to prevent unhandled promise rejections
pool.on('error', (err) => {
  console.error('Unexpected database pool error:', err);
});