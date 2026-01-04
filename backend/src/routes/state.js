import express from 'express';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const stateRouter = express.Router();

// Production resource mapping
const BUILDING_RESOURCES = {
  well: 'water',
  lumberjack: 'wood',
  sandgrube: 'stone'
};

stateRouter.get('/', authRequired, async (req, res) => {
  const userId = req.user.id;
  const client = await pool.connect();

  try {
    await client.query('SET statement_timeout = 10000');
    await client.query('BEGIN');

    // Idle production removed: buildings no longer produce automatically over time

    const stateRes = await client.query(
      `SELECT coins, last_tick_at FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    const bRes = await client.query(
      `SELECT building_type, level, is_producing, ready_at, producing_qty FROM buildings WHERE user_id = $1 ORDER BY building_type FOR UPDATE`,
      [userId]
    );

    // Auto-collect finished productions
    const now = new Date();
    for (const b of bRes.rows) {
      if (b.is_producing && b.ready_at) {
        const readyAt = new Date(b.ready_at);
        if (readyAt <= now) {
          // Production is finished, auto-collect
          const qty = BigInt(b.producing_qty ?? 0);
          const resource = BUILDING_RESOURCES[b.building_type];
          
          // Data integrity checks
          if (!b.producing_qty && b.is_producing) {
            console.warn(`Data integrity issue: building ${b.building_type} for user ${userId} is_producing=true but producing_qty is null`);
          }
          
          if (!resource) {
            console.warn(`Unknown building type ${b.building_type} for user ${userId} - cannot determine resource type`);
          }
          
          if (qty > 0n && resource) {
            // Add to inventory
            await client.query(
              `INSERT INTO inventory(user_id, resource_type, amount)
               VALUES ($1, $2, $3)
               ON CONFLICT (user_id, resource_type)
               DO UPDATE SET amount = inventory.amount + EXCLUDED.amount`,
              [userId, resource, qty.toString()]
            );
            
            // Reset building state
            await client.query(
              `UPDATE buildings
               SET is_producing = false, ready_at = NULL, producing_qty = NULL
               WHERE user_id = $1 AND building_type = $2`,
              [userId, b.building_type]
            );
            
            // Mark as collected in our local data
            b.is_producing = false;
            b.ready_at = null;
            b.producing_qty = null;
          } else if (b.is_producing && b.ready_at && new Date(b.ready_at) <= now) {
            // Production finished but we can't collect - reset building state to avoid stuck state
            console.error(`Cannot collect production for building ${b.building_type} - resetting state`);
            await client.query(
              `UPDATE buildings
               SET is_producing = false, ready_at = NULL, producing_qty = NULL
               WHERE user_id = $1 AND building_type = $2`,
              [userId, b.building_type]
            );
            b.is_producing = false;
            b.ready_at = null;
            b.producing_qty = null;
          }
        }
      }
    }

    // Fetch inventory after auto-collect
    const invRes = await client.query(
      `SELECT resource_type, amount FROM inventory WHERE user_id = $1`,
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
        ready_at_unix: r.ready_at ? Math.floor(new Date(r.ready_at).getTime() / 1000) : null,
        producing_qty: r.producing_qty ? String(r.producing_qty) : null
      }))
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('State error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});