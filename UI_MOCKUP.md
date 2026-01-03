# Visual Mockup der neuen Spieloberfläche

## Vollbildansicht (Portrait Mode - 1080x1920)

```
╔═══════════════════════════════════════════════════════════════╗
║                     🔵 HEADER BAR 🔵                          ║
║ ┌───────────────────────────────┬─────────────────────────┐   ║
║ │ DanielCorp                    │  [Logout]               │   ║
║ │ Bargeld: 6.701.210,79 €       │  ┌───┬───┬───┬───┐     │   ║
║ │ Gesamtkapital: 7.115.000,00 € │  │📊 │🏢 │🔧 │❓ │     │   ║
║ │ Markt: 0  Gebäude: 22         │  └───┴───┴───┴───┘     │   ║
║ │ Coins: 0                      │                         │   ║
║ └───────────────────────────────┴─────────────────────────┘   ║
╠═══════════════════════════════════════════════════════════════╣
║          ⚫ GEBÄUDE-AUSWAHL DROPDOWN ⚫                        ║
║  ╔═══════════════════════════════════════════════════════╗   ║
║  ║ Kraftwerk Einzugsgebiet (Frankreich:1427540)      ▼  ║   ║
║  ╚═══════════════════════════════════════════════════════╝   ║
╠═══════════════════════════════════════════════════════════════╣
║              GEBÄUDE-ICON-NAVIGATION                          ║
║   ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐                ║
║   │ 🏠 │ │ 💧 │ │ 🪓 │ │ 🪨 │ │ 🏭 │ │ ⏪ │                ║
║   └────┘ └────┘ └────┘ └────┘ └────┘ └────┘                ║
║   Home  Well  Lumber Stone Factory Back                      ║
╠═══════════════════════════════════════════════════════════════╣
║                                                               ║
║                                                               ║
║                                                               ║
║              🏭 ZENTRALER SPIEL-BEREICH 🏭                    ║
║                                                               ║
║           (Hier werden Gebäude dargestellt)                   ║
║                                                               ║
║     ╔═════════════════════════════════════════════╗          ║
║     ║        GEBÄUDE-INFO-DIALOG                  ║          ║
║     ║  ┌────────────────────────────────────────┐ ║          ║
║     ║  │           Hallo                        │ ║          ║
║     ║  ├────────────────────────────────────────┤ ║          ║
║     ║  │ Dies ist dein Kraftwerk -              │ ║          ║
║     ║  │ Produktionsgebäude in Frankreich       │ ║          ║
║     ║  │                                        │ ║          ║
║     ║  │ Dein Gebäude hat eine Fläche von 40m², │ ║          ║
║     ║  │ beschäftigt 4 Arbeiter und produziert  │ ║          ║
║     ║  │ aktuell Waren in der Qualitätsstufe Q0 │ ║          ║
║     ║  │                                        │ ║          ║
║     ║  │ Um die Produktion zu starten wähle     │ ║          ║
║     ║  │ bitte eines der Produkte unten         │ ║          ║
║     ║  │                                        │ ║          ║
║     ║  │      ┌────┐  ┌────┐  ┌────┐          │ ║          ║
║     ║  │      │ P1 │  │ P2 │  │ P3 │          │ ║          ║
║     ║  │      └────┘  └────┘  └────┘          │ ║          ║
║     ║  │                                        │ ║          ║
║     ║  │        [ Schließen ]                   │ ║          ║
║     ║  └────────────────────────────────────────┘ ║          ║
║     ╚═════════════════════════════════════════════╝          ║
║                                                               ║
║                                                               ║
║                                                               ║
╠═══════════════════════════════════════════════════════════════╣
║                    STATUS-LEISTE                              ║
║              Gebäude ausgewählt: Kraftwerk                    ║
╚═══════════════════════════════════════════════════════════════╝
```

## Farbcodierung

```
🔵 Blau (Header)          - RGB(0.2, 0.4, 0.8) = #3366CC
⚫ Dunkelgrau (Dropdown)   - RGB(0.35, 0.35, 0.35) = #595959
🟤 Braun/Beige (Game Area) - RGB(0.6, 0.5, 0.4) = #998066
⚪ Hellgrau (Dialog)       - RGB(0.95, 0.95, 0.95) = #F2F2F2
◻️  Hellgrau (Status)      - RGB(0.9, 0.9, 0.9) = #E6E6E6
```

