import { createApp } from './app.js';
import { config } from './config.js';
import { createServer } from 'http';
import { initializeWebSocket } from './websocket.js';

const app = createApp();
const httpServer = createServer(app);

// Initialize WebSocket server
initializeWebSocket(httpServer);

httpServer.listen(config.port, () => {
  console.log(`API listening on http://localhost:${config.port}`);
  console.log(`WebSocket server listening on ws://localhost:${config.port}`);
});