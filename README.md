# Der-Kapitalist

Ein Spiel wie Kapiland nur für Mobile Clients und als Lernprojekt.

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

Der-Kapitalist ist ein Wirtschaftsspiel, bei dem Spieler:
- Ressourcen produzieren (Wasser, Holz, Stein, etc.)
- Gebäude bauen und upgraden (Brunnen, Holzfäller, Steinmetz, etc.)
- **Manuelle Produktions-Jobs starten** - Produktion wird über Schieberegler gestartet und läuft für die gewählte Anzahl × Produktionszeit
- Ressourcen gegen Münzen verkaufen
- Mit anderen Spielern auf dem Marktplatz handeln
- **KEINE automatische Idle-Produktion** - Gebäude produzieren nur wenn Jobs manuell gestartet werden