## Interaktive Elemente

### Header-Buttons (rechts oben)
```
┌───────────────────────────────┐
│ [Logout]                      │ ← Logout-Button
│ ┌───┬───┬───┬───┐            │
│ │📊 │🏢 │🔧 │❓ │            │ ← Navigation-Icons
│ └───┴───┴───┴───┘            │
│ Stats │   │   Help            │
│      Bldgs Prod               │
└───────────────────────────────┘
```

### Gebäude-Icon-Bar
```
[🏠]  →  Übersicht/Home
[💧]  →  Brunnen (Well)
[🪓]  →  Holzfäller (Lumberjack)
[🪨]  →  Steinmetz (Stonemason)
[🏭]  →  Fabrik/Kraftwerk (Factory)
[⏪]  →  Zurück (Back)
```

### Dialog-Buttons
```
┌────────────────────────┐
│  [P1]  [P2]  [P3]     │ ← Produkt-Buttons
│                        │
│   [ Schließen ]        │ ← Dialog schließen
└────────────────────────┘
```

## Responsive Verhalten

### Viewport-Größe: 1080x1920 (Standard Mobile Portrait)

```
Header:           120px Höhe (fest)
Dropdown:          60px Höhe (fest)
Icon-Bar:          90px Höhe (fest)
Spiel-Bereich:    ~1570px Höhe (flexibel, füllt verbleibenden Raum)
Status:            80px Höhe (fest)
```

## Zustandsänderungen

### 1. Dialog geschlossen (Standard)
```
┌────────────────────┐
│                    │
│  SPIEL-BEREICH     │
│                    │
│  (Gebäude-Ansicht) │
│                    │
│                    │
└────────────────────┘
```

### 2. Dialog geöffnet (bei Klick auf Gebäude-Icon)
```
┌────────────────────┐
│                    │
│  ╔════════════╗    │
│  ║  DIALOG    ║    │
│  ║            ║    │
│  ║ [Buttons]  ║    │
│  ╚════════════╝    │
│                    │
└────────────────────┘
```

## Icon-Bedeutungen

| Icon | Name | Funktion | Status |
|------|------|----------|--------|
| 📊 | Stats | Zeigt Statistiken | TODO |
| 🏢 | Buildings | Zeigt Gebäude-Panel | ✅ Implementiert |
| 🔧 | Production | Zeigt Produktions-Panel | TODO |
| ❓ | Help | Zeigt Hilfe | TODO |
| 🏠 | Home | Übersicht | ✅ Implementiert |
| 💧 | Well | Brunnen | ✅ Implementiert |
| 🪓 | Lumber | Holzfäller | ✅ Implementiert |
| 🪨 | Stone | Steinmetz | ✅ Implementiert |
| 🏭 | Factory | Fabrik/Kraftwerk | Platzhalter |
| ⏪ | Back | Zurück | Platzhalter |

## Animation-Konzept (Future)

### Dialog Ein/Aus
```
Geschlossen:  opacity=0, scale=0.8
    ↓ 0.3s ease-out
Geöffnet:     opacity=1, scale=1.0
```

### Button-Feedback
```
Normal:   scale=1.0
    ↓ 0.1s
Pressed:  scale=0.95
    ↓ 0.1s
Normal:   scale=1.0
```

### Status-Update
```
Neue Nachricht:  fade in from bottom
Nach 3s:         fade out
```

## Mobile Touch-Bereiche

Alle interaktiven Elemente haben Mindestgrößen für Touch:
- Header-Buttons: 70x70px
- Gebäude-Icons: 80x80px
- Dialog-Buttons: 60x60px minimum
- Logout-Button: 80x40px

## Vergleich zum Referenz-Screenshot

✅ **Implementiert:**
- Blauer Header mit Firmeninfo
- Navigations-Icons rechts
- Gebäude-Dropdown
- Icon-Leiste für Gebäude
- Info-Dialog mit Details
- Status-Bereich unten

⏳ **Platzhalter/TODO:**
- 3D/Isometrische Gebäude-Grafiken im zentralen Bereich
- Echte Icon-Grafiken statt Emojis
- Zusätzliche Panels (Stats, Production, Help)
- Animationen und Übergänge
