# Der-Kapitalist Backend

Backend API server for Der-Kapitalist mobile game.

## Prerequisites

- Node.js 20+ 
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

3. Update `.env` with your configuration:
   - `DATABASE_URL`: PostgreSQL connection string
   - `JWT_SECRET`: Strong secret key (minimum 32 characters recommended)
   - `PORT`: Server port (default: 3000)
   - `JWT_EXPIRES_IN`: Token expiration (default: 7d)
   - `ALLOWED_ORIGINS`: CORS allowed origins (comma-separated)

4. Create database and run migrations:
```bash
createdb der_kapitalist
psql -d der_kapitalist -f migrations/001_initial_schema.sql
psql -d der_kapitalist -f migrations/002_add_building_production_columns.sql
psql -d der_kapitalist -f migrations/003_add_performance_indices.sql
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

## Railway.app Deployment

Wenn das Backend auf Railway.app läuft, müssen folgende Umgebungsvariablen gesetzt werden:

```bash
PORT=8080  # Railway nutzt Port 8080
ALLOWED_ORIGINS=http://localhost:*,https://your-frontend-domain.netlify.app
NODE_ENV=production
DATABASE_URL=<your-railway-postgres-url>
JWT_SECRET=<your-secure-secret-key>
JWT_EXPIRES_IN=7d
```

**Wichtige Hinweise:**
- Railway.app stellt automatisch `DATABASE_URL` bereit wenn PostgreSQL hinzugefügt wird
- `ALLOWED_ORIGINS` sollte alle Frontend-Domains enthalten (komma-separiert)
- `JWT_SECRET` muss mindestens 32 Zeichen lang sein für Sicherheit
- Der WebSocket-Server läuft automatisch auf demselben Port wie die HTTP-API

## API Endpoints

See [../API.md](../API.md) for complete API documentation.

### Quick Reference

**Authentication:**
- `POST /auth/register` - Register a new user
- `POST /auth/login` - Login with email and password

**Game State:**
- `GET /state` - Get current player state (requires auth)

**Production:**
- `POST /production/start` - Start production job (requires auth)
- `POST /production/collect` - Collect finished production (requires auth, optional - auto-collected in /state)

**Economy:**
- `POST /economy/sell` - Sell resources for coins (requires auth)
- `POST /economy/buildings/build` - Build a new building (requires auth)
- `POST /economy/buildings/upgrade` - Upgrade a building (requires auth)

**Market:**
- `GET /market/listings` - Get active market listings (requires auth)
- `POST /market/listings` - Create a market listing (requires auth)
- `POST /market/listings/:id/buy` - Buy a market listing (requires auth)

**Health Check:**
- `GET /health` - Server health check

**Development (DEV only):**
- `POST /dev/reset-account` - Reset account to starting state (requires auth, only when NODE_ENV != 'production')

## Authentication

All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <token>
```

## Architecture

- **Express.js** - Web framework with REST API
- **PostgreSQL** - Relational database with BigInt support
- **JWT** - Stateless authentication tokens
- **bcrypt** - Password hashing (12 rounds)
- **Zod** - Schema validation for all inputs
- **express-rate-limit** - Rate limiting (100 req/15min general, 5 req/15min auth)
- **cors** - Cross-Origin Resource Sharing

### Security Features
- Parameterized SQL queries (SQL injection prevention)
- Input validation with Zod schemas
- JWT token authentication
- bcrypt password hashing
- Rate limiting on all endpoints
- CORS configuration
- Transaction-based operations with ROLLBACK on errors
- FOR UPDATE locks to prevent race conditions

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
