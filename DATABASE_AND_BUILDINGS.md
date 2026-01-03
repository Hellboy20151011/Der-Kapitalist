# Datenbank-Verbindung und Gebäude-Verwaltung

Dieses Dokument erklärt, wie die Datenbank mit dem Code verbunden ist und wie neue Gebäude hinzugefügt werden.

## 1. Datenbank-Verbindung

### Setup und Konfiguration

Die Datenbankverbindung wird in **`backend/src/db.js`** eingerichtet:

```javascript
import pg from 'pg';
import { config } from './config.js';

export const pool = new pg.Pool({
  connectionString: config.databaseUrl,
  ssl: config.isProduction ? { rejectUnauthorized: false } : false
});
```

**Umgebungsvariablen** (in `.env` Datei):
```
DATABASE_URL=postgresql://user:password@localhost:5432/derkapitalist
```

### Datenbankschema

Das vollständige Schema ist in **`DB_Schema.md`** dokumentiert. Wichtige Tabellen:

- **`users`** - Spieler-Accounts
- **`player_state`** - Münzen und letzter Tick-Zeitstempel
- **`inventory`** - Ressourcen des Spielers (Wasser, Holz, Stein, etc.)
- **`buildings`** - Gebäude des Spielers mit Typ und Level
- **`production_queue`** - Aktive Produktions-Jobs
- **`market_listings`** - Marktplatz-Angebote

### Wie Updates zur Datenbank geschehen

Bei jeder API-Anfrage:
1. Client verbindet mit `const client = await pool.connect()`
2. Transaktion startet mit `await client.query('BEGIN')`
3. Daten werden gelesen/geschrieben mit SQL-Queries
4. Transaktion wird abgeschlossen mit `await client.query('COMMIT')`
5. Bei Fehlern: `await client.query('ROLLBACK')`
6. Connection wird freigegeben: `client.release()`

**Beispiel aus `economy.js`:**
```javascript
const client = await pool.connect();
try {
  await client.query('BEGIN');
  
  // SQL Queries hier
  await client.query(
    `UPDATE inventory SET amount = amount + $2 WHERE user_id = $1`,
    [userId, amount]
  );
  
  await client.query('COMMIT');
} catch {
  await client.query('ROLLBACK');
  res.status(500).json({ error: 'server_error' });
} finally {
  client.release();
}
```

## 2. Neue Gebäude hinzufügen

### Schritt 1: Produktions-Konfiguration in `economy.js`

Füge die Gebäude-Produktionsdaten zu **`PRODUCTION_CONFIG`** hinzu:

```javascript
const PRODUCTION_CONFIG = {
  // Existierende Gebäude...
  well: { 
    costs: { coins: 1n, water: 0n }, 
    duration_seconds: 3, 
    output_type: 'water', 
    output_amount: 1n 
  },
  
  // NEUES GEBÄUDE HINZUFÜGEN (Beispiel: Eisenmine):
  ironmine: {
    costs: { 
      coins: 2n,      // Kosten pro Produktions-Zyklus
      water: 1n,      // Benötigte Ressourcen
      wood: 3n 
    },
    duration_seconds: 10,        // Zeit pro Produktions-Einheit
    output_type: 'iron_ore',     // Was wird produziert
    output_amount: 5n            // Menge pro Zyklus
  }
};
```

### Schritt 2: Bau-Kosten in `economy.js`

Füge Baukosten zu **`BUILD_COSTS`** hinzu:

```javascript
const BUILD_COSTS = {
  // Existierende Gebäude...
  well: { coins: 10n, wood: 10n, stone: 20n },
  
  // NEUES GEBÄUDE (Beispiel: Eisenmine):
  ironmine: { 
    coins: 50n, 
    wood: 30n, 
    stone: 20n 
  }
};
```

### Schritt 3: Validation-Schemas aktualisieren

Füge den neuen Gebäude-Typ zu den Zod-Schemas hinzu:

```javascript
// In economy.js - für Produktion starten
const productionStartSchema = z.object({
  building_type: z.enum([
    'well', 'lumberjack', 'sandgrube', 
    'ironmine'  // <-- HINZUFÜGEN
  ]),
  quantity: z.number().int().positive().max(1000)
});

// Für Bauen
const buildSchema = z.object({
  building_type: z.enum([
    'well', 'lumberjack', 'sandgrube',
    'ironmine'  // <-- HINZUFÜGEN
  ])
});

// Für Upgraden
const upgradeSchema = z.object({
  building_type: z.enum([
    'well', 'lumberjack', 'sandgrube',
    'ironmine'  // <-- HINZUFÜGEN
  ])
});
```

### Schritt 4: Verkaufspreise für neue Ressourcen (optional)

Falls das Gebäude eine neue Ressource produziert, füge den Verkaufspreis hinzu:

```javascript
const SELL_PRICES = { 
  water: 1.2, 
  wood: 1.3, 
  stone: 1.4,
  iron_ore: 2.5  // <-- HINZUFÜGEN
};

// Und im sellSchema:
const sellSchema = z.object({
  resource_type: z.enum([
    'water', 'wood', 'stone',
    'iron_ore'  // <-- HINZUFÜGEN
  ]),
  quantity: z.number().int().positive().max(1_000_000)
});
```

### Schritt 5: Frontend (Godot) aktualisieren

In **`Scripts/Main.gd`** UI-Elemente hinzufügen:

