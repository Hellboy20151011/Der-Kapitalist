# Der-Kapitalist - Schnellstart-Anleitung

## Voraussetzungen

- Node.js 18+ ([Download](https://nodejs.org/))
- PostgreSQL 14+ ([Download](https://www.postgresql.org/download/))
- Godot Engine 4+ ([Download](https://godotengine.org/download/)) - für Client-Entwicklung

## Setup in 5 Minuten

### 1. Repository klonen

```bash
git clone https://github.com/Hellboy20151011/Der-Kapitalist.git
cd Der-Kapitalist
```

### 2. Datenbank einrichten

```bash
# PostgreSQL starten
# Datenbank erstellen
createdb der_kapitalist

# Schema importieren (DB_Schema.md enthält reines SQL)
psql der_kapitalist < DB_Schema.md
```

### 3. Backend konfigurieren

```bash
cd backend

# Dependencies installieren
npm install

# .env Datei erstellen
cp .env.example .env

# .env bearbeiten und anpassen:
# - DATABASE_URL: postgresql://user:password@localhost:5432/der_kapitalist
# - JWT_SECRET: einen sicheren zufälligen String generieren
```

### 4. Backend starten

```bash
npm start
# oder für Entwicklung mit Hot-Reload:
npm run dev
```

Der Server läuft jetzt auf `http://localhost:3000`

### 5. API testen

```bash
# Health-Check
curl http://localhost:3000/health

# User registrieren
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Response enthält: {"token":"eyJhbG..."}
```

## Entwicklung

### Backend-Entwicklung

```bash
cd backend

# Mit Auto-Reload starten
npm run dev

# Code-Änderungen werden automatisch neu geladen
```

### API-Endpoints testen

#### Registrierung
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"player@test.com","password":"secure123"}'
```

#### Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"player@test.com","password":"secure123"}'
```

#### Spielzustand abrufen (benötigt Token)
```bash
TOKEN="dein-jwt-token-hier"
curl http://localhost:3000/state \
  -H "Authorization: Bearer $TOKEN"
```

#### Ressourcen verkaufen
```bash
curl -X POST http://localhost:3000/economy/sell \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resource_type":"water","quantity":10}'
```

#### Gebäude upgraden
```bash
curl -X POST http://localhost:3000/economy/buildings/upgrade \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"building_type":"well"}'
```

#### Markt-Listings anzeigen
```bash
curl http://localhost:3000/market/listings?resource_type=wood&limit=10 \
  -H "Authorization: Bearer $TOKEN"
```

#### Markt-Listing erstellen
```bash
curl -X POST http://localhost:3000/market/listings \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"resource_type":"wood","quantity":50,"price_per_unit":5}'
```

#### Markt-Listing kaufen
```bash
curl -X POST http://localhost:3000/market/listings/LISTING_ID/buy \
  -H "Authorization: Bearer $TOKEN"
```

### Frontend-Entwicklung (Godot)

1. Godot Engine 4+ öffnen
2. Projekt öffnen (Hauptverzeichnis)
3. `autoload/net.gd` ist bereits konfiguriert
4. `base_url` bei Bedarf anpassen

Beispiel-Verwendung in GDScript:
```gdscript
# Token nach Login speichern
Net.token = login_response.token

# Spielzustand abrufen
var state = await Net.get_json("/state")
if state.ok:
    print("Coins: ", state.data.coins)
    print("Inventory: ", state.data.inventory)

# Ressourcen verkaufen
var result = await Net.post_json("/economy/sell", {
    "resource_type": "wood",
    "quantity": 5
})

# Markt-Listings abrufen
var listings = await Net.get_json("/market/listings?resource_type=wood")
if listings.ok:
    for listing in listings.data.listings:
        print("Listing: ", listing.quantity, " wood für ", listing.price_per_unit, " pro Stück")

# Markt-Listing erstellen
var create_result = await Net.post_json("/market/listings", {
    "resource_type": "stone",
    "quantity": 100,
    "price_per_unit": 10
})

# Markt-Listing kaufen
var buy_result = await Net.post_json("/market/listings/%s/buy" % listing_id, {})
```

## Datenbank-Management

### Schema-Updates
```bash
# Aktuelle Tabellen anzeigen
psql der_kapitalist -c "\dt"

# Tabelle inspizieren
psql der_kapitalist -c "\d users"

# Query ausführen
psql der_kapitalist -c "SELECT * FROM users LIMIT 5;"
```

### Daten zurücksetzen (Vorsicht!)
```bash
# Alle Daten löschen
psql der_kapitalist -c "TRUNCATE users CASCADE;"

# Datenbank neu erstellen
dropdb der_kapitalist
createdb der_kapitalist
psql der_kapitalist < DB_Schema.md
```

## Spielmechanik

### Ressourcen
- **Wasser** (water): Produziert von Brunnen, Preis: 1 Münze
- **Holz** (wood): Produziert von Holzfällern, Preis: 3 Münzen
- **Stein** (stone): Produziert von Steinmetzen, Preis: 5 Münzen

### Gebäude
- **Brunnen** (well): Produziert Wasser
- **Holzfäller** (lumberjack): Produziert Holz
- **Steinmetz** (stonemason): Produziert Stein

### Progression
- Jedes Gebäude startet auf Level 1
- Upgrade-Kosten: `100 * 1.6^(level-1)` Münzen
- Produktion steigt mit Level: `base_rate * 1.15^(level-1)`
- Offline-Produktion: bis zu 8 Stunden

### Startwerte (Level 1)
- Brunnen: 30 Wasser/Minute
- Holzfäller: 15 Holz/Minute
- Steinmetz: 10 Stein/Minute

## Troubleshooting

### Backend startet nicht
```bash
# Prüfen ob Port 3000 frei ist
lsof -i :3000

# Node.js Version prüfen
node --version  # sollte >= 18 sein

# Dependencies neu installieren
rm -rf node_modules package-lock.json
npm install
```

### Datenbank-Verbindung schlägt fehl
```bash
# PostgreSQL-Status prüfen
systemctl status postgresql  # Linux
brew services list  # macOS

# Verbindung testen
psql -U postgres -c "SELECT version();"

# DATABASE_URL in .env prüfen
cat backend/.env
```

### Port bereits belegt
```bash
# In .env anderen Port setzen
PORT=3001

# Oder Prozess beenden
lsof -ti:3000 | xargs kill -9
```

## Weiterführende Dokumentation

- [Backend README](backend/README.md) - Detaillierte Backend-Dokumentation
- [REVIEW.md](REVIEW.md) - Vollständige Projekt-Analyse
- [SECURITY.md](SECURITY.md) - Sicherheits-Checkliste
- [DB_Schema.md](DB_Schema.md) - Datenbank-Schema

## Nächste Schritte

1. ✅ Backend läuft
2. ✅ API getestet
3. 🔜 Frontend mit Godot verbinden
4. 🔜 Gameplay implementieren
5. 🔜 Tests schreiben
6. 🔜 Produktions-Deployment vorbereiten

## Support

Bei Fragen oder Problemen:
- Issue erstellen auf GitHub
- Code reviewen in [REVIEW.md](REVIEW.md)
- Sicherheit prüfen in [SECURITY.md](SECURITY.md)

Viel Erfolg! 🎮
