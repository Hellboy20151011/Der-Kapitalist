// ============================================================================
// MARKET ROUTER - Trading System Implementation
// ============================================================================
// FILE SIZE: 251 lines
// 
// MODULARITY ASSESSMENT:
// This file handles the market/trading system with 3 main endpoints:
// 1. GET /listings - View available market listings (~50 lines)
// 2. POST /listings - Create new listing (~70 lines)
// 3. POST /listings/:id/buy - Purchase listing (~130 lines)
// 
// OVERALL: Well-structured and focused on a single domain (market)
// 
// STRENGTHS:
// - Clear separation of concerns (one file = one feature)
// - Each endpoint is reasonably sized
// - Good use of service layer (marketService.js)
// - Proper transaction handling with rollbacks
// 
// MINOR IMPROVEMENTS POSSIBLE:
// 1. Extract transaction logic to separate service:
//    - marketTransactionService.js for buy/sell operations
//    - Would make testing easier and reduce duplication
// 2. Consider breaking into:
//    - marketListingRouter.js (view, create listings)
//    - marketTransactionRouter.js (buy/sell operations)
// 
// CURRENT STATE: Acceptable modularity, no urgent refactoring needed
// File size is manageable and code is readable
// ============================================================================

import express from 'express';
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';
import { MARKET, countActiveListings } from '../services/marketService.js';
import { RESOURCE_TYPES } from '../constants.js';
import { broadcastToSubscribers, emitToUser } from '../utils/socketHelper.js';

export const marketRouter = express.Router();

const createSchema = z.object({
  resource_type: z.enum(RESOURCE_TYPES),
  quantity: z.number().int().positive().max(1_000_000),
  price_per_unit: z.number().int().positive().max(1_000_000_000)
});

// ============================================================================
// GET /listings - View Market Listings
// ============================================================================
// MODULARITY: Clean and focused endpoint
// Query parameters allow filtering by resource type
// ============================================================================

marketRouter.get('/listings', authRequired, async (req, res) => {
  const resourceType = req.query.resource_type;
  // Validate limit is a safe positive integer
  const limitParam = Number(req.query.limit ?? 50);
  const limit = Math.min(Math.max(1, Math.floor(limitParam)), 200);

  const params = [];
  let where = `WHERE status = 'active' AND expires_at > now()`;

  if (resourceType && RESOURCE_TYPES.includes(resourceType)) {
    params.push(resourceType);
    where += ` AND resource_type = $${params.length}`;
  }

  const q = `
    SELECT id, resource_type, quantity, price_per_unit, fee_percent, created_at, expires_at
    FROM market_listings
    ${where}
    ORDER BY price_per_unit ASC, created_at ASC
    LIMIT ${limit}
  `;

  const r = await pool.query(q, params);

  // BigInt-safe response: quantity/price als String
  const listings = r.rows.map(row => ({
    id: row.id,
    resource_type: row.resource_type,
    quantity: String(row.quantity),
    price_per_unit: String(row.price_per_unit),
    fee_percent: row.fee_percent,
    created_at: row.created_at,
    expires_at: row.expires_at
  }));

  return res.json({ listings });
});

// ============================================================================
// POST /listings - Create Market Listing
// ============================================================================
// MODULARITY: Reasonable size (~70 lines) with clear transaction handling
// Uses marketService.js for business logic (listing limits)
// ============================================================================

marketRouter.post('/listings', authRequired, async (req, res) => {
  const parsed = createSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });

  const userId = req.user.id;
  const { resource_type, quantity, price_per_unit } = parsed.data;

  const client = await pool.connect();
  try {
    // Set statement timeout to prevent long-running transactions (10 seconds)
    await client.query('SET statement_timeout = 10000');
    await client.query('BEGIN');

    // Idle production removed: buildings no longer produce automatically over time

    // Limit aktive Listings
    const activeCount = await countActiveListings(client, userId);
    if (activeCount >= MARKET.maxActiveListingsPerUser) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'too_many_active_listings' });
    }

    // Inventar locken und abbuchen (Reservierung = sofort abziehen)
    const inv = await client.query(
      `SELECT amount FROM inventory
       WHERE user_id = $1 AND resource_type = $2
       FOR UPDATE`,
      [userId, resource_type]
    );

    const have = inv.rowCount ? BigInt(inv.rows[0].amount) : 0n;
    const qty = BigInt(quantity);

    if (have < qty) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_resources' });
    }

    await client.query(
      `UPDATE inventory
       SET amount = amount - $3
       WHERE user_id = $1 AND resource_type = $2`,
      [userId, resource_type, qty.toString()]
    );

    // Listing erstellen
    const ins = await client.query(
      `INSERT INTO market_listings
       (seller_user_id, resource_type, quantity, price_per_unit, fee_percent, status, expires_at)
       VALUES ($1, $2, $3, $4, $5, 'active', now() + interval '24 hours')
       RETURNING id, expires_at`,
      [userId, resource_type, qty.toString(), BigInt(price_per_unit).toString(), MARKET.feePercent]
    );

    await client.query('COMMIT');
    
    // Emit WebSocket event for new listing
    broadcastToSubscribers('market', 'market:new-listing', {
      id: ins.rows[0].id,
      resource_type,
      quantity: qty.toString(),
      price_per_unit: BigInt(price_per_unit).toString(),
      fee_percent: MARKET.feePercent,
      expires_at: ins.rows[0].expires_at
    });
    
    return res.json({
      ok: true,
      id: ins.rows[0].id,
      expires_at: ins.rows[0].expires_at
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Market listing creation error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});

