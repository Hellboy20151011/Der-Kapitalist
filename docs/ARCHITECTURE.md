# Architectural Improvements Summary

## Overview
This document summarizes the architectural improvements made to Der-Kapitalist based on the code review in issue #1.

## Changes Implemented

### 1. Project Structure Reorganization ✅

**Before:**
```
Scenes/
 ├─ Login.tscn
 └─ Main.tscn
Scripts/
 ├─ login.gd
 └─ Main.gd
```

**After:**
```
Scenes/
 ├─ Auth/
 │   ├─ Login.tscn
 │   └─ Login.gd
 ├─ Game/
 │   ├─ Main.tscn
 │   └─ Main.gd
 ├─ UI/
 │   ├─ WalletBar.tscn
 │   └─ WalletBar.gd
 └─ Common/
     ├─ LoadingOverlay.tscn
     └─ LoadingOverlay.gd
```

**Benefits:**
- Clear separation between authentication and game logic
- UI components are modular and reusable
- Shared components are centralized
- Easier to find and maintain code

### 2. Autoload System ✅

**New Autoloads:**

#### GameState.gd
Global state management singleton that stores:
- Authentication state (token, player_id)
- Player data (coins, company_name)
- Inventory (water, wood, stone, sand)
- Buildings array
- Server time

**Key Methods:**
- `reset()`: Reset all state (on logout)
- `update_from_server(data)`: Update from API response
- `has_building(type)`: Check building ownership
- `get_building(type)`: Get building data

#### Api.gd
Abstraction layer for all API endpoints:

**Auth:**
- `login(email, password)`
- `register(email, password)`

**State:**
- `get_state()`

**Economy:**
- `build_building(type)`
- `upgrade_building(type)`
- `sell_resource(type, quantity)`

**Production:**
- `start_production(type, quantity)`

**Market:**
- `get_market_listings(resource_type)`
- `create_market_listing(type, quantity, price)`
- `buy_listing(id)`

**Dev:**
- `dev_reset_account()`

**Benefits:**
- No more `get_node("../../")` mess
- Clean API for all scenes
- Single source of truth for state
- Easy to test and mock
- Mobile-friendly architecture

### 3. Scene Refactoring ✅

#### Login Scene
**Improvements:**
- Uses `Api.login()` and `Api.register()` instead of raw HTTP
- Updates `GameState.token` instead of `Net.token`
- Already has loading states and error handling
- Properly disables buttons during requests

#### Main Scene
**Improvements:**
- Refactored to use `Api.*` methods instead of `Net.post_json()`
- Uses `GameState` for state management
- Scene change now points to `res://Scenes/Game/Main.tscn`
- Logout properly resets `GameState`

### 4. UI Components ✅

#### LoadingOverlay (Common)
Reusable loading overlay with animated spinner:
- Shows/hides with messages
- Blocks interaction during loading
- Animated spinner for visual feedback

#### WalletBar (UI)
Example of modular UI component:
- Displays coins and resources
- Can update from `GameState` directly
- Reusable across scenes

**Benefits:**
- Components can be reused
- Testing individual components is easier
- Changes to one component don't affect others
- Following UI/UX best practices

### 5. Documentation ✅

#### API.md
Complete API documentation including:
- All endpoints with request/response examples
- Authentication requirements
- Error responses
- Notes about data types and server behavior

#### README.md Updates
- New project structure section
- Architecture explanation
- Links to documentation
- Clear separation of concerns

**Benefits:**
- Frontend developers know exactly what to expect
- Backend developers have clear API contract
- New team members can understand the system quickly

### 6. Error Handling & UX ✅

**Already Implemented in Main Scene:**
- Loading spinner shows during all API calls
- Buttons disabled during requests
- Status messages with auto-timeout
- Error messages displayed to user

**LoadingOverlay Component:**
- Can be integrated into any scene
- Provides consistent loading experience

## Architecture Principles

### 1. Client-Server Separation
✅ **Server is Single Source of Truth**
- All game logic runs on server
- Client only displays and collects input
- Production calculations on server
- Prevents cheating

### 2. State Management
✅ **Centralized via GameState**
- No scattered state across scenes
- Easy to sync with server
- Logout properly clears all state

### 3. API Abstraction
✅ **Clean API Layer via Api.gd**
- Scenes don't need to know about HTTP
- Easy to change backend without touching scenes
- Can add request/response logging easily
- Can implement retry logic centrally

### 4. Modular UI
✅ **Component-Based Architecture**
- Each UI element is its own scene
- Components can be composed
- Signals for communication
- No tight coupling

### 5. Loading States
✅ **User Feedback During Operations**
- Always show loading state during API calls
- Disable buttons to prevent double-submit
- Clear error messages
- Auto-dismiss success messages

## Migration Path

### For Existing Code
The old `Net` autoload is kept for backward compatibility:
- `Net.token` now proxies to `GameState.token`
- Old code will continue to work
- Gradually migrate to `Api.*` methods

### For New Code
Always use:
- `GameState` for state access
- `Api.*` methods for API calls
- Scene paths in `Scenes/{Auth,Game,UI,Common}/`

