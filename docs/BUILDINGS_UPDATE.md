# Buildings and Production System Update

## Overview
This document describes the implementation of the new building and production system as requested in the issue "Gebäude und Produktion".

## Changes Summary

### New Resource Type: Strom (Electricity)
- Added `strom` as a new resource type throughout the system
- Electricity can be produced, stored, traded, and used in production chains

### Building Updates

#### 1. Kraftwerk (Power Plant) - NEW
- **Build Cost**: 10 coins
- **Production**: 1 electricity for 0.2 coins in 0.3 seconds
- **Purpose**: Primary electricity producer, foundation of the production chain

#### 2. Brunnen (Well) - UPDATED
- **Build Cost**: 20 coins (changed from previous cost)
- **Production**: 1 water for 0.5 electricity in 0.5 seconds
- **Change**: Now requires electricity instead of coins for production

#### 3. Holzfäller (Lumberjack) - UPDATED
- **Build Cost**: 50 coins (changed from previous cost)
- **Production**: 2 wood for 0.1 electricity + 0.2 water in 5 seconds
- **Change**: Now requires electricity and water instead of just coins

#### 4. Sandgrube (Sand Pit) - UPDATED
- **Build Cost**: 45 coins (changed from previous cost)
- **Production**: 1.2 sand for 0.3 electricity + 0.1 water in 3.2 seconds
- **Change**: Now produces sand (not stone), requires electricity and water

## Technical Implementation

### Database Storage
All values are stored as `bigint` in the database, multiplied by 10 to preserve one decimal place:
- 1.0 is stored as 10
- 0.2 is stored as 2
- 1.2 is stored as 12

This approach ensures precision while working with integer database types.

### Production Configuration
Located in `backend/src/routes/production.js`:
```javascript
const CONFIG = {
  kraftwerk: { 
    resource: 'strom', 
    output_per_unit: 10,  // 1.0 electricity
    seconds_per_unit: 0.3, 
    costs: { coins: 2 }  // 0.2 coins
  },
  well: { 
    resource: 'water', 
    output_per_unit: 10,  // 1.0 water
    seconds_per_unit: 0.5, 
    costs: { strom: 5 }  // 0.5 electricity
  },
  lumberjack: { 
    resource: 'wood', 
    output_per_unit: 20,  // 2.0 wood
    seconds_per_unit: 5, 
    costs: { strom: 1, water: 2 }  // 0.1 electricity, 0.2 water
  },
  sandgrube: { 
    resource: 'sand', 
    output_per_unit: 12,  // 1.2 sand
    seconds_per_unit: 3.2, 
    costs: { strom: 3, water: 1 }  // 0.3 electricity, 0.1 water
  }
};
```

### Files Modified

#### Backend Core Files
1. **`backend/src/constants.js`**
   - Added `strom` to RESOURCE_TYPES
   - Added `kraftwerk` to BUILDING_TYPES
   - Updated BUILD_COSTS for all 4 buildings
   - Updated BUILDING_RESOURCES mapping
   - Updated SELL_PRICES to include electricity
   - Changed STARTING_BUILDINGS to just `['kraftwerk']`

2. **`backend/src/routes/production.js`**
   - Completely rewrote CONFIG with new buildings and costs
   - Updated validation schemas to include kraftwerk
   - Rewrote production start logic to handle multiple resource types as costs
   - Implemented proper precision handling for decimal values

3. **`backend/src/routes/economy.js`**
   - Updated BUILD_COSTS for all 4 buildings
   - Updated SELL_PRICES to include electricity
   - Updated validation schemas to include kraftwerk

4. **`backend/src/routes/state.js`**
   - Updated BUILDING_RESOURCES mapping to include kraftwerk and correct sandgrube output

5. **`backend/src/routes/auth.js`**
   - Updated new player initialization to include all resource types
   - Changed starting building to kraftwerk only

6. **`backend/src/routes/dev.js`**
   - Updated account reset to use kraftwerk as starting building

7. **`backend/src/routes/market.js`**
   - Updated resource validation to include electricity and all resource types

## Production Chain Flow

The new production chain creates dependencies:

1. **Coins** → **Kraftwerk** → **Electricity**
2. **Electricity** → **Well** → **Water**
3. **Electricity + Water** → **Lumberjack** → **Wood**
4. **Electricity + Water** → **Sandgrube** → **Sand**

This creates a progression where players must:
1. Start with Kraftwerk to produce electricity
2. Build Well to produce water (requires electricity)
3. Build Lumberjack and Sandgrube (both require electricity and water)

## Starting Configuration

New players now start with:
- 100 coins
- 1 Kraftwerk (Power Plant)
- All resource types initialized to 0

This ensures players can immediately start producing electricity, which is needed for all other buildings.

## Variable Production

All production is variable via slider/input field in the UI:
- Players can specify quantity (1-1,000,000 units)
- Costs are multiplied by quantity
- Production time is multiplied by quantity
- Output is multiplied by quantity

## API Endpoints

### Production Start
```
POST /production/start
{
  "building_type": "kraftwerk",
  "quantity": 10
}
```

### Production Collect
```
POST /production/collect
{
  "building_type": "kraftwerk"
}
```

## Testing Notes

To test the new system:
1. Start the backend server
2. Register a new account (will have kraftwerk automatically)
3. Start production on kraftwerk with some quantity
4. Wait for production to complete
5. Collect the electricity
6. Build a well
7. Use electricity to produce water
8. Build lumberjack/sandgrube
9. Use electricity and water to produce wood/sand

## Compatibility Notes

- All existing endpoints remain compatible
- The precision scheme (multiply by 10) is transparent to API consumers
- Values are returned as strings to prevent JavaScript BigInt issues
- The system properly handles decimal values in production costs and outputs

## Future Enhancements

Possible future improvements:
1. Add more complex buildings that use electricity
2. Implement electricity storage/battery mechanics
3. Add production efficiency upgrades
4. Implement multi-step production chains
5. Add production automation options
