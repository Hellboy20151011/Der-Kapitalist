# Spieloberfläche Design

## Übersicht

Die neue Spieloberfläche wurde basierend auf dem Referenz-Screenshot neu gestaltet. Das Design folgt einem modernen, spielerischen Ansatz mit klarer visueller Hierarchie.

## Hauptkomponenten

### 1. Header-Leiste (Blau)
- **Position**: Oben auf dem Bildschirm
- **Höhe**: 120px
- **Hintergrundfarbe**: Blau (RGB: 0.2, 0.4, 0.8)
- **Inhalt**:
  - **Links**: Firmennamen und Statistiken
    - Firmenname: "DanielCorp"
    - Bargeld
    - Gesamtkapital
    - Anzahl Markt, Gebäude und Coins
  - **Rechts**: Navigations-Icons
    - Logout-Button
    - Statistiken (📊)
    - Gebäude (🏢)
    - Produktion (🔧)
    - Hilfe (❓)

### 2. Gebäude-Auswahl
- **Position**: Direkt unter der Header-Leiste
- **Höhe**: 60px
- **Hintergrundfarbe**: Dunkelgrau (RGB: 0.35, 0.35, 0.35)
- **Inhalt**: OptionButton zur Auswahl des aktiven Gebäudes

### 3. Gebäude-Icon-Leiste
- **Position**: Unter der Gebäude-Auswahl
- **Höhe**: 90px (70-160px vom oberen Rand)
- **Inhalt**: Horizontale Reihe von Icon-Buttons
  - Übersicht (🏠)
  - Brunnen (💧)
  - Holzfäller (🪓)
  - Steinmetz (🪨)
  - Fabrik (🏭)
  - Zurück (⏪)

### 4. Zentraler Spiel-Bereich
- **Position**: Hauptbereich zwischen Icon-Leiste und Status-Leiste
- **Hintergrundfarbe**: Braun/Beige (RGB: 0.6, 0.5, 0.4)
- **Inhalt**: 
  - Platzhalter für 3D/Isometrische Gebäude-Ansicht
  - Label: "Gebäude-Ansicht" (wird später durch tatsächliche Gebäude-Grafiken ersetzt)

### 5. Gebäude-Info-Dialog (Modal)
- **Position**: Zentriert über dem Spiel-Bereich
- **Größe**: 500x300px
- **Hintergrundfarbe**: Hellgrau (RGB: 0.95, 0.95, 0.95)
- **Inhalt**:
  - Titel (z.B. "Hallo", "Brunnen", etc.)
  - Beschreibung des Gebäudes
  - Informationen (Fläche, Arbeiter, Qualitätsstufe)
  - Handlungsaufforderung
  - Produkt-Buttons (P1, P2, P3 - Platzhalter)
  - Schließen-Button

### 6. Status-Leiste (Unten)
- **Position**: Am unteren Bildschirmrand
- **Höhe**: 80px
- **Hintergrundfarbe**: Hellgrau (RGB: 0.9, 0.9, 0.9)
- **Inhalt**: Status-Nachrichten und Feedback für den Spieler

## Legacy-UI

Die alte Benutzeroberfläche ist weiterhin im Code vorhanden (unter `LegacyUI`), aber standardmäßig unsichtbar. Dies ermöglicht:
- Einfaches Zurückwechseln zur alten UI bei Bedarf
- Zugriff auf alle bisherigen Funktionen
- Schrittweiser Übergang zur neuen UI

Um zur Legacy-UI zurückzukehren, setzen Sie die `visible`-Eigenschaft:
```gdscript
$LegacyUI.visible = true
$VBoxMain.visible = false
```

## Interaktive Elemente

### Neue UI-Handler-Funktionen
- `_show_stats()`: Zeigt Statistik-Panel (TODO)
- `_show_buildings_panel()`: Zeigt Gebäude-Panel und Info-Dialog
- `_show_production_panel()`: Zeigt Produktions-Panel (TODO)
- `_show_help()`: Zeigt Hilfe-Dialog (TODO)
- `_on_building_selected(index)`: Handler für Gebäude-Auswahl
- `_close_dialog()`: Schließt Info-Dialog
- `_on_home_icon_pressed()`: Kehrt zur Übersicht zurück
- `_on_well_icon_pressed()`: Zeigt Brunnen-Details
- `_on_lumber_icon_pressed()`: Zeigt Holzfäller-Details
- `_on_stone_icon_pressed()`: Zeigt Steinmetz-Details

## Farbschema

| Element | Farbe (RGB) | Hex |
|---------|-------------|-----|
| Header | (0.2, 0.4, 0.8) | #3366CC |
| Gebäude-Auswahl | (0.35, 0.35, 0.35) | #595959 |
| Spiel-Bereich | (0.6, 0.5, 0.4) | #998066 |
| Dialog-Hintergrund | (0.95, 0.95, 0.95) | #F2F2F2 |
| Status-Leiste | (0.9, 0.9, 0.9) | #E6E6E6 |
| Hintergrund | (0.85, 0.85, 0.85) | #D9D9D9 |

## Nächste Schritte

1. **3D/Isometrische Grafiken**: Ersetzen Sie den Platzhalter im zentralen Bereich durch tatsächliche Gebäude-Grafiken
2. **Produktions-Dialog**: Implementieren Sie den vollständigen Produktions-Dialog mit echten Produkten
3. **Animations**: Fügen Sie Übergänge und Animationen für Dialoge hinzu
4. **Mobile Optimierung**: Testen und optimieren Sie für verschiedene Bildschirmgrößen
5. **Touchscreen-Gesten**: Implementieren Sie Wisch- und Zoomgesten für mobile Geräte

## Technische Details

- **Engine**: Godot 4.5.1
- **Viewport**: 1080x1920 (Mobile Portrait)
- **Layout**: Responsive mit Anchors und Container-Nodes
- **Skriptsprache**: GDScript
