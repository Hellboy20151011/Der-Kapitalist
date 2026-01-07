// ============================================================================
// ECONOMY ROUTER - Building Construction, Upgrades, and Sales
// ============================================================================
// FILE SIZE: 333 lines (reduced from 504 lines)
// 
// MODULARITY ASSESSMENT:
// This file handles economy-related subsystems:
// 1. Resource selling (/sell) - ~50 lines
// 2. Building upgrades (/buildings/upgrade) - ~60 lines
// 3. Building construction (/buildings/build) - ~100 lines
// 
// PHASE 1 REFACTORING COMPLETE (2026-01-07):
// ✅ Removed duplicate production system (~280 lines)
// - Eliminated confusion about which production system is active
// - Reduced technical debt and maintenance burden
// - Frontend continues using /production/* endpoints (production.js)
// 
// REMAINING IMPROVEMENTS (Optional):
// 1. Extract shared logic to services:
//    - buildingService.js (building operations, cost calculations)
//    - inventoryService.js (resource checks, updates)
//    - transactionService.js (atomic coin/resource transfers)
// 2. This would reduce file size to ~200 lines and improve testability
// ============================================================================

import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';
import { RESOURCE_TYPES, BUILDING_TYPES } from '../constants.js';

export const economyRouter = express.Router();

// ============================================================================
// RESOURCE SELLING ENDPOINT
// ============================================================================
// MODULARITY: This endpoint is well-contained (~50 lines)
// Could be extracted to sellService.js if economy router gets split
// ============================================================================

const SELL_PRICES = { 
  strom: 1.1,
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
  resource_type: z.enum(RESOURCE_TYPES),
  quantity: z.number().int().positive().max(1_000_000)
});

economyRouter.post('/sell', authRequired, async (req, res) => {
  const parsed = sellSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { resource_type, quantity } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('SET statement_timeout = 10000');
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
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Resource sell error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

// ============================================================================
// BUILDING UPGRADE SYSTEM
// ============================================================================
// MODULARITY: Upgrade logic is straightforward but tightly coupled to economy
// Consider: buildingService.js with upgradeBuilding(userId, buildingType)
// This would encapsulate cost calculation and make it reusable
// ============================================================================

const upgradeSchema = z.object({
  building_type: z.enum(BUILDING_TYPES)
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
    await client.query('SET statement_timeout = 10000');
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
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Building upgrade error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

// ============================================================================
// BUILDING CONSTRUCTION SYSTEM
// ============================================================================
// MODULARITY NOTE: This is a complex endpoint (~100 lines) with:
// - Dynamic resource cost validation
// - Multi-resource transactions
// - Cost configuration management
// 
// SUGGESTED REFACTORING:
// Extract to buildingService.js:
//   - validateBuildingCosts(userId, buildingType, costs)
//   - deductBuildingCosts(client, userId, costs)
//   - constructBuilding(userId, buildingType)
// This would make the endpoint handler much simpler and more testable
// ============================================================================

// Building costs for construction (not upgrades)
const BUILD_COSTS = {
  kraftwerk: { coins: 10n },
  well: { coins: 20n },
  lumberjack: { coins: 50n },
  sandgrube: { coins: 45n },
  kalktagebau: { coins: 50n, wood: 20n, stone: 30n },
  steinfabrik: { coins: 100n, wood: 30n, sand: 50n },
  saegewerk: { coins: 75n, wood: 40n, stone: 20n },
  zementwerk: { coins: 150n, wood: 30n, sand: 40n, limestone: 40n },
  betonfabrik: { coins: 200n, wood: 40n, cement: 30n, sand: 60n }
};

const buildSchema = z.object({
  building_type: z.enum(BUILDING_TYPES)
});

economyRouter.post('/buildings/build', authRequired, async (req, res) => {
  const parsed = buildSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { building_type } = parsed.data;

  const client = await pool.connect();
  try {
    await client.query('SET statement_timeout = 10000');
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
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Building construction error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

// ============================================================================
// DUPLICATE PRODUCTION SYSTEM REMOVED - Phase 1 of Refactoring
// ============================================================================
// The duplicate queue-based production system has been removed (was lines 315-597).
// 
// DECISION: Removed Option A from assessment
// - Simplified codebase by removing ~280 lines of unused code
// - Eliminated confusion about which production system is active
// - Frontend continues to use /production/* endpoints (production.js)
// - Active system uses buildings.is_producing, ready_at, producing_qty columns
// 
// CLEANUP NEEDED:
// - production_queue table can be dropped from database if it exists
// - Migration script may be needed if table contains data
// 
// See: docs/MODULARITY_ASSESSMENT.md for rationale
// Completed: Phase 1 of refactoring roadmap (2026-01-07)
// ============================================================================
