CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_state (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  coins bigint NOT NULL DEFAULT 0,
  last_tick_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  resource_type text NOT NULL,
  amount bigint NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, resource_type)
);

CREATE TABLE IF NOT EXISTS buildings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  building_type text NOT NULL,
  level int NOT NULL DEFAULT 1,
  UNIQUE (user_id, building_type)
);

CREATE TABLE IF NOT EXISTS market_listings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  resource_type text NOT NULL,
  quantity bigint NOT NULL,
  price_per_unit bigint NOT NULL,
  fee_percent int NOT NULL DEFAULT 7,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '24 hours')
);

CREATE INDEX IF NOT EXISTS idx_market_active ON market_listings(status, resource_type, price_per_unit);