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

## WebSocket Events

### Connection

WebSocket server is available at the same URL as the HTTP API, using the WebSocket protocol:

**Development:**
```
ws://localhost:3000
```

**Production:**
```
wss://your-domain.com
```

### Authentication

WebSocket connections require JWT authentication. The token should be sent in the connection handshake:

```javascript
// In the initial connection message
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

In Godot, authentication is handled automatically by the WebSocketClient autoload.

### Client → Server Events

Events that the client can send to the server:

#### subscribe:market
Subscribe to market updates (new listings, sales).

**Payload:**
```json
{}
```

**Server Response:**
```json
{
  "event": "subscribed",
  "data": {
    "channel": "market"
  }
}
```

#### subscribe:production
Subscribe to production updates (job completion).

**Payload:**
```json
{}
```

**Server Response:**
```json
{
  "event": "subscribed",
  "data": {
    "channel": "production"
  }
}
```

#### ping
Keep-alive ping to maintain connection.

**Payload:**
```json
{}
```

**Server Response:**
```json
{
  "event": "pong",
  "data": {
    "timestamp": "2024-01-15T10:30:00Z"
  }
}
```

### Server → Client Events

Events that the server emits to clients:

#### market:new-listing
Emitted when a new market listing is created (broadcast to all subscribed users).

**Payload:**
```json
{
  "id": 123,
  "resource_type": "wood",
  "quantity": "100",
  "price_per_unit": "5",
  "fee_percent": 10,
  "expires_at": "2024-01-16T10:30:00Z"
}
```

#### market:listing-sold
Emitted to the seller when their listing is bought.

**Payload:**
```json
{
  "listing_id": 123,
  "resource_type": "wood",
  "quantity": "100",
  "total": "450",
  "fee": "50"
}
```

#### production:started
Emitted to user when production job starts.

**Payload:**
```json
{
  "building_type": "lumberjack",
  "quantity": 10,
  "ready_at": "2024-01-15T10:35:00Z",
  "resource": "wood",
  "output": "200"
}
```

#### production:complete
Emitted to user when production job finishes.

**Payload:**
```json
{
  "building_type": "lumberjack",
  "quantity": "200",
  "resource": "wood"
}
```

#### state:update
Emitted when coins, inventory, or buildings change.

**Payload for resource sold:**
```json
{
  "type": "resource_sold",
  "resource_type": "wood",
  "quantity": "10",
  "coins_gained": "13"
}
```

**Payload for building built:**
```json
{
  "type": "building_built",
  "building_type": "well",
  "costs": {
    "coins": "20"
  }
}
```

**Payload for building upgraded:**
```json
{
  "type": "building_upgraded",
  "building_type": "well",
  "new_level": 2,
  "cost": "160"
}
```

**Payload for market purchase:**
```json
{
  "type": "market_purchase",
  "coins_spent": "500"
}
```

### Connection Management

- **Reconnection**: Clients should implement exponential backoff for reconnection attempts
- **Heartbeat**: Server sends ping every 25 seconds, times out after 60 seconds of inactivity
- **Token Expiry**: If JWT token expires, reconnect with new token
- **Graceful Degradation**: If WebSocket fails, fall back to polling `/state` endpoint

### Usage Examples

**Godot (using WebSocketClient autoload):**
```gdscript
func _ready():
    # Connect to server
    WebSocketClient.connect_to_server()
    
    # Subscribe to events
    WebSocketClient.market_new_listing.connect(_on_new_listing)
    WebSocketClient.production_complete.connect(_on_production_done)
    
    # Subscribe to channels when connected
    WebSocketClient.connected_to_server.connect(func():
        WebSocketClient.subscribe_to_market()
        WebSocketClient.subscribe_to_production()
    )

func _on_new_listing(listing: Dictionary):
    print("New listing: ", listing.resource_type)
    # Refresh market UI

func _on_production_done(job: Dictionary):
    print("Production complete: ", job.resource)
    # Update inventory UI
```

### Event Flow Examples

**Market Listing Creation:**
1. User A creates listing via `POST /market/listings`
2. Server saves listing to database
3. Server emits `market:new-listing` to all users subscribed to market channel
4. All clients receive event and update their market UI

**Production Completion:**
1. User starts production via `POST /production/start`
2. Server emits `production:started` to user
3. Production timer completes on server
4. User collects via `POST /production/collect`
5. Server emits `production:complete` to user
6. Client updates inventory UI

**Market Purchase:**
1. User B buys listing via `POST /market/listings/:id/buy`
2. Server processes transaction
3. Server emits `market:listing-sold` to seller (User A)
4. Server emits `state:update` to buyer (User B)
5. Both clients update their UI accordingly