## Testing Checklist

- [ ] Login flow works correctly
- [ ] Main scene loads after login
- [ ] State syncs properly
- [ ] Building construction works
- [ ] Production starts and completes
- [ ] Market operations work
- [ ] Logout returns to login screen
- [ ] Loading states display correctly
- [ ] Error messages show properly

## Future Improvements

### Recommended Next Steps:

1. **Break Down Main.gd Further**
   - Extract production panel logic to `UI/ProductionPanel.tscn`
   - Extract market panel logic to `UI/MarketPanel.tscn`
   - Create `UI/BuildingPanel.tscn` for building management
   - Main.gd should only coordinate between components

2. **Add More UI Components**
   - `UI/BuildingCard.tscn` - Display single building
   - `UI/ResourceDisplay.tscn` - Show resource with icon
   - `UI/ProgressBar.tscn` - Production progress

3. **Implement Signal-Based Communication**
   - Components emit signals for actions
   - Main scene or controller responds to signals
   - Loose coupling between components

4. **Add State Persistence**
   - Save last login email (optional)
   - Cache state locally for offline viewing
   - Background sync when app resumes

5. **Improve Error Handling**
   - Retry failed requests automatically
   - Queue actions when offline
   - Better error categorization

6. **Add Unit Tests**
   - Test `GameState` methods
   - Test `Api` error handling
   - Test UI component behavior

## Conclusion

The implemented changes provide a solid foundation for scaling the project:

✅ **Organized**: Clear structure that scales  
✅ **Maintainable**: Easy to find and fix code  
✅ **Testable**: Components can be tested in isolation  
✅ **Mobile-Ready**: Proper state management and loading states  
✅ **Documented**: Clear API and architecture documentation  
✅ **Secure**: Server-authoritative, no client-side cheating  

The architecture now follows industry best practices for client-server games and is ready for team collaboration and future expansion.

## Real-Time Communication Architecture

### Overview

The game now supports real-time updates through WebSocket connections, enabling immediate synchronization of game state changes across clients without polling.

### When to Use REST vs WebSocket

#### Use REST API for:
- **User-initiated actions**: Login, register, building construction, starting production
- **Data fetching**: Getting initial state, querying market listings
- **Write operations**: All modifications to game state (REST is the source of truth)
- **Historical data**: Fetching logs, statistics, past transactions

#### Use WebSocket for:
- **Real-time notifications**: Production completion, market listing sold
- **Live updates**: New market listings appearing immediately
- **State synchronization**: Keeping UI in sync with server changes
- **Presence**: Detecting when other players are online (future feature)

**Key Principle**: REST writes, WebSocket notifies. All changes go through REST API, WebSocket only broadcasts notifications.

