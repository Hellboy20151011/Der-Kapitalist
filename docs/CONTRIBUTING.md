# Contributing to Der-Kapitalist

Vielen Dank für dein Interesse an der Entwicklung von Der-Kapitalist!

## Development Setup

### Voraussetzungen

- Node.js 20+ und npm
- PostgreSQL 14+
- Godot Engine 4.2+
- Git

### Repository Setup

1. Clone das Repository:
   ```bash
   git clone https://github.com/Hellboy20151011/Der-Kapitalist.git
   cd Der-Kapitalist
   ```

2. Backend Setup:
   ```bash
   cd backend
   npm install
   cp .env.example .env
   # Bearbeite .env mit deinen Datenbank-Credentials
   ```

3. Datenbank Setup:
   ```bash
   createdb der_kapitalist
   psql -d der_kapitalist -f migrations/001_initial_schema.sql
   psql -d der_kapitalist -f migrations/002_add_building_production_columns.sql
   psql -d der_kapitalist -f migrations/003_add_performance_indices.sql
   ```

4. Server starten:
   ```bash
   npm start
   # oder für development mit auto-reload:
   npm run dev
   ```

5. Godot Projekt öffnen und F5 drücken

## Code-Struktur

### Backend (Node.js/Express)

```
backend/
├── src/
│   ├── routes/       # API Endpoints
│   ├── services/     # Business Logic
│   ├── middleware/   # Express Middleware
│   ├── app.js        # Express App Setup
│   ├── config.js     # Configuration
│   ├── db.js         # Database Pool
│   ├── logger.js     # Logging Utility
│   └── Server.js     # Entry Point
└── migrations/       # Database Migrations
```

### Frontend (Godot/GDScript)

```
Scenes/
├── Auth/            # Login/Register
├── Game/            # Main Game Scene
├── UI/              # Reusable UI Components
└── Common/          # Shared Components

autoload/
├── GameState.gd     # Global State Management
├── Api.gd           # API Client
└── net.gd           # Deprecated (use Api.gd)
```

## Coding Standards

### Backend (JavaScript)

- ES6 Modules (import/export)
- Async/await statt Callbacks
- Zod für Input Validierung
- Parameterisierte SQL Queries (keine String-Concatenation)
- Try-catch mit ROLLBACK in finally
- BigInt für große Zahlen (Coins, Quantities)
- Strukturiertes Logging mit logger.js

**Beispiel:**
```javascript
import { z } from 'zod';
import { pool } from '../db.js';
import { authRequired } from '../middleware/authRequired.js';
import { logger } from '../logger.js';

const schema = z.object({
  quantity: z.number().int().positive().max(1_000_000)
});

router.post('/endpoint', authRequired, async (req, res) => {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: 'invalid_input', details: parsed.error.issues });
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    // ... business logic
    await client.query('COMMIT');
    return res.json({ ok: true });
  } catch (e) {
    await client.query('ROLLBACK');
    logger.error('Endpoint error', { error: e.message, userId: req.user.id });
    return res.status(500).json({ error: 'server_error' });
  } finally {
    client.release();
  }
});
```

### Frontend (GDScript)

- Type hints wo möglich: `var coins: int = 0`
- Dokumentation mit `##`
- Signals für Komponenten-Kommunikation
- Autoload nur für echte Globals (GameState, Api)
- Await für asynchrone API-Calls
- Error-Handling für alle API-Calls

**Beispiel:**
```gdscript
func _build_building(building_type: String) -> void:
    if is_loading:
        return
    
    _show_loading(true)
    _disable_buttons(true)
    
    var res := await Api.build_building(building_type)
    
    _show_loading(false)
    _disable_buttons(false)
    
    if not res.ok:
        _set_status("❌ Fehler: " + _error_string(res))
        return
    
    _set_status("✓ Gebäude gebaut!")
    await _sync_state()
```

## Git Workflow

### Branch Naming

- `feature/beschreibung` - Neue Features
- `bugfix/beschreibung` - Bug Fixes
- `docs/beschreibung` - Dokumentations-Updates
- `refactor/beschreibung` - Code Refactoring

### Commit Messages

Verwende beschreibende Commit Messages auf Deutsch:

```
Add: Neue Feature-Beschreibung
Fix: Behobenen Bug beschreiben
Refactor: Refactoring-Details
Docs: Dokumentations-Änderungen
```

### Pull Request Process

1. Erstelle einen Branch für deine Änderungen
2. Committe häufig mit klaren Messages
3. Update/Ergänze die Dokumentation
4. Teste deine Änderungen lokal
5. Erstelle einen Pull Request mit Beschreibung
6. Warte auf Code Review

## Testing

Aktuell gibt es keine automatisierten Tests. Bitte teste manuell:

### Backend Testing

1. Starte den Server
2. Teste API Endpoints mit curl/Postman:
   ```bash
   # Register
   curl -X POST http://localhost:3000/auth/register \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test1234"}'
   
   # Login
   curl -X POST http://localhost:3000/auth/login \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"test1234"}'
   ```

### Frontend Testing

1. Öffne Godot
2. Drücke F5
3. Teste Login/Register
4. Teste Spielmechaniken (Bauen, Produzieren, Verkaufen)
5. Teste Market Features
6. Teste Error Cases (falsches Passwort, nicht genug Coins, etc.)

## Sicherheit

### Security Best Practices

- **Nie** Secrets im Code committen
- **Nie** `.env` Files committen
- SQL Injection durch parameterisierte Queries verhindern
- Input Validierung mit Zod Schemas
- JWT Token Validierung
- CORS richtig konfigurieren
- Rate Limiting beachten (siehe SECURITY.md)

### Reporting Security Issues

Sicherheitslücken bitte **nicht** öffentlich als Issue melden, sondern direkt an die Maintainer.

## Fragen?

Bei Fragen erstelle ein GitHub Issue oder kontaktiere die Maintainer.

## License

Dieses Projekt steht unter der ISC License - siehe LICENSE file für Details.