1. **Neue Referenzen** für Buttons/Slider:
```gdscript
@onready var ironmine_slider: HSlider = $Path/To/IronmineSlider
@onready var ironmine_produce_btn: Button = $Path/To/IronmineProduceButton
@onready var ironmine_qty_label: Label = $Path/To/IronmineQtyLabel
```

2. **Connections in `_ready()`:**
```gdscript
ironmine_slider.value_changed.connect(func(val): ironmine_qty_label.text = str(int(val)))
ironmine_produce_btn.pressed.connect(func(): await _produce("ironmine", int(ironmine_slider.value)))
```

3. **Building-Tracking Variable:**
```gdscript
var has_ironmine := false
```

4. **Sync-Funktion aktualisieren:**
```gdscript
func _sync_state() -> void:
    # ... 
    for b in buildings:
        if b.type == "ironmine":
            has_ironmine = true
    # ...
```

5. **UI-Update-Funktion:**
```gdscript
func _update_building_ui() -> void:
    # ...
    ironmine_slider.editable = has_ironmine
    ironmine_produce_btn.disabled = not has_ironmine
```

### Schritt 6: Szene (`.tscn`) aktualisieren

Bearbeite **`Scenes/Main.tscn`** und füge hinzu:
- HSlider für Mengenauswahl
- Button für "Produzieren"
- Label für Anzeigewert
- Icon für das Gebäude (optional)

## 3. Produktionssystem verstehen

### Manuelles Produktionssystem

**Keine Idle-Produktion!** Gebäude produzieren nur wenn explizit gestartet:

1. **Spieler wählt Menge** über Schieberegler (1-100)
2. **Spieler klickt "Produzieren"** → API-Call zu `/economy/production/start`
3. **Backend prüft Kosten** (Münzen + Ressourcen)
4. **Kosten werden sofort abgezogen**
5. **Produktions-Job wird erstellt** in `production_queue` Tabelle
   - `finishes_at` = jetzt + (Dauer × Menge)
6. **Job läuft im Hintergrund**
7. **Beim nächsten Polling** (`/economy/production/status`):
   - Abgeschlossene Jobs werden erkannt (`finishes_at <= now()`)
   - Ressourcen werden zum Inventar hinzugefügt
   - Job-Status wird auf `'completed'` gesetzt

### Polling-System

Im Frontend (`Main.gd`):
```gdscript
# Timer alle 5 Sekunden
poll_timer = Timer.new()
poll_timer.wait_time = 5.0
poll_timer.timeout.connect(_poll_production)

func _poll_production() -> void:
    var res := await Net.get_json("/economy/production/status")
    if res.ok and res.data.has("in_progress"):
        var in_progress = res.data.get("in_progress", [])
        if in_progress.size() > 0:
            await _sync_state()  # Holt abgeschlossene Produktion
```

## 4. Datenbank direkt aktualisieren (für Tests)

### Spieler Ressourcen geben

```sql
-- Wasser hinzufügen
INSERT INTO inventory(user_id, resource_type, amount)
VALUES ('user-uuid-hier', 'water', 1000)
ON CONFLICT (user_id, resource_type)
DO UPDATE SET amount = inventory.amount + 1000;

-- Münzen hinzufügen
UPDATE player_state 
SET coins = coins + 5000 
WHERE user_id = 'user-uuid-hier';
```

### Gebäude hinzufügen

```sql
INSERT INTO buildings(user_id, building_type, level)
VALUES ('user-uuid-hier', 'ironmine', 1)
ON CONFLICT (user_id, building_type) DO NOTHING;
```

### Aktive Produktionen ansehen

```sql
SELECT * FROM production_queue 
WHERE user_id = 'user-uuid-hier' 
AND status = 'in_progress';
```

## 5. Zusammenfassung: Datenfluss

```
Godot UI (GDScript)
    ↓ HTTP Request
Backend API (Node.js/Express)
    ↓ SQL Query
PostgreSQL Datenbank
    ↑ Result
Backend verarbeitet
    ↑ JSON Response
Godot aktualisiert UI
```

**Wichtige Dateien:**
- `backend/src/db.js` - Datenbank-Connection Pool
- `backend/src/routes/economy.js` - Gebäude & Produktion
- `backend/src/routes/state.js` - Spieler-Status abrufen
- `DB_Schema.md` - Tabellen-Definitionen
- `Scripts/Main.gd` - Frontend-Logik
- `autoload/net.gd` - HTTP API-Kommunikation

## 6. Häufige Fragen

**Q: Wie werden Daten gespeichert?**
A: Alle Spielerdaten werden in PostgreSQL gespeichert. Jede Aktion (Bauen, Produzieren, Verkaufen) führt eine Datenbank-Transaktion aus.

**Q: Kann ich die Datenbank-Struktur ändern?**
A: Ja, aber du musst:
1. `DB_Schema.md` aktualisieren
2. SQL-Migration erstellen und ausführen
3. Backend-Code anpassen (queries)
4. Frontend-Code anpassen (falls nötig)

**Q: Wie füge ich komplexe Produktionsketten hinzu?**
A: Erstelle mehrere Gebäude mit unterschiedlichen Input/Output-Ressourcen. Beispiel: Zementwerk braucht Kalkstein + Sand → produziert Zement.

**Q: Werden Daten zwischengespeichert?**
A: Nein, jede Anfrage holt frische Daten aus der Datenbank. Bei Bedarf könnte Redis für Caching hinzugefügt werden.

---

**Stand:** 2026-01-03  
**Aktuelle Version:** Manuelles Produktionssystem (Keine Idle-Produktion)
