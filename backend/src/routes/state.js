import express from 'express';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const stateRouter = express.Router();

stateRouter.get('/', authRequired, async (req, res) => {
  const userId = req.user.id;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Idle production removed: buildings no longer produce automatically over time

    const stateRes = await client.query(
      `SELECT coins, last_tick_at FROM player_state WHERE user_id = $1`,
      [userId]
    );

    const invRes = await client.query(
      `SELECT resource_type, amount FROM inventory WHERE user_id = $1`,
      [userId]
    );

    const bRes = await client.query(
      `SELECT building_type, level, is_producing, ready_at, producing_qty FROM buildings WHERE user_id = $1 ORDER BY building_type`,
      [userId]
    );

    await client.query('COMMIT');

    const inventory = {};
for (const row of invRes.rows) inventory[row.resource_type] = String(row.amount);

return res.json({
  server_time: new Date().toISOString(),
  coins: String(stateRes.rows[0].coins),
  last_tick_at: stateRes.rows[0].last_tick_at,
  inventory,
  buildings: bRes.rows.map(r => ({
    type: r.building_type,
    level: Number(r.level),
    is_producing: !!r.is_producing,
    ready_at: r.ready_at,
    producing_qty: r.producing_qty ? String(r.producing_qty) : null
  }))
});
  } catch (e) {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});