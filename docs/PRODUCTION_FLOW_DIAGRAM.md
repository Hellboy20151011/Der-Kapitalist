# Production System Flow Diagram

## User Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRODUCTION SYSTEM FLOW                       │
└─────────────────────────────────────────────────────────────────┘

1. START PRODUCTION
   ┌────────────┐
   │   Player   │
   └─────┬──────┘
         │ Selects quantity: 10 water
         │ Cost: 10 coins
         ▼
   ┌────────────────┐         ┌──────────────┐
   │  Godot Client  │────────▶│   Backend    │
   │   Main.gd      │  POST   │ /production/ │
   │                │  /start │    start     │
   └────────────────┘         └──────┬───────┘
                                     │
                              ┌──────▼───────────────────┐
                              │  1. Validate coins ≥ 10 │
                              │  2. Check building free   │
                              │  3. Deduct 10 coins       │
                              │  4. Set is_producing=true │
                              │  5. Set ready_at=now+30s  │
                              │  6. Set producing_qty=10  │
                              └──────────────────────────┘

2. PRODUCTION RUNNING (30 seconds)
   ┌────────────────┐
   │  Godot Client  │
   │   Polls every  │──┐
   │   5 seconds    │  │
   └────────────────┘  │
         ▲              │
         │              ▼
         │        ┌──────────────┐
         │        │   Backend    │
         └────────│   /state     │
           GET    │              │
                  └──────────────┘
   
   UI Shows: "Produziert... (25s)" ← countdown
   Button: Disabled
   Slider: Disabled

3. PRODUCTION READY
   ┌────────────────┐
   │  Godot Client  │
   │  Button text:  │
   │   "Abholen"    │ ← changes automatically
   │  Enabled!      │
   └────────────────┘

4. COLLECT PRODUCTION
   ┌────────────────┐         ┌──────────────┐
   │  Godot Client  │────────▶│   Backend    │
   │  Player clicks │  POST   │ /production/ │
   │   "Abholen"    │ /collect│   collect    │
   └────────────────┘         └──────┬───────┘
                                     │
                              ┌──────▼───────────────────┐
                              │  1. Check ready_at ≤ now │
                              │  2. Add 10 water to inv  │
                              │  3. Reset is_producing   │
                              │  4. Clear ready_at       │
                              │  5. Clear producing_qty  │
                              └──────────────────────────┘
         ▲
         │ Response: +10 water
         │
   ┌────▼───────────┐
   │  Inventory     │
   │  Water: +10    │
   │  Coins: -10    │
   └────────────────┘

   → Button returns to "Produzieren"
   → Slider enabled again
   → Player can start new production

```

## Database State Changes

```
BUILDINGS TABLE:

BEFORE START:
┌────────┬──────────┬───────┬──────────────┬──────────┬───────────────┐
│ user_id│   type   │ level │ is_producing │ ready_at │ producing_qty │
├────────┼──────────┼───────┼──────────────┼──────────┼───────────────┤
│  abc   │   well   │   1   │    false     │   NULL   │     NULL      │
└────────┴──────────┴───────┴──────────────┴──────────┴───────────────┘

AFTER START (10 units):
┌────────┬──────────┬───────┬──────────────┬──────────────────────┬───────────────┐
│ user_id│   type   │ level │ is_producing │      ready_at        │ producing_qty │
├────────┼──────────┼───────┼──────────────┼──────────────────────┼───────────────┤
│  abc   │   well   │   1   │     true     │ 2026-01-04 12:00:30Z │      10       │
└────────┴──────────┴───────┴──────────────┴──────────────────────┴───────────────┘
                                              ↑ now + 30 seconds

AFTER COLLECT:
┌────────┬──────────┬───────┬──────────────┬──────────┬───────────────┐
│ user_id│   type   │ level │ is_producing │ ready_at │ producing_qty │
├────────┼──────────┼───────┼──────────────┼──────────┼───────────────┤
│  abc   │   well   │   1   │    false     │   NULL   │     NULL      │
└────────┴──────────┴───────┴──────────────┴──────────┴───────────────┘
```

## Error Handling

```
START PRODUCTION ERRORS:
├─ building_not_found     → Player doesn't own this building
├─ building_busy          → Building is already producing
└─ not_enough_coins       → Insufficient coins for quantity

COLLECT PRODUCTION ERRORS:
├─ building_not_found     → Player doesn't own this building
├─ nothing_to_collect     → Building is not producing
├─ not_ready_yet          → Production timer not finished
└─ invalid_production_qty → Data corruption (qty ≤ 0)
```

## API Examples

### Start Production
```bash
curl -X POST http://localhost:3000/production/start \
  -H 'Authorization: Bearer eyJ...' \
  -H 'Content-Type: application/json' \
  -d '{
    "building_type": "well",
    "quantity": 10
  }'

# Success Response:
{
  "ok": true,
  "building_type": "well",
  "quantity": "10",
  "cost": "10",
  "ready_at": "2026-01-04T12:00:30.000Z"
}
```

### Collect Production
```bash
curl -X POST http://localhost:3000/production/collect \
  -H 'Authorization: Bearer eyJ...' \
  -H 'Content-Type: application/json' \
  -d '{
    "building_type": "well"
  }'

# Success Response:
{
  "ok": true,
  "building_type": "well",
  "quantity": "10",
  "resource": "water"
}
```

### Check State
```bash
curl http://localhost:3000/state \
  -H 'Authorization: Bearer eyJ...'

# Response includes:
{
  "coins": "90",
  "inventory": {
    "water": "10"
  },
  "buildings": [
    {
      "type": "well",
      "level": 1,
      "is_producing": false,
      "ready_at": null,
      "producing_qty": null
    }
  ]
}
```
