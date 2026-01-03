import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';
import { applyCatchUpProduction } from '../services/simService.js';

export const economyRouter = express.Router();

const SELL_PRICES = { water: 1n, wood: 3n, stone: 5n };

const sellSchema = z.object({
  resource_type: z.enum(['water', 'wood', 'stone']),
  quantity: z.number().int().positive().max(1_000_000)
});

economyRouter.post('/sell', authRequired, async (req, res) => {
  const parsed = sellSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { resource_type, quantity } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await applyCatchUpProduction(client, userId);

    const invRes = await client.query(
      `SELECT amount FROM inventory WHERE user_id = $1 AND resource_type = $2 FOR UPDATE`,
      [userId, resource_type]
    );

    const have = invRes.rowCount ? BigInt(invRes.rows[0].amount) : 0n;
    const qty = BigInt(quantity);

    if (have < qty) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_resources' });
    }

    const gain = qty * SELL_PRICES[resource_type];

    await client.query(
      `UPDATE inventory SET amount = amount - $3 WHERE user_id = $1 AND resource_type = $2`,
      [userId, resource_type, qty.toString()]
    );

    await client.query(
      `UPDATE player_state SET coins = coins + $2 WHERE user_id = $1`,
      [userId, gain.toString()]
    );

    await client.query('COMMIT');
    return res.json({ ok: true });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

const upgradeSchema = z.object({
  building_type: z.enum(['well', 'lumberjack', 'stonemason'])
});

// Simple Kostenkurve: 100 * 1.6^(level-1)
function upgradeCost(level) {
  const base = 100;
  const cost = base * Math.pow(1.6, Math.max(0, level - 1));
  return BigInt(Math.floor(cost));
}

economyRouter.post('/buildings/upgrade', authRequired, async (req, res) => {
  const parsed = upgradeSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await applyCatchUpProduction(client, userId);

    const bRes = await client.query(
      `SELECT level FROM buildings WHERE user_id = $1 AND building_type = $2 FOR UPDATE`,
      [userId, building_type]
    );

    if (bRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_not_found' });
    }

    const level = Number(bRes.rows[0].level);
    const cost = upgradeCost(level);

    const sRes = await client.query(
      `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    const coins = BigInt(sRes.rows[0].coins);
    if (coins < cost) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_coins' });
    }

    await client.query(
      `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
      [userId, cost.toString()]
    );

    await client.query(
      `UPDATE buildings SET level = level + 1 WHERE user_id = $1 AND building_type = $2`,
      [userId, building_type]
    );

    await client.query('COMMIT');
    return res.json({ ok: true });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});