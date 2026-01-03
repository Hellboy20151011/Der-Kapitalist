# Der-Kapitalist

Ein Spiel wie Kaipland nur für Mobile Clients und als Lernprojekt.

## Projektstruktur

- **backend/** - Node.js/Express API Server
- **autoload/** - Godot Autoload-Skripte (net.gd für API-Kommunikation)
- **DB_Schema.md** - PostgreSQL Datenbankschema

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

## Spielmechanik

Der-Kapitalist ist ein Idle-/Wirtschaftsspiel, bei dem Spieler:
- Ressourcen produzieren (Wasser, Holz, Stein)
- Gebäude bauen und upgraden (Brunnen, Holzfäller, Steinmetz)
- Ressourcen gegen Münzen verkaufen
- Offline-Produktion für bis zu 8 Stunden erhalten
