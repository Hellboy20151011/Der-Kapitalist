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
  - **net.gd** - Legacy network layer (deprecated, use Api.gd)

### Documentation
- **[API.md](API.md)** - Complete API endpoint documentation
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Architecture overview and implementation guide
- **DB_Schema.md** - PostgreSQL Datenbankschema
- **IMPLEMENTATION_SUMMARY.md** - Implementation details
- **PRODUCTION_FLOW_DIAGRAM.md** - Production system flow

## Technologie-Stack

### Backend
- Node.js mit Express.js
- PostgreSQL Datenbank
- JWT Authentifizierung
- bcrypt für Passwort-Hashing

### Frontend
- Godot Engine 4+
- GDScript

## Setup

Siehe [backend/README.md](backend/README.md) für Backend-Setup-Anweisungen.

## Architektur

### Client-Server-Trennung
Das Spiel folgt einer strikten Client-Server-Architektur:
- **Server**: Single Source of Truth für alle Spielzustände
- **Client**: UI und User Experience Layer
- **API**: RESTful JSON API (siehe [API.md](API.md))

### Autoloads (Globals)
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
- [ARCHITECTURE.md](ARCHITECTURE.md) - Complete architecture guide
- [API.md](API.md) - API endpoint reference
- [REVIEW.md](REVIEW.md) - Code review that led to these improvements

