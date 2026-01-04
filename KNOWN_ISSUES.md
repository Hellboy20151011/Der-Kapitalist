# Known Issues

## Production System Duplication

Es existieren zwei unterschiedliche Produktions-Implementierungen:

### 1. Production Router (`/production/*`)
- **Dateien**: `backend/src/routes/production.js`
- **Verwendung**: Aktuell vom Frontend genutzt
- **Mechanismus**: Nutzt `buildings.is_producing`, `ready_at`, `producing_qty` direkt in der `buildings` Tabelle
- **Endpoints**: 
  - `POST /production/start` - Startet Produktion
  - `POST /production/collect` - Sammelt fertige Produktion ein
- **Vorteile**: 
  - Einfacher, direkter Ansatz
  - Ein Gebäude = Eine Produktion
  - Weniger Tabellen
- **Nachteile**:
  - Nur eine Produktion pro Gebäude möglich
  - Keine Queue für mehrere Jobs

### 2. Economy Router Production (`/economy/production/*`)
- **Dateien**: `backend/src/routes/economy.js` (Zeilen 241-473)
- **Verwendung**: Aktuell NICHT vom Frontend genutzt
- **Mechanismus**: Nutzt separate `production_queue` Tabelle für Jobs
- **Endpoints**:
  - `POST /economy/production/start` - Startet Produktions-Job
  - `GET /economy/production/status` - Zeigt aktive Produktionen
- **Vorteile**:
  - Queue-System für mehrere Jobs
  - Komplexere Produktionsrezepte (Input-Ressourcen + Output)
  - Erweiterbarer
- **Nachteile**:
  - Komplexer
  - Zusätzliche Tabelle nötig

## Empfehlung

**Kurzfristig**: Behalte beide Systeme, aber:
1. ✅ Dokumentiere die Existenz beider Systeme
2. Verwende `/production/*` (aktuell im Frontend)
3. Deprecate `/economy/production/*` oder nutze es für zukünftige Features

**Langfristig** (größeres Refactoring):
1. Entscheide dich für ein System basierend auf Spiel-Design
2. Wenn Queues gewünscht: Migriere zu `production_queue` System
3. Wenn simpler besser: Entferne `production_queue` Tabelle und `/economy/production/*`

## Status Tracking

Die automatische Collection (auto-collect) passiert in:
- `/state` endpoint: Sammelt fertige Produktionen automatisch ein
- `state.js` Zeilen 34-73: Auto-collect Logik für `buildings.is_producing`

## Fazit

Aktuell ist das **Production Router System** (`/production/*`) aktiv und funktioniert.
Das **Economy Production System** (`/economy/production/*`) ist implementiert aber ungenutzt.

**Action Items**:
- [ ] Im Frontend entweder ganz auf `/production/*` ODER `/economy/production/*` setzen
- [ ] Den ungenutzten Code entweder löschen oder mit einem klaren Kommentar als "future feature" markieren
- [ ] Tests schreiben um sicherzustellen dass nur ein System verwendet wird

## net.gd Deprecation

**Status**: ✅ Resolved

Das veraltete `net.gd` Autoload wurde aus dem Projekt entfernt:
- ✅ Aus `project.godot` Autoloads entfernt
- ✅ Datei mit Deprecation-Kommentar versehen (kann später gelöscht werden)
- ✅ Keine aktiven Verwendungen im Code gefunden
- ✅ README.md aktualisiert

**Migration**: Alle Netzwerk-Calls verwenden jetzt `Api.gd` mit typed methods.
