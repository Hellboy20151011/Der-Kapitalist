# Der-Kapitalist

Ein Spiel wie Kapiland nur für Mobile Clients und als Lernprojekt.

## Projektstruktur

### Backend
- **backend/** - Node.js/Express API Server

### Frontend (Godot)
- **Scenes/** - Godot scenes organized by functionality
  - **Auth/** - Login and authentication scenes
  - **Game/** - Main game scene
  - **UI/** - Reusable UI components
  - **Common/** - Shared components (LoadingOverlay, etc.)
- **autoload/** - Godot Autoload-Skripte
  - **GameState.gd** - Global game state management
  - **Api.gd** - API communication layer

### Documentation
All documentation is now organized in the **[docs/](docs/)** folder:
- **[docs/API.md](docs/API.md)** - Complete API endpoint documentation
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Architecture overview and implementation guide
- **[docs/DB_Schema.md](docs/DB_Schema.md)** - PostgreSQL Datenbankschema
- **[docs/DOCS_INDEX.md](docs/DOCS_INDEX.md)** - Complete documentation index
- **[docs/QUICKSTART.md](docs/QUICKSTART.md)** - Quick start guide
- **[docs/RAILWAY_DEPLOYMENT.md](docs/RAILWAY_DEPLOYMENT.md)** - Railway.app deployment guide

See **[docs/DOCS_INDEX.md](docs/DOCS_INDEX.md)** for a complete overview of all available documentation.

## Technologie-Stack

### Backend
- Node.js mit Express.js
- PostgreSQL Datenbank
- JWT Authentifizierung
- bcrypt für Passwort-Hashing
- Socket.io für WebSocket-Kommunikation

### Frontend
- Godot Engine 4+
- GDScript
- WebSocket Client für Echtzeit-Updates

## Setup

### Backend Setup

Siehe [backend/README.md](backend/README.md) für Backend-Setup-Anweisungen.

**Quick Start:**
1. Installiere PostgreSQL und erstelle eine Datenbank
2. Kopiere `backend/.env.example` zu `backend/.env` und konfiguriere:
   - `DATABASE_URL`: PostgreSQL Connection String
   - `JWT_SECRET`: Sicherer Secret Key (mind. 32 Zeichen)
   - `ALLOWED_ORIGINS`: CORS Origins (komma-separiert)
3. Führe Datenbank-Migrationen aus:
   ```bash
   psql -d der_kapitalist -f backend/migrations/001_initial_schema.sql
   psql -d der_kapitalist -f backend/migrations/002_add_building_production_columns.sql
   psql -d der_kapitalist -f backend/migrations/003_add_performance_indices.sql
   ```
4. Installiere Dependencies: `cd backend && npm install`
5. Starte den Server: `npm start`

### Frontend Setup (Godot)

1. Installiere Godot Engine 4.5+ (empfohlen: 4.5.1)
2. Öffne das Projekt in Godot
3. (Optional) Konfiguriere API Base URL in Projekt-Einstellungen:
   - Project → Project Settings → Application → Config
   - Füge `api_base_url` Setting hinzu mit deiner Backend URL
   - Füge `ws_base_url` Setting hinzu für WebSocket URL (z.B. `ws://localhost:3000`)
4. Drücke F5 zum Starten

### WebSocket Setup

Das Spiel nutzt WebSockets für Echtzeit-Updates wie:
- Neue Markt-Listings erscheinen sofort bei allen Spielern
- Produktions-Abschluss-Benachrichtigungen
- Sofortige Synchronisation bei Verkäufen

**Backend Konfiguration:**

Die WebSocket-Verbindung läuft über denselben Port wie die HTTP-API. In `.env`:
```
PORT=3000
ALLOWED_ORIGINS=http://localhost:3000
```

WebSocket URL: `ws://localhost:3000` (Entwicklung) oder `wss://yourdomain.com` (Produktion)

**Frontend Konfiguration:**

Der WebSocketClient ist als Autoload konfiguriert und verbindet sich automatisch beim Start.

**WebSocket-Verbindung testen:**

1. Starte Backend: `cd backend && npm start`
2. Öffne zwei Godot-Instanzen oder zwei Browser
3. Melde dich mit verschiedenen Accounts an
4. Erstelle ein Markt-Listing in Client A
5. Client B sollte das neue Listing sofort sehen

Bei Verbindungsproblemen:
- Prüfe, dass Backend läuft und Port 3000 frei ist
- Prüfe Browser-Konsole oder Godot-Ausgabe für WebSocket-Fehler
- WebSocket fällt automatisch auf Polling zurück wenn Verbindung fehlschlägt

Siehe **[docs/API.md#websocket-events](docs/API.md)** für vollständige WebSocket-Dokumentation.

## Architektur

### Client-Server-Trennung
Das Spiel folgt einer strikten Client-Server-Architektur:
- **Server**: Single Source of Truth für alle Spielzustände
- **Client**: UI und User Experience Layer
- **API**: RESTful JSON API (siehe [docs/API.md](docs/API.md))

### Autoloads (Globals)
- **WebSocketClient**: Verwaltet WebSocket-Verbindung für Echtzeit-Updates
- **GameState**: Verwaltet globalen Spielzustand (Token, Coins, Inventory, Buildings)
- **Api**: Abstraktionsschicht für alle API-Aufrufe

### Modularität
Szenen sind nach Funktion organisiert:
- **Auth**: Authentifizierung und Login
- **Game**: Hauptspiel-Logik
- **UI**: Wiederverwendbare UI-Komponenten
- **Common**: Gemeinsame Komponenten wie LoadingOverlay

### Fehlerbehandlung
- Loading States zeigen während API-Aufrufen
- Buttons werden während Requests deaktiviert
- Fehlermeldungen vom Server werden angezeigt

## Spielmechanik

Der-Kapitalist ist ein Wirtschaftsspiel, bei dem Spieler:
- Ressourcen produzieren (Wasser, Holz, Stein, etc.)
- Gebäude bauen und upgraden (Brunnen, Holzfäller, Steinmetz, etc.)
- **Manuelle Produktions-Jobs starten** - Produktion wird über Schieberegler gestartet und läuft für die gewählte Anzahl × Produktionszeit
- Ressourcen gegen Münzen verkaufen
- Mit anderen Spielern auf dem Marktplatz handeln
- **KEINE automatische Idle-Produktion** - Gebäude produzieren nur wenn Jobs manuell gestartet werden

## Quick Reference

### For Developers

**Running the project:**
1. Start backend: `cd backend && npm start`
2. Open project in Godot 4+
3. Press F5 to run

**Key files to know:**
- `autoload/GameState.gd` - Global state (coins, inventory, buildings)
- `autoload/Api.gd` - All API calls
- `Scenes/Auth/Login.gd` - Login logic
- `Scenes/Game/Main.gd` - Main game logic

**Making API calls:**
```gdscript
# Login
var result = await Api.login(email, password)

# Get state
var result = await Api.get_state()

# Build building
var result = await Api.build_building("well")
```

**Accessing state:**
```gdscript
# Get coins
var coins = GameState.coins

# Get inventory
var water = GameState.inventory["water"]

# Check building ownership
if GameState.has_building("well"):
    print("Has well!")
```

### For Further Reading
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - Complete architecture guide
- [docs/API.md](docs/API.md) - API endpoint reference
- [docs/REVIEW.md](docs/REVIEW.md) - Code review that led to these improvements
- [docs/DOCS_INDEX.md](docs/DOCS_INDEX.md) - Complete documentation index

