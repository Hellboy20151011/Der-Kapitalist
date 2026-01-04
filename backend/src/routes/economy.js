import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const economyRouter = express.Router();

const SELL_PRICES = { 
  water: 1.2, 
  wood: 1.3, 
  stone: 1.4,
  sand: 1.5,
  limestone: 1.6,
  cement: 2.0,
  concrete: 2.5,
  stone_blocks: 2.2,
  wood_planks: 1.8
};

const sellSchema = z.object({
  resource_type: z.enum(['water', 'wood', 'stone', 'sand', 'limestone', 'cement', 'concrete', 'stone_blocks', 'wood_planks']),
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

    // Idle production removed: buildings no longer produce automatically over time

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

    // Calculate gain with decimal price, then convert to integer coins
    const gain = BigInt(Math.floor(Number(qty) * SELL_PRICES[resource_type]));

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
  building_type: z.enum(['well', 'lumberjack', 'sandgrube', 'kalktagebau', 'steinfabrik', 'saegewerk', 'zementwerk', 'betonfabrik'])
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

    // Idle production removed: buildings no longer produce automatically over time

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

// Building costs for construction (not upgrades)
const BUILD_COSTS = {
  lumberjack: { coins: 10n, wood: 10n, stone: 0n },
  sandgrube: { coins: 10n, wood: 10n, stone: 0n },
  well: { coins: 10n, wood: 10n, stone: 20n },
  kalktagebau: { coins: 50n, wood: 20n, stone: 30n },
  steinfabrik: { coins: 100n, wood: 30n, sand: 50n },
  saegewerk: { coins: 75n, wood: 40n, stone: 20n },
  zementwerk: { coins: 150n, wood: 30n, sand: 40n, limestone: 40n },
  betonfabrik: { coins: 200n, wood: 40n, cement: 30n, sand: 60n }
};

const buildSchema = z.object({
  building_type: z.enum(['well', 'lumberjack', 'sandgrube', 'kalktagebau', 'steinfabrik', 'saegewerk', 'zementwerk', 'betonfabrik'])
});

economyRouter.post('/buildings/build', authRequired, async (req, res) => {
  const parsed = buildSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if building already exists
    const existingRes = await client.query(
      `SELECT id FROM buildings WHERE user_id = $1 AND building_type = $2`,
      [userId, building_type]
    );

    if (existingRes.rowCount > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_already_exists' });
    }

    const costs = BUILD_COSTS[building_type];

    // Check coins
    const stateRes = await client.query(
      `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );
    const coins = BigInt(stateRes.rows[0].coins);
    if (coins < costs.coins) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_coins' });
    }

    // Check all resource costs dynamically
    const resourceTypes = Object.keys(costs).filter(k => k !== 'coins');
    for (const resourceType of resourceTypes) {
      const required = costs[resourceType];
      if (required > 0n) {
        const resourceRes = await client.query(
          `SELECT amount FROM inventory WHERE user_id = $1 AND resource_type = $2 FOR UPDATE`,
          [userId, resourceType]
        );
        const have = resourceRes.rowCount ? BigInt(resourceRes.rows[0].amount) : 0n;
        if (have < required) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: `not_enough_${resourceType}` });
        }
      }
    }

    // Deduct costs
    await client.query(
      `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
      [userId, costs.coins.toString()]
    );

    for (const resourceType of resourceTypes) {
      const required = costs[resourceType];
      if (required > 0n) {
        await client.query(
          `UPDATE inventory SET amount = amount - $2 WHERE user_id = $1 AND resource_type = $3`,
          [userId, required.toString(), resourceType]
        );
      }
    }

    // Build the building
    await client.query(
      `INSERT INTO buildings(user_id, building_type, level) VALUES ($1, $2, 1)`,
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
// ============================================================================
// PRODUCTION SYSTEM (Alternative Implementation - Currently Not Used)
// ============================================================================
// NOTE: This is an alternative production system using production_queue table.
// The frontend currently uses /production/* endpoints (production.js) instead.
// This implementation uses production_queue for multi-job queuing.
// See KNOWN_ISSUES.md for details on the production system duplication.
// ============================================================================

// Production mechanics:
// - Well: 1 coin → 1 water in 3 seconds
// - Lumberjack: 1 coin + 1 water → 10 wood in 5 seconds
// - Sandgrube: 1 coin + 1 water → 2 sand in 5 seconds
// - Kalktagebau: 1 coin + 1 water → 2 limestone in 6 seconds
// - Steinfabrik: 2 coins + 2 sand → 3 stone_blocks in 8 seconds
// - Saegewerk: 1 coin + 5 wood → 8 wood_planks in 7 seconds
// - Zementwerk: 2 coins + 2 limestone + 1 sand → 4 cement in 10 seconds
// - Betonfabrik: 2 coins + 3 cement + 2 sand → 5 concrete in 12 seconds
const PRODUCTION_CONFIG = {
  well: { 
    costs: { coins: 1n, water: 0n }, 
    duration_seconds: 3, 
    output_type: 'water', 
    output_amount: 1n 
  },
  lumberjack: { 
    costs: { coins: 1n, water: 1n }, 
    duration_seconds: 5, 
    output_type: 'wood', 
    output_amount: 10n 
  },
  sandgrube: { 
    costs: { coins: 1n, water: 1n }, 
    duration_seconds: 5, 
    output_type: 'sand', 
    output_amount: 2n 
  },
  kalktagebau: { 
    costs: { coins: 1n, water: 1n }, 
    duration_seconds: 6, 
    output_type: 'limestone', 
    output_amount: 2n 
  },
  steinfabrik: { 
    costs: { coins: 2n, sand: 2n }, 
    duration_seconds: 8, 
    output_type: 'stone_blocks', 
    output_amount: 3n 
  },
  saegewerk: { 
    costs: { coins: 1n, wood: 5n }, 
    duration_seconds: 7, 
    output_type: 'wood_planks', 
    output_amount: 8n 
  },
  zementwerk: { 
    costs: { coins: 2n, limestone: 2n, sand: 1n }, 
    duration_seconds: 10, 
    output_type: 'cement', 
    output_amount: 4n 
  },
  betonfabrik: { 
    costs: { coins: 2n, cement: 3n, sand: 2n }, 
    duration_seconds: 12, 
    output_type: 'concrete', 
    output_amount: 5n 
  }
};

const productionStartSchema = z.object({
  building_type: z.enum(['well', 'lumberjack', 'sandgrube', 'kalktagebau', 'steinfabrik', 'saegewerk', 'zementwerk', 'betonfabrik']),
  quantity: z.number().int().positive().max(1000) // UI slider shows 1-100, but allow higher for flexibility
});

economyRouter.post('/production/start', authRequired, async (req, res) => {
  const parsed = productionStartSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type, quantity } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Check if building exists
    const buildingRes = await client.query(
      `SELECT id FROM buildings WHERE user_id = $1 AND building_type = $2`,
      [userId, building_type]
    );

    if (buildingRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'building_not_found' });
    }

    const config = PRODUCTION_CONFIG[building_type];
    const costs = config.costs;
    
    // Calculate total costs for all units
    const totalCosts = {};
    for (const [resource, cost] of Object.entries(costs)) {
      totalCosts[resource] = cost * BigInt(quantity);
    }

    // Check coins
    if (totalCosts.coins > 0n) {
      const stateRes = await client.query(
        `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
        [userId]
      );
      const coins = BigInt(stateRes.rows[0].coins);
      if (coins < totalCosts.coins) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'not_enough_coins' });
      }
    }

    // Check all resource costs dynamically
    const resourceTypes = Object.keys(costs).filter(k => k !== 'coins');
    for (const resourceType of resourceTypes) {
      const required = totalCosts[resourceType];
      if (required > 0n) {
        const resourceRes = await client.query(
          `SELECT amount FROM inventory WHERE user_id = $1 AND resource_type = $2 FOR UPDATE`,
          [userId, resourceType]
        );
        const have = resourceRes.rowCount ? BigInt(resourceRes.rows[0].amount) : 0n;
        if (have < required) {
          await client.query('ROLLBACK');
          return res.status(400).json({ error: `not_enough_${resourceType}` });
        }
      }
    }

    // Deduct coins
    if (totalCosts.coins > 0n) {
      await client.query(
        `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
        [userId, totalCosts.coins.toString()]
      );
    }

    // Deduct resources
    for (const resourceType of resourceTypes) {
      const required = totalCosts[resourceType];
      if (required > 0n) {
        await client.query(
          `UPDATE inventory SET amount = amount - $2 WHERE user_id = $1 AND resource_type = $3`,
          [userId, required.toString(), resourceType]
        );
      }
    }

    // Create production job
    // Total time = duration per unit * quantity
    const totalDuration = config.duration_seconds * quantity * 1000;
    const finishesAt = new Date(Date.now() + totalDuration);
    const prodRes = await client.query(
      `INSERT INTO production_queue(user_id, building_type, quantity, finishes_at)
       VALUES ($1, $2, $3, $4)
       RETURNING id, finishes_at`,
      [userId, building_type, quantity, finishesAt]
    );

    await client.query('COMMIT');
    return res.json({ 
      ok: true, 
      production_id: prodRes.rows[0].id,
      finishes_at: prodRes.rows[0].finishes_at
    });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

economyRouter.get('/production/status', authRequired, async (req, res) => {
  const userId = req.user.id;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Check for completed productions
    const completedRes = await client.query(
      `SELECT id, building_type, quantity FROM production_queue
       WHERE user_id = $1 AND status = 'in_progress' AND finishes_at <= now()
       FOR UPDATE`,
      [userId]
    );

    // Process completed productions
    for (const prod of completedRes.rows) {
      const config = PRODUCTION_CONFIG[prod.building_type];
      const totalOutput = config.output_amount * BigInt(prod.quantity);

      // Add output to inventory
      await client.query(
        `INSERT INTO inventory(user_id, resource_type, amount)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, resource_type)
         DO UPDATE SET amount = inventory.amount + EXCLUDED.amount`,
        [userId, config.output_type, totalOutput.toString()]
      );

      // Mark as completed
      await client.query(
        `UPDATE production_queue SET status = 'completed' WHERE id = $1`,
        [prod.id]
      );
    }

    // Get current in-progress productions
    const inProgressRes = await client.query(
      `SELECT id, building_type, quantity, started_at, finishes_at
       FROM production_queue
       WHERE user_id = $1 AND status = 'in_progress'
       ORDER BY finishes_at`,
      [userId]
    );

    await client.query('COMMIT');

    return res.json({
      in_progress: inProgressRes.rows.map(r => ({
        id: r.id,
        building_type: r.building_type,
        quantity: r.quantity,
        started_at: r.started_at,
        finishes_at: r.finishes_at
      }))
    });
  } catch {
    await client.query('ROLLBACK');
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});
