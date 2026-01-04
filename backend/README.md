# Der-Kapitalist Backend

Backend API server for Der-Kapitalist mobile game.

## Prerequisites

- Node.js 18+ 
- PostgreSQL 14+

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

3. Update `.env` with your database credentials and JWT secret.

4. Initialize the database using the schema in `../DB_Schema.md`:
```bash
# The DB_Schema.md file contains pure SQL and can be executed directly
psql -U your_user -d your_database < ../DB_Schema.md
```

## Running the Server

### Development Mode
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

The server will start on `http://localhost:3000` by default.

## API Endpoints

### Authentication
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login with email and password

### Game State
- `GET /state` - Get current player state (requires authentication)

### Economy
- `POST /economy/sell` - Sell resources for coins (requires authentication)
  - Body: `{ resource_type: string (enum: water, wood, stone), quantity: integer (1-1,000,000) }`
- `POST /economy/buildings/build` - Build a new building (requires authentication)
  - Body: `{ building_type: string (enum: well, lumberjack, sandgrube) }`
- `POST /economy/buildings/upgrade` - Upgrade a building (requires authentication)
  - Body: `{ building_type: string (enum: well, lumberjack, sandgrube) }`
- `POST /economy/production/start` - Start a production job (requires authentication)
  - Body: `{ building_type: string (enum: well, lumberjack, sandgrube), quantity: integer (1-1,000) }`
- `GET /economy/production/status` - Get production queue status (requires authentication)

### Market (Player-to-Player Trading)
- `GET /market/listings` - Get active market listings (requires authentication)
  - Query params: `resource_type` (optional: water, wood, stone), `limit` (default: 50, max: 200)
- `POST /market/listings` - Create a new market listing (requires authentication)
  - Body: `{ resource_type: string (enum: water, wood, stone), quantity: integer (1-1,000,000), price_per_unit: integer (1-1,000,000,000) }`
- `POST /market/listings/:id/buy` - Buy a market listing (requires authentication)

### Health Check
- `GET /health` - Server health check

### Development (DEV only - not available in production)
- `POST /dev/reset-account` - Reset user account to starting state (requires authentication)
  - Resets coins to 100
  - Clears inventory
  - Deletes all buildings and re-adds starting buildings (well, lumberjack, sandgrube)
  - Cancels all active production jobs
  - Cancels all market listings and returns resources to inventory
  - **Only available when NODE_ENV != 'production'**

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Architecture

- **Express.js** - Web framework
- **PostgreSQL** - Database
- **JWT** - Authentication
- **bcrypt** - Password hashing
- **Zod** - Input validation

## Game Mechanics

### Resources
- Water (produced by wells)
- Wood (produced by lumberjacks)
- Stone/Sand (produced by sandgrube - sand mines)

### Buildings
Each building produces resources over time. Production increases with building level.

**Building Costs (to construct):**
- Well: 10 coins, 10 wood, 20 stone
- Lumberjack: 10 coins, 10 wood
- Stonemason: 10 coins, 10 wood

**Upgrade Costs:**
- Formula: `100 * 1.6^(level-1)` coins

### Production System
**MANUAL PRODUCTION ONLY** - Buildings do NOT produce automatically over time.

Players can start production jobs that consume resources and time to produce outputs:

**Well Production:**
- Cost: 1 coin per unit
- Duration: 3 seconds per unit
- Output: 1 water per unit

**Lumberjack Production:**
- Cost: 1 coin + 1 water per unit
- Duration: 5 seconds per unit
- Output: 10 wood per unit

**Sandgrube (Sand Mine) Production:**
- Cost: 1 coin + 1 water per unit
- Duration: 5 seconds per unit
- Output: 2 sand per unit

Players manually select quantity via a slider and click "Produce" to queue a production job. The job runs in the background and completes after (quantity × duration). Once complete, resources are added to inventory.

**NO IDLE/OFFLINE PRODUCTION** - Production only happens when explicitly started by the player.

### Player Market
Players can trade resources with each other through market listings:
- Create listings to sell resources at custom prices
- Browse and buy listings from other players
- 7% marketplace fee applies to all transactions
- Listings expire after 24 hours
- Maximum 10 active listings per player to prevent spam
