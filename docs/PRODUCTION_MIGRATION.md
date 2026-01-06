# Production System Migration Guide

This guide explains how to apply the production system migration to add click-based production to buildings.

## Database Migration

The migration adds three columns to the `buildings` table to track production state:
- `is_producing` (boolean): Whether the building is currently producing
- `ready_at` (timestamptz): When the production will be ready to collect
- `producing_qty` (bigint): How many units are being produced

### How to Apply

Connect to your PostgreSQL database and run:

```bash
psql -U <username> -d der_kapitalist -f backend/migrations/002_add_building_production_columns.sql
```

Or run the SQL directly:

```sql
ALTER TABLE buildings
ADD COLUMN IF NOT EXISTS is_producing boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS ready_at timestamptz NULL,
ADD COLUMN IF NOT EXISTS producing_qty bigint NULL;
```

## API Changes

### New Endpoints

**POST /production/start**
- Start production in a building
- Request body: `{ "building_type": "well", "quantity": 10 }`
- Response: `{ "ok": true, "building_type": "well", "quantity": "10", "cost": "10", "ready_at": "2026-01-04T12:00:00Z" }`

**POST /production/collect**
- Collect finished production from a building
- Request body: `{ "building_type": "well" }`
- Response: `{ "ok": true, "building_type": "well", "quantity": "10", "resource": "water" }`

### Modified Endpoints

**GET /state**
- Now returns production status for each building:
```json
{
  "buildings": [
    {
      "type": "well",
      "level": 1,
      "is_producing": true,
      "ready_at": "2026-01-04T12:00:00Z",
      "producing_qty": "10"
    }
  ]
}
```

## Production Configuration

Currently only the well is configured:
- **Well**: 1 coin → 1 water in 3 seconds per unit

To add more buildings, update the `CONFIG` object in `backend/src/routes/production.js`:

```javascript
const CONFIG = {
  well: { resource: 'water', seconds_per_unit: 3, coin_cost_per_unit: 1n },
  lumberjack: { resource: 'wood', seconds_per_unit: 5, coin_cost_per_unit: 2n },
  // Add more buildings here...
};
```

Also update the Zod schemas to include the new building types:
```javascript
const startSchema = z.object({
  building_type: z.enum(['well', 'lumberjack', /* ... */]),
  quantity: z.number().int().positive().max(1_000_000)
});
```

## Client Changes

The Godot client now:
1. Tracks production state for each building
2. Shows countdown timers on production buttons
3. Automatically changes button text from "Produzieren" to "Abholen" when ready
4. Polls every 5 seconds to update UI when production is active

## Testing

1. Apply the database migration
2. Start the backend server: `cd backend && npm start`
3. Build a well using the existing `/economy/buildings/build` endpoint
4. Start production: `POST /production/start` with `{"building_type": "well", "quantity": 1}`
5. Wait 3 seconds
6. Collect: `POST /production/collect` with `{"building_type": "well"}`
7. Check your inventory - you should have +1 water
