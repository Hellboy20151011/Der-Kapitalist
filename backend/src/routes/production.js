// ============================================================================
// PRODUCTION ROUTER - Active Production System
// ============================================================================
// FILE SIZE: 239 lines
// 
// MODULARITY ASSESSMENT:
// This is the ACTIVE production system used by the frontend (Main.gd)
// Implements production using buildings.is_producing, ready_at columns
// 
// STRUCTURE:
// 1. Configuration (CONFIG object) - Production recipes (~45 lines)
// 2. POST /start - Start production (~110 lines)
// 3. POST /collect - Collect finished production (~80 lines)
// 
// STRENGTHS:
// - Focused on single responsibility (production management)
// - Clear separation between start and collect operations
// - Good configuration-driven design
// - Reasonable file size
// 
// MODULARITY CONCERNS:
// 1. Large CONFIG object could be extracted to constants.js or config file
// 2. Resource validation logic is repeated between start and collect
// 3. Transaction handling could be extracted to service layer
// 
// SUGGESTED IMPROVEMENTS:
// - Extract to productionService.js:
//   - validateProductionCosts(userId, buildingType, quantity)
//   - deductProductionCosts(client, userId, costs)
//   - startProduction(client, userId, buildingType, quantity)
//   - collectProduction(client, userId, buildingType)
// - Move CONFIG to constants.js for consistency
// 
// NOTE: There is a DUPLICATE production system in economy.js (lines 250-504)
// that uses production_queue table. See economy.js comments for details.
// The duplicate system should be removed to avoid confusion.
// ============================================================================

import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';

export const productionRouter = express.Router();

/**
 * Production Configuration
 * Note: All costs and outputs are stored in database as bigint (multiplied by 10 to preserve 1 decimal)
 * Example: 0.2 coins is stored as 2, 1.2 sand is stored as 12
 * 
 * kraftwerk: 1 strom for 0.2 coins in 0.3s
 * well: 1 water for 0.5 strom in 0.5s
 * lumberjack: 2 wood for 0.1 strom + 0.2 water in 5s
 * sandgrube: 1.2 sand for 0.3 strom + 0.1 water in 3.2s
 * 
 * MODULARITY NOTE: This configuration object could be moved to:
 * - backend/src/config/productionConfig.js
 * - backend/src/constants.js (with other game configs)
 * This would centralize all game balance and make it easier to maintain
 */
const CONFIG = {
  kraftwerk: { 
    resource: 'strom', 
    output_per_unit: 10,  // 1.0 stored as 10
    seconds_per_unit: 0.3, 
    costs: { coins: 2 }  // 0.2 stored as 2
  },
  well: { 
    resource: 'water', 
    output_per_unit: 10,  // 1.0 stored as 10
    seconds_per_unit: 0.5, 
    costs: { strom: 5 }  // 0.5 stored as 5
  },
  lumberjack: { 
    resource: 'wood', 
    output_per_unit: 20,  // 2.0 stored as 20
    seconds_per_unit: 5, 
    costs: { strom: 1, water: 2 }  // 0.1 -> 1, 0.2 -> 2
  },
  sandgrube: { 
    resource: 'sand', 
    output_per_unit: 12,  // 1.2 stored as 12
    seconds_per_unit: 3.2, 
    costs: { strom: 3, water: 1 }  // 0.3 -> 3, 0.1 -> 1
  }
};

const startSchema = z.object({
  building_type: z.enum(['kraftwerk', 'well', 'lumberjack', 'sandgrube']),
  quantity: z.number().int().positive().max(1_000_000)
});

// ============================================================================
// POST /start - Start Production
// ============================================================================
// MODULARITY: ~110 lines handling production initiation
// Contains complex resource validation and deduction logic
// 
// POTENTIAL REFACTORING:
// This endpoint could be split into helper functions:
// - _validateBuildingAvailable(client, userId, buildingType)
// - _deductProductionCosts(client, userId, costs)
// - _calculateProductionTime(quantity, config)
// - _startBuildingProduction(client, userId, buildingType, output, seconds)
// 
// This would improve readability and testability
// ============================================================================

productionRouter.post('/start', authRequired, async (req, res) => {
  const parsed = startSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type, quantity } = parsed.data;

  const cfg = CONFIG[building_type];
  
  // Calculate total costs (all values are already scaled by 10)
  const totalCosts = {};
  for (const [costType, costPerUnit] of Object.entries(cfg.costs)) {
    totalCosts[costType] = BigInt(costPerUnit * quantity);
  }

  const client = await pool.connect();
  try {
    // Set statement timeout to prevent long-running transactions
    await client.query('SET statement_timeout = 10000');
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

    // Lock player state for coins
    const sRes = await client.query(
      `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );

    // Check and deduct coins if needed
    if (totalCosts.coins) {
      const coins = BigInt(sRes.rows[0].coins);
      if (coins < totalCosts.coins) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'not_enough_coins' });
      }
      await client.query(
        `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
        [userId, totalCosts.coins.toString()]
      );
    }

    // Check and deduct resources (strom, water, etc.)
    for (const [resourceType, cost] of Object.entries(totalCosts)) {
      if (resourceType === 'coins') continue; // Already handled
      
      const resourceRes = await client.query(
        `SELECT amount FROM inventory WHERE user_id = $1 AND resource_type = $2 FOR UPDATE`,
        [userId, resourceType]
      );
      
      const have = resourceRes.rowCount ? BigInt(resourceRes.rows[0].amount) : 0n;
      if (have < cost) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: `not_enough_${resourceType}` });
      }
      
      // Deduct resource
      await client.query(
        `UPDATE inventory SET amount = amount - $3 WHERE user_id = $1 AND resource_type = $2`,
        [userId, resourceType, cost.toString()]
      );
    }

    // Calculate total production time and output
    const seconds = quantity * cfg.seconds_per_unit;
    const totalOutput = BigInt(cfg.output_per_unit * quantity);
    
    const readyAtRes = await client.query(
      `UPDATE buildings
       SET is_producing = true,
           producing_qty = $3,
           ready_at = now() + ($2 || ' seconds')::interval
       WHERE user_id = $1 AND building_type = $4
       RETURNING ready_at`,
      [userId, String(seconds), totalOutput.toString(), building_type]
    );

    await client.query('COMMIT');

    return res.json({
      ok: true,
      building_type,
      quantity,
      ready_at: readyAtRes.rows[0].ready_at
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Production start error:', err);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

const collectSchema = z.object({
  building_type: z.enum(['kraftwerk', 'well', 'lumberjack', 'sandgrube'])
});

// ============================================================================
// POST /collect - Collect Finished Production
// ============================================================================
// MODULARITY: ~80 lines handling production completion
// Validates timing and credits resources to inventory
// 
// GOOD PRACTICES:
// - Clear validation of production state
// - Atomic transaction handling
// - Proper error messages for different failure cases
// ============================================================================

productionRouter.post('/collect', authRequired, async (req, res) => {
  const parsed = collectSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type } = parsed.data;
  const cfg = CONFIG[building_type];

  const client = await pool.connect();
  try {
    // Set statement timeout to prevent long-running transactions
    await client.query('SET statement_timeout = 10000');
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
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Production collect error:', err);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});