// ============================================================================
// POST /listings/:id/buy - Purchase Market Listing
// ============================================================================
// MODULARITY NOTE: This is the largest endpoint in the file (~130 lines)
// Handles complex transaction logic:
// - Listing validation and locking
// - Buyer coin validation
// - Coin transfer with marketplace fee
// - Resource transfer
// - Listing status update
// 
// POTENTIAL REFACTORING:
// Extract to marketTransactionService.js:
//   - validateListingForPurchase(listingId, buyerId)
//   - calculateTransactionAmounts(listing)
//   - executeMarketPurchase(client, listing, buyerId)
// 
// This would reduce endpoint to ~40 lines and improve testability
// ============================================================================

const buySchema = z.object({
  // MVP: ganzes Listing kaufen -> quantity optional, aber wir ignorieren es
});

marketRouter.post('/listings/:id/buy', authRequired, async (req, res) => {
  // Body optional, MVP whole-buy
  buySchema.safeParse(req.body ?? {});

  const userId = req.user.id;
  const listingId = req.params.id;
  
  // Validate listing ID is a positive integer
  const listingIdNum = parseInt(listingId, 10);
  if (isNaN(listingIdNum) || listingIdNum <= 0) {
    return res.status(400).json({ error: 'invalid_listing_id' });
  }

  const client = await pool.connect();
  try {
    // Set statement timeout to prevent long-running transactions (10 seconds)
    await client.query('SET statement_timeout = 10000');
    await client.query('BEGIN');

    // Idle production removed: buildings no longer produce automatically over time

    // Listing locken
    const lRes = await client.query(
      `SELECT id, seller_user_id, resource_type, quantity, price_per_unit, fee_percent, status, expires_at
       FROM market_listings
       WHERE id = $1
       FOR UPDATE`,
      [listingIdNum]
    );

    if (lRes.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'listing_not_found' });
    }

    const listing = lRes.rows[0];

    if (listing.status !== 'active') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'listing_not_active' });
    }

    if (new Date(listing.expires_at).getTime() <= Date.now()) {
      // Ablauf -> als expired markieren und abbrechen
      await client.query(`UPDATE market_listings SET status = 'expired' WHERE id = $1`, [listingIdNum]);
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'listing_expired' });
    }

    if (listing.seller_user_id === userId) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'cannot_buy_own_listing' });
    }

    const qty = BigInt(listing.quantity);
    const pricePerUnit = BigInt(listing.price_per_unit);

    // Check for potential overflow in multiplication
    // Max safe BigInt is implementation-dependent, but we can validate against reasonable business limits
    const MAX_COINS = BigInt('9223372036854775807'); // Max int64
    const total = qty * pricePerUnit;
    
    if (total > MAX_COINS) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'transaction_amount_too_large' });
    }
    const feePercent = BigInt(listing.fee_percent);
    const fee = (total * feePercent) / 100n;
    const payout = total - fee;

    // Käufer-Coins locken
    const buyerState = await client.query(
      `SELECT coins FROM player_state WHERE user_id = $1 FOR UPDATE`,
      [userId]
    );
    const buyerCoins = BigInt(buyerState.rows[0].coins);

    if (buyerCoins < total) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'not_enough_coins' });
    }

    // Coins transferieren
    await client.query(
      `UPDATE player_state SET coins = coins - $2 WHERE user_id = $1`,
      [userId, total.toString()]
    );

    await client.query(
      `UPDATE player_state SET coins = coins + $2 WHERE user_id = $1`,
      [listing.seller_user_id, payout.toString()]
    );

    // Käufer bekommt Ressource
    await client.query(
      `INSERT INTO inventory(user_id, resource_type, amount)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, resource_type)
       DO UPDATE SET amount = inventory.amount + EXCLUDED.amount`,
      [userId, listing.resource_type, qty.toString()]
    );

    // Listing auf sold setzen
    await client.query(
      `UPDATE market_listings SET status = 'sold' WHERE id = $1`,
      [listingIdNum]
    );

    await client.query('COMMIT');
    
    // Emit WebSocket events for listing sold
    // Notify seller
    emitToUser(listing.seller_user_id, 'market:listing-sold', {
      listing_id: listingIdNum,
      resource_type: listing.resource_type,
      quantity: qty.toString(),
      total: payout.toString(),
      fee: fee.toString()
    });
    
    // Notify buyer with state update
    emitToUser(userId, 'state:update', {
      type: 'market_purchase',
      coins_spent: total.toString()
    });
    
    return res.json({
      ok: true,
      bought: {
        resource_type: listing.resource_type,
        quantity: qty.toString(),
        total: total.toString(),
        fee: fee.toString()
      }
    });
  } catch (e) {
    await client.query('ROLLBACK');
    console.error('Market listing purchase error:', e);
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});