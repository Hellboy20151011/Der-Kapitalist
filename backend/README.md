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
- `POST /economy/buildings/upgrade` - Upgrade a building (requires authentication)

### Health Check
- `GET /health` - Server health check

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
- Stone (produced by stonemasons)

### Buildings
Each building produces resources over time. Production increases with building level.

### Offline Production
The game tracks offline time and grants up to 8 hours of catch-up production when players return.
