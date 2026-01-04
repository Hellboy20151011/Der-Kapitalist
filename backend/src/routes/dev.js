import express from 'express';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const devRouter = express.Router();

// Only allow dev routes in development environment
const isDev = process.env.NODE_ENV !== 'production';

// Reset account endpoint - DEV only
// NOTE: This endpoint is not rate-limited as it's:
// 1. Only available in development (NODE_ENV check)
// 2. Requires authentication
// 3. Only affects the authenticated user's own account
// Rate limiting should be added if this endpoint is ever enabled in production
devRouter.post('/reset-account', authRequired, async (req, res) => {
  if (!isDev) {
    return res.status(403).json({ error: 'dev_only_endpoint' });
  }

  const userId = req.user.id;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Reset player_state - give starting coins again
    await client.query(
      `UPDATE player_state SET coins = 100, last_tick_at = now() WHERE user_id = $1`,
      [userId]
    );

    // Clear inventory
    await client.query(
      `UPDATE inventory SET amount = 0 WHERE user_id = $1`,
      [userId]
    );

    // Delete all buildings
    await client.query(
      `DELETE FROM buildings WHERE user_id = $1`,
      [userId]
    );

    // Re-seed starting buildings
    const buildings = ['well', 'lumberjack', 'sandgrube'];
    for (const b of buildings) {
      await client.query(
        `INSERT INTO buildings(user_id, building_type, level) VALUES ($1, $2, 1)
         ON CONFLICT (user_id, building_type) DO NOTHING`,
        [userId, b]
      );
    }

    // Cancel all active productions
    await client.query(
      `DELETE FROM production_jobs WHERE user_id = $1`,
      [userId]
    );

    // Cancel all market listings (return resources if active)
    const activeListings = await client.query(
      `SELECT id, resource_type, quantity FROM market_listings
       WHERE seller_user_id = $1 AND status = 'active'`,
      [userId]
    );

    for (const listing of activeListings.rows) {
      // Return resources to inventory
      await client.query(
        `UPDATE inventory SET amount = amount + $2
         WHERE user_id = $1 AND resource_type = $3`,
        [userId, listing.quantity, listing.resource_type]
      );
    }

    // Delete all market listings
    await client.query(
      `DELETE FROM market_listings WHERE seller_user_id = $1`,
      [userId]
    );

    await client.query('COMMIT');
    return res.json({ ok: true, message: 'account_reset_success' });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Reset account error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});