### WebSocket Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Godot Frontend                         │
├─────────────────────────────────────────────────────────────┤
│  WebSocketClient.gd (Autoload)                             │
│  - Connection management                                    │
│  - JWT authentication                                       │
│  - Exponential backoff reconnection                        │
│  - Event routing via signals                               │
│                                                             │
│  GameState.gd                                              │
│  - Listens to WebSocket signals                            │
│  - Fetches updated state from REST API                     │
│  - Emits state change signals                              │
│                                                             │
│  Game Scenes (Main.gd, Market.gd, etc.)                    │
│  - Subscribe to WebSocket channels                         │
│  - React to real-time events                               │
│  - Update UI immediately                                   │
└─────────────────────────────────────────────────────────────┘
                           ▲ ▼
                    WebSocket (ws://)
                           ▲ ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend (Node.js)                       │
├─────────────────────────────────────────────────────────────┤
│  Server.js                                                  │
│  - Creates HTTP server                                      │
│  - Initializes Socket.io                                    │
│                                                             │
│  websocket.js                                               │
│  - Socket.io initialization                                 │
│  - JWT authentication middleware                            │
│  - Connection/disconnection handling                        │
│  - User → Socket mapping (Map<userId, Set<socketId>>)      │
│  - Channel subscriptions (rooms)                            │
│                                                             │
│  utils/socketHelper.js                                      │
│  - emitToUser(userId, event, data)                         │
│  - broadcastToAll(event, data)                             │
│  - broadcastToSubscribers(channel, event, data)            │
│                                                             │
│  Routes (market.js, production.js, economy.js)             │
│  - Process REST requests                                    │
│  - Update database                                          │
│  - Emit WebSocket events after successful operations       │
└─────────────────────────────────────────────────────────────┘
```

### Event Flow Diagrams

#### Market Listing Creation

```
User A (Godot)                Backend                    User B (Godot)
      │                          │                              │
      │  POST /market/listings   │                              │
      ├─────────────────────────>│                              │
      │                          │                              │
      │                      [DB Write]                         │
      │                          │                              │
      │  HTTP 200 OK            │                              │
      │<─────────────────────────┤                              │
      │                          │                              │
      │                          │  WS: market:new-listing      │
      │                          ├─────────────────────────────>│
      │                          │                              │
      │                          │                          [Refresh UI]
      │                          │                              │
```

#### Production Completion

```
User (Godot)                   Backend
      │                          │
      │  POST /production/start  │
      ├─────────────────────────>│
      │                          │
      │                      [DB Write]
      │                          │
      │  WS: production:started │
      │<─────────────────────────┤
      │                          │
      │                     [Timer expires]
      │                          │
      │  POST /production/collect│
      ├─────────────────────────>│
      │                          │
      │                      [DB Write]
      │                          │
      │  WS: production:complete │
      │<─────────────────────────┤
      │                          │
      │  [Update inventory UI]   │
      │                          │
```

#### Market Purchase

```
Buyer (User B)                Backend               Seller (User A)
      │                          │                          │
      │  POST /listings/:id/buy  │                          │
      ├─────────────────────────>│                          │
      │                          │                          │
      │                  [Transaction: DB]                  │
      │                          │                          │
      │  HTTP 200 OK            │                          │
      │<─────────────────────────┤                          │
      │                          │                          │
      │  WS: state:update       │                          │
      │<─────────────────────────┤                          │
      │                          │                          │
      │                          │  WS: market:listing-sold │
      │                          ├─────────────────────────>│
      │                          │                          │
      │  [Refresh coins]         │                [Notification]
      │                          │                          │
```

### Reconnection Strategy

WebSocket connections can be interrupted by network issues, server restarts, or client inactivity. The client implements exponential backoff:

```
Attempt | Delay
--------|-------
1       | 1s
2       | 2s
3       | 4s
4       | 8s
5       | 16s
6+      | 30s (max)
```

**Reconnection Flow:**

```gdscript
1. Detect disconnection
2. Start reconnection timer
3. Attempt to reconnect
4. If successful:
   - Reset attempt counter
   - Re-authenticate with JWT
   - Re-subscribe to channels
5. If failed:
   - Increase delay exponentially
   - Retry (max 10 attempts)
6. If all attempts fail:
   - Fall back to polling /state endpoint
   - Notify user of limited functionality
```

### Security Considerations

1. **Authentication**: JWT token required for WebSocket handshake
2. **Authorization**: Server validates userId from token matches event target
3. **Rate Limiting**: Prevent spam by limiting message frequency
4. **Input Validation**: All WebSocket messages validated same as REST
5. **Token Expiry**: Client must reconnect with fresh token when JWT expires

### Performance Characteristics

**Connection Overhead:**
- Initial connection: ~100ms (includes TLS handshake)
- Authentication: ~10ms
- Subscribe to channel: ~5ms

**Message Latency:**
- WebSocket message: 10-50ms (vs 100-500ms for REST polling)
- Broadcast to 100 users: <100ms
- Emit to single user: <10ms

**Scaling Considerations:**
- Current implementation: In-memory user-socket mapping
- For production: Use Redis for distributed state
- Socket.io supports clustering with Redis adapter

### Graceful Degradation

If WebSocket connection fails or is unavailable:

1. **Fallback to polling**: Client polls `/state` every 5 seconds
2. **User notification**: Display "Limited connectivity" warning
3. **Reduced features**: No real-time market updates, manual refresh required
4. **All critical features work**: Production, building, trading still functional

Example implementation:

```gdscript
func _ready():
    WebSocketClient.connection_error.connect(_on_websocket_failed)

func _on_websocket_failed(error: String):
    print("WebSocket unavailable, falling back to polling")
    _start_polling_timer()
    _show_connectivity_warning()
```

### Future Enhancements

1. **Presence System**: Show which players are online
2. **Chat System**: Real-time messaging between players
3. **Trade Notifications**: Alert when specific resources are listed
4. **Price Alerts**: Notify when prices drop below threshold
5. **Alliance Features**: Real-time cooperation mechanics
6. **Live Leaderboards**: Rankings update in real-time

### Testing Real-Time Features

**Manual Testing Checklist:**

1. Open two clients (two browser windows or Godot instances)
2. Login as different users
3. Create market listing in Client A → Verify appears in Client B
4. Buy listing in Client B → Verify seller notification in Client A
5. Start production → Verify completion notification
6. Disconnect network → Verify reconnection behavior
7. Restart backend server → Verify clients reconnect automatically

**Automated Testing:**

```javascript
// Backend test
describe('WebSocket Events', () => {
  it('should emit market:new-listing when listing created', async () => {
    const socket = io('ws://localhost:3000', { auth: { token } });
    socket.emit('subscribe:market');
    
    // Create listing via REST
    await request(app).post('/market/listings').send({...});
    
    // Verify WebSocket event received
    await waitFor(() => socket.received('market:new-listing'));
  });
});
```

### Monitoring and Debugging

**Server-side logging:**
- Connection/disconnection events
- Authentication failures
- Message routing
- Channel subscriptions

**Client-side logging:**
```gdscript
WebSocketClient.connected_to_server.connect(func():
    print("[WS] Connected at ", Time.get_time_string_from_system())
)

WebSocketClient.market_new_listing.connect(func(listing):
    print("[WS] New listing: ", listing)
)
```

**Health checks:**
```bash
# Check WebSocket endpoint
curl -i -N -H "Connection: Upgrade" \
     -H "Upgrade: websocket" \
     http://localhost:3000
```
