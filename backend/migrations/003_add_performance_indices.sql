-- Migration: Add performance indices for common queries
-- Date: 2026-01-04

-- Add index for inventory lookups by user_id
CREATE INDEX IF NOT EXISTS idx_inventory_user ON inventory(user_id);

-- Add index for buildings lookups by user_id
CREATE INDEX IF NOT EXISTS idx_buildings_user ON buildings(user_id);

-- Add index for player_state lookups (already primary key, but explicit for clarity)
-- CREATE INDEX IF NOT EXISTS idx_player_state_user ON player_state(user_id); -- Not needed, PRIMARY KEY

-- Add index for market_listings by seller
CREATE INDEX IF NOT EXISTS idx_market_seller ON market_listings(seller_user_id);

-- Add index for production_queue by user and status
-- Already exists: idx_production_user ON production_queue(user_id, status)

-- Add constraints to prevent negative values
-- Note: coins >= 0 allows zero coins, which is valid when a player spends all coins
-- Players can still perform free actions and earn more coins through gameplay
ALTER TABLE player_state
ADD CONSTRAINT IF NOT EXISTS chk_coins_non_negative CHECK (coins >= 0);

ALTER TABLE inventory
ADD CONSTRAINT IF NOT EXISTS chk_amount_non_negative CHECK (amount >= 0);

ALTER TABLE buildings
ADD CONSTRAINT IF NOT EXISTS chk_level_positive CHECK (level > 0);

ALTER TABLE market_listings
ADD CONSTRAINT IF NOT EXISTS chk_quantity_positive CHECK (quantity > 0),
ADD CONSTRAINT IF NOT EXISTS chk_price_positive CHECK (price_per_unit > 0);

ALTER TABLE production_queue
ADD CONSTRAINT IF NOT EXISTS chk_production_quantity_positive CHECK (quantity > 0);
