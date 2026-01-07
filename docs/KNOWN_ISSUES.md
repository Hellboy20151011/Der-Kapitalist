# Known Issues

## ~~Production System Duplication~~ ✅ RESOLVED (2026-01-07)

**Status**: ✅ **RESOLVED** - Duplicate system removed in Phase 1 of refactoring roadmap

### Resolution

Das duplicate production system wurde entfernt:
- ✅ **Entfernt**: `economy.js` Zeilen 315-597 (~280 lines of duplicate code)
- ✅ **Entscheidung**: Production Router (`/production/*`) ist das offizielle System
- ✅ **Frontend**: Nutzt weiterhin `/production/*` endpoints (keine Änderungen nötig)
- ✅ **Backend**: Reduziert von 597 auf 333 Zeilen in economy.js

### Active Production System

**Production Router (`/production/*`)** - OFFICIAL SYSTEM
- **Dateien**: `backend/src/routes/production.js`
- **Verwendung**: Vom Frontend genutzt
- **Mechanismus**: Nutzt `buildings.is_producing`, `ready_at`, `producing_qty` direkt in der `buildings` Tabelle
- **Endpoints**: 
  - `POST /production/start` - Startet Produktion
  - `POST /production/collect` - Sammelt fertige Produktion ein
- **Vorteile**: 
  - Einfacher, direkter Ansatz
  - Ein Gebäude = Eine Produktion
  - Weniger Tabellen
  - Keine Verwirrung mehr über welches System aktiv ist

### Database Cleanup

**TODO**: Optional cleanup if production_queue table exists
- `production_queue` Tabelle kann aus der Datenbank entfernt werden
- Prüfen ob Daten vorhanden sind bevor Table gedropped wird
- Migration Script erstellen wenn nötig

### Status Tracking

Die automatische Collection (auto-collect) passiert in:
- `/state` endpoint: Sammelt fertige Produktionen automatisch ein
- `state.js` Zeilen 34-73: Auto-collect Logik für `buildings.is_producing`

---

## net.gd Deprecation

**Status**: ✅ Resolved

Das veraltete `net.gd` Autoload wurde aus dem Projekt entfernt:
- ✅ Aus `project.godot` Autoloads entfernt
- ✅ Datei mit Deprecation-Kommentar versehen (kann später gelöscht werden)
- ✅ Keine aktiven Verwendungen im Code gefunden
- ✅ README.md aktualisiert

**Migration**: Alle Netzwerk-Calls verwenden jetzt `Api.gd` mit typed methods.
