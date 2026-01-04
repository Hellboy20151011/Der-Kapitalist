# API Documentation

## Base URL
```
http://localhost:3000
```

## Authentication

All authenticated endpoints require a JWT token in the `Authorization` header:
```
Authorization: Bearer <token>
```

### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Error):**
```json
{
  "error": "Email bereits registriert"
}
```

### POST /auth/login
Login with existing credentials.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Error):**
```json
{
  "error": "Ungültige Anmeldedaten"
}
```

## State Management

### GET /state
Get current player state (requires authentication).

**Response:**
```json
{
  "coins": "1000",
  "inventory": {
    "water": "50",
    "wood": "30",
    "stone": "20",
    "sand": "10"
  },
  "buildings": [
    {
      "id": 1,
      "type": "well",
      "level": 1,
      "is_producing": false,
      "ready_at_unix": null
    }
  ],
  "server_time": "2024-01-15T10:30:00Z"
}
```

## Economy

### POST /economy/buildings/build
Build a new building (requires authentication).

**Request Body:**
```json
{
  "building_type": "well"
}
```

**Valid building types:** `well`, `lumberjack`, `sandgrube`

**Response (Success):**
```json
{
  "message": "Gebäude gebaut",
  "building": {
    "id": 1,
    "type": "well",
    "level": 1
  }
}
```

**Response (Error):**
```json
{
  "error": "Nicht genug Coins"
}
```

### POST /economy/buildings/upgrade
Upgrade an existing building (requires authentication).

**Request Body:**
```json
{
  "building_type": "well"
}
```

**Response (Success):**
```json
{
  "message": "Gebäude upgraded",
  "building": {
    "id": 1,
    "type": "well",
    "level": 2
  }
}
```

### POST /economy/sell
Sell resources for coins (requires authentication).

**Request Body:**
```json
{
  "resource_type": "water",
  "quantity": 10
}
```

**Valid resource types:** `water`, `wood`, `stone`, `sand`

**Response (Success):**
```json
{
  "message": "Ressourcen verkauft",
  "coins_earned": 50,
  "new_balance": "1050"
}
```

## Production

### POST /production/start
Start a production job (requires authentication).

**Request Body:**
```json
{
  "building_type": "well",
  "quantity": 5
}
```

**Response (Success):**
```json
{
  "message": "Produktion gestartet",
  "ready_at": "2024-01-15T10:35:00Z",
  "ready_at_unix": 1705318500
}
```

**Response (Error):**
```json
{
  "error": "Gebäude produziert bereits"
}
```

**Notes:**
- Production costs coins per unit produced (1 coin for well, 2 for lumberjack, 3 for sandgrube)
- Production takes time (3 seconds per unit for well, varies by building)
- Collection happens automatically when production completes

### POST /production/collect
Manually collect finished production (requires authentication).

**Note:** In the current implementation, production is automatically collected when querying `/state`, so this endpoint is optional.

**Request Body:**
```json
{
  "building_type": "well"
}
```

**Response (Success):**
```json
{
  "ok": true,
  "building_type": "well",
  "quantity": "5",
  "resource": "water"
}
```

**Response (Error):**
```json
{
  "error": "nothing_to_collect"
}
```

or

```json
{
  "error": "not_ready_yet",
  "ready_at": "2024-01-15T10:35:00Z"
}
```

## Market

### GET /market/listings
Get market listings, optionally filtered by resource type.

**Query Parameters:**
- `resource_type` (optional): Filter by resource type (`water`, `wood`, `stone`, `sand`)

**Example:** `GET /market/listings?resource_type=water`

**Response:**
```json
{
  "listings": [
    {
      "id": 123,
      "seller_id": 456,
      "resource_type": "water",
      "quantity": "100",
      "price_per_unit": "5",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### POST /market/listings
Create a new market listing (requires authentication).

**Request Body:**
```json
{
  "resource_type": "water",
  "quantity": 100,
  "price_per_unit": 5
}
```

**Response (Success):**
```json
{
  "message": "Listing erstellt",
  "listing": {
    "id": 123,
    "resource_type": "water",
    "quantity": "100",
    "price_per_unit": "5"
  }
}
```

**Response (Error):**
```json
{
  "error": "Nicht genug Ressourcen"
}
```

### POST /market/listings/:id/buy
Buy a market listing (requires authentication).

**Path Parameters:**
- `id`: The listing ID

**Request Body:**
```json
{}
```

**Response (Success):**
```json
{
  "message": "Erfolgreich gekauft"
}
```

**Response (Error):**
```json
{
  "error": "Nicht genug Coins"
}
```

## Development

### POST /dev/reset-account
Reset account to initial state (requires authentication, dev mode only).

**Request Body:**
```json
{}
```

**Response:**
```json
{
  "message": "Account zurückgesetzt"
}
```

## Error Responses

All endpoints may return these standard error responses:

**401 Unauthorized:**
```json
{
  "error": "Token ungültig oder abgelaufen"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Serverfehler"
}
```

## Notes

- All numeric values (coins, quantities) are returned as strings to prevent JavaScript BigInt issues
- Unix timestamps are provided for time-sensitive operations (production completion)
- The server is the single source of truth for all game state
- Client should poll `/state` endpoint periodically to check production status
