# Produktions-Checkliste für Der-Kapitalist

Diese Checkliste hilft dabei, das Projekt sicher in Produktion zu bringen.

## Phase 1: Vorbereitung (vor Deployment) ⚠️

### Sicherheit
- [ ] **Rate Limiting installiert und konfiguriert**
  ```bash
  npm install express-rate-limit
  ```
  - [ ] Login: Max 5 Versuche pro 15 Minuten
  - [ ] Register: Max 3 Versuche pro Stunde
  - [ ] API: Max 100 Requests pro Minute

- [ ] **CORS konfiguriert**
  ```bash
  npm install cors
  ```
  - [ ] Whitelist für erlaubte Origins
  - [ ] Credentials richtig gesetzt

- [ ] **Helmet.js installiert**
  ```bash
  npm install helmet
  ```
  - [ ] Security Headers aktiviert
  - [ ] CSP konfiguriert

- [ ] **HTTPS eingerichtet**
  - [ ] SSL/TLS-Zertifikat (Let's Encrypt)
  - [ ] Reverse Proxy (nginx/Caddy)
  - [ ] HTTP zu HTTPS Redirect

- [ ] **JWT_SECRET generiert**
  ```bash
  openssl rand -base64 32
  ```
  - [ ] Mindestens 32 Bytes
  - [ ] Nirgends im Code
  - [ ] Sicher gespeichert

### Logging & Monitoring
- [ ] **Logging-System**
  ```bash
  npm install winston
  ```
  - [ ] Strukturiertes Logging
  - [ ] Log-Levels konfiguriert
  - [ ] Rotation aktiviert

- [ ] **Error-Tracking**
  - [ ] Sentry oder ähnlich
  - [ ] API-Key konfiguriert
  - [ ] Source-Maps hochgeladen

- [ ] **Monitoring**
  - [ ] Uptime-Monitor (UptimeRobot, Pingdom)
  - [ ] Performance-Monitoring
  - [ ] Alert-System konfiguriert

### Datenbank
- [ ] **Produktions-Datenbank eingerichtet**
  - [ ] Starkes Passwort
  - [ ] SSL-Verbindung
  - [ ] Nur von App-Server erreichbar

- [ ] **Backup-System**
  - [ ] Automatische tägliche Backups
  - [ ] Off-site Storage
  - [ ] Backup-Restore getestet!

- [ ] **Connection-Pool optimiert**
  - [ ] Max Connections gesetzt
  - [ ] Idle Timeout konfiguriert

### Environment
- [ ] **Produktions-.env erstellt**
  - [ ] Alle Variablen gesetzt
  - [ ] Keine Default-Werte
  - [ ] Nie committen!

- [ ] **Node-Version spezifiziert**
  - [ ] In package.json: `"engines": {"node": ">=18"}`
  - [ ] Auf Server installiert

## Phase 2: Deployment 🚀

### Server
- [ ] **Server vorbereitet**
  - [ ] Linux-Server (Ubuntu/Debian)
  - [ ] Firewall konfiguriert (ufw)
  - [ ] Nur Port 22, 80, 443 offen
  - [ ] SSH-Key-Auth (kein Passwort)

- [ ] **Dependencies installiert**
  - [ ] Node.js 18+
  - [ ] PostgreSQL 14+
  - [ ] nginx/Caddy
  - [ ] PM2 oder systemd

- [ ] **Reverse Proxy konfiguriert**
  ```nginx
  server {
      listen 443 ssl http2;
      server_name api.dein-domain.de;
      
      ssl_certificate /path/to/cert.pem;
      ssl_certificate_key /path/to/key.pem;
      
      location / {
          proxy_pass http://localhost:3000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection 'upgrade';
          proxy_set_header Host $host;
          proxy_cache_bypass $http_upgrade;
      }
  }
  ```

### Application
- [ ] **Code deployed**
  ```bash
  git clone <repo>
  cd backend
  npm ci --production
  ```

- [ ] **.env konfiguriert**
  - [ ] DATABASE_URL (Produktions-DB)
  - [ ] JWT_SECRET (stark!)
  - [ ] PORT (3000)
  - [ ] NODE_ENV=production

- [ ] **Prozess-Manager**
  ```bash
  npm install -g pm2
  pm2 start src/Server.js --name der-kapitalist
  pm2 startup
  pm2 save
  ```

### Testing
- [ ] **Health-Check**
  ```bash
  curl https://api.dein-domain.de/health
  # Sollte {"ok":true} zurückgeben
  ```

- [ ] **Registrierung testen**
  ```bash
  curl -X POST https://api.dein-domain.de/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"test12345"}'
  ```

- [ ] **Login testen**
  ```bash
  curl -X POST https://api.dein-domain.de/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"test12345"}'
  ```

- [ ] **Geschützte Endpoints testen**
  ```bash
  curl https://api.dein-domain.de/state \
    -H "Authorization: Bearer <token>"
  ```

- [ ] **Produktions-System testen**
  ```bash
  # Gebäude bauen
  curl -X POST https://api.dein-domain.de/economy/buildings/build \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"building_type":"well"}'
  
  # Produktion starten
  curl -X POST https://api.dein-domain.de/economy/production/start \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"building_type":"well","quantity":5}'
  
  # Produktionsstatus abrufen
  curl https://api.dein-domain.de/economy/production/status \
    -H "Authorization: Bearer <token>"
  ```

- [ ] **Marktplatz-Funktionen testen**
  ```bash
  # Listings abrufen
  curl https://api.dein-domain.de/market/listings \
    -H "Authorization: Bearer <token>"
  
  # Listing erstellen
  curl -X POST https://api.dein-domain.de/market/listings \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"resource_type":"water","quantity":10,"price_per_unit":2}'
  ```

## Phase 3: Nach Deployment ✅

### Monitoring einrichten
- [ ] **Uptime-Monitoring aktiv**
- [ ] **Error-Rate überwacht**
- [ ] **Performance-Metriken überwacht**
- [ ] **Alert-Benachrichtigungen funktionieren**

### Dokumentation
- [ ] **Deployment-Prozess dokumentiert**
- [ ] **Rollback-Prozedur definiert**
- [ ] **Incident-Response-Plan**
- [ ] **Contact-Liste (On-Call)**

### Backup & Recovery
- [ ] **Erstes Backup erstellt**
- [ ] **Backup-Restore getestet**
- [ ] **Recovery-Zeit dokumentiert (RTO)**
- [ ] **Disaster-Recovery-Plan**

### Performance
- [ ] **Load-Testing durchgeführt**
  ```bash
  npm install -g autocannon
  autocannon -c 100 -d 30 https://api.dein-domain.de/health
  ```
- [ ] **Database-Indizes überprüft**
- [ ] **Slow-Query-Log analysiert**
- [ ] **Caching-Strategie überlegt**

## Phase 4: Optimierung 🔧

### Skalierung
- [ ] **Horizontal Scaling möglich**
  - [ ] Stateless Application
  - [ ] Load Balancer konfiguriert
  - [ ] Session-Management (Redis)

- [ ] **Database Scaling**
  - [ ] Read-Replicas erwogen
  - [ ] Connection-Pooling optimiert
  - [ ] Query-Performance überwacht

### Features
- [ ] **E-Mail-Verifizierung**
- [ ] **Password-Reset**
- [ ] **2FA (optional)**
- [ ] **Admin-Panel**

### Analytics
- [ ] **User-Analytics**
  - [ ] Registrierungen pro Tag
  - [ ] Active Users (DAU/MAU)
  - [ ] Retention Rate

- [ ] **Business-Metrics**
  - [ ] Engagement-Metriken
  - [ ] Progression-Tracking
  - [ ] Economy-Balance

## Phase 5: Wartung 🔄

### Regelmäßig
- [ ] **Wöchentlich**
  - [ ] Logs überprüfen
  - [ ] Error-Rate checken
  - [ ] Backups verifizieren

- [ ] **Monatlich**
  - [ ] Dependencies updaten
  - [ ] Security-Audit
  - [ ] Performance-Review

- [ ] **Quartalsweise**
  - [ ] Penetration-Testing
  - [ ] Disaster-Recovery-Drill
  - [ ] Kostenanalyse

### Updates
- [ ] **Prozess für Updates**
  1. Auf Staging testen
  2. Backup erstellen
  3. Deployment vorbereiten
  4. In Wartungsfenster deployen
  5. Smoke-Tests durchführen
  6. Monitoring beobachten
  7. Rollback-Plan bereit

## Zusätzliche Empfehlungen

### Compliance (EU/DSGVO)
- [ ] Datenschutzerklärung
- [ ] Nutzungsbedingungen
- [ ] Consent-Management
- [ ] Recht auf Löschung implementiert
- [ ] Datenexport-Funktion

### Kosten-Optimierung
- [ ] Server-Größe angepasst
- [ ] Auto-Scaling erwogen
- [ ] CDN für statische Assets
- [ ] Database-Kosten optimiert

### Developer-Experience
- [ ] CI/CD-Pipeline
- [ ] Staging-Environment
- [ ] Development-Guide
- [ ] Code-Review-Prozess

---

## Prioritäten-Übersicht

### MUST HAVE (vor Launch) 🔴
- HTTPS
- Rate Limiting
- JWT_SECRET stark
- Backups
- Monitoring

### SHOULD HAVE (erste Woche) 🟡
- Logging-System
- Error-Tracking
- Uptime-Monitoring
- Incident-Response-Plan

### NICE TO HAVE (erster Monat) 🟢
- Load-Testing
- CI/CD
- Admin-Panel
- Analytics

---

## Ressourcen

- [Backend README](backend/README.md)
- [Security Checklist](SECURITY.md)
- [Quick Start Guide](QUICKSTART.md)
- [Project Review](REVIEW.md)

---

**Viel Erfolg beim Launch! 🚀**

_Diese Checkliste sollte regelmäßig aktualisiert und an die Bedürfnisse des Projekts angepasst werden._
