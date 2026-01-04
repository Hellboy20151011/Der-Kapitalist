import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const productionRouter = express.Router();

/**
 * Konfiguration (MVP)
 * well: 1 water / 3s / 1 coin
 */
const CONFIG = {
  well: { resource: 'water', seconds_per_unit: 3, coin_cost_per_unit: 1n },
  // später: lumberjack, stonemason ...
};

const startSchema = z.object({
  building_type: z.enum(['well']), // später erweitern
  quantity: z.number().int().positive().max(1_000_000)
});

productionRouter.post('/start', authRequired, async (req, res) => {
  const parsed = startSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type, quantity } = parsed.data;

  const cfg = CONFIG[building_type];
  const qty = BigInt(quantity);
  const totalCost = qty * cfg.coin_cost_per_unit;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Gebäude locken
    const bRes = await client.query(
      `SELECT id, level, is_producing, ready_at
       FROM buildings
       WHERE user_id = $1 AND building_type = $2
       FOR UPDATE`,
      [userId, building_type]
    );

    if (bRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_not_found' });
    }

    const b = bRes.rows[0];
    if (b.is_producing) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_busy' });
    }

    // Coins locken
    const sRes = await client.query(
      `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    const coins = BigInt(sRes.rows[0].coins);
    if (coins < totalCost) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_coins' });
    }

    // Coins abziehen
    await client.query(
      `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
      [userId, totalCost.toString()]
    );

    // ready_at setzen
    const seconds = Number(qty) * cfg.seconds_per_unit; // qty begrenzt, ok für MVP
    const readyAtRes = await client.query(
      `UPDATE buildings
       SET is_producing = true,
           producing_qty = $3,
           ready_at = now() + ($2 || ' seconds')::interval
       WHERE user_id = $1 AND building_type = $4
       RETURNING ready_at`,
      [userId, String(seconds), qty.toString(), building_type]
    );

    await client.query('COMMIT');

    return res.json({
      ok: true,
      building_type,
      quantity: qty.toString(),
      cost: totalCost.toString(),
      ready_at: readyAtRes.rows[0].ready_at
    });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

const collectSchema = z.object({
  building_type: z.enum(['well'])
});

productionRouter.post('/collect', authRequired, async (req, res) => {
  const parsed = collectSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type } = parsed.data;
  const cfg = CONFIG[building_type];

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Gebäude locken
    const bRes = await client.query(
      `SELECT is_producing, ready_at, producing_qty
       FROM buildings
       WHERE user_id = $1 AND building_type = $2
       FOR UPDATE`,
      [userId, building_type]
    );

    if (bRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_not_found' });
    }

    const b = bRes.rows[0];
    if (!b.is_producing) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'nothing_to_collect' });
    }

    const readyAt = new Date(b.ready_at);
    if (readyAt.getTime() > Date.now()) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_ready_yet', ready_at: b.ready_at });
    }

    const qty = BigInt(b.producing_qty ?? 0);
    if (qty <= 0n) {
      await client.query('ROLLBACK');
      return res.status(500).json({ error: 'invalid_production_qty' });
    }

    // Inventar gutschreiben
    await client.query(
      `INSERT INTO inventory(user_id, resource_type, amount)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, resource_type)
       DO UPDATE SET amount = inventory.amount + EXCLUDED.amount`,
      [userId, cfg.resource, qty.toString()]
    );

    // Auftrag zurücksetzen
    await client.query(
      `UPDATE buildings
       SET is_producing = false, ready_at = NULL, producing_qty = NULL
       WHERE user_id = $1 AND building_type = $2`,
      [userId, building_type]
    );

    await client.query('COMMIT');
    return res.json({ ok: true, building_type, quantity: qty.toString(), resource: cfg.resource });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});
