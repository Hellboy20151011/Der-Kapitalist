// ============================================================================
// WEBSOCKET SERVER - Real-time Communication Layer
// ============================================================================
// Implements Socket.io for real-time updates:
// - Market listings (new, sold, expired)
// - Production job completion
// - Game state synchronization
// ============================================================================

import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { logger } from './logger.js';

let io = null;

// Store user -> socket mappings for targeted messages
// Map<userId, Set<socketId>>
const userSockets = new Map();

// Store socket subscriptions
// Map<socketId, Set<channel>>
const socketSubscriptions = new Map();

/**
 * Initialize Socket.io server with HTTP server
 * @param {import('http').Server} httpServer - The HTTP server instance
 */
export function initializeWebSocket(httpServer) {
  io = new Server(httpServer, {
    cors: {
      origin: config.allowedOrigins.length > 0 ? config.allowedOrigins : '*',
      credentials: true
    },
    // Connection timeout settings
    pingTimeout: 60000,
    pingInterval: 25000
  });

  // Authentication middleware
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    
    if (!token) {
      return next(new Error('missing_token'));
    }

    try {
      const payload = jwt.verify(token, config.jwtSecret);
      socket.userId = payload.sub;
      next();
    } catch (err) {
      return next(new Error('invalid_token'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    const userId = socket.userId;
    logger.info(`WebSocket client connected`, { userId, socketId: socket.id });

    // Register user socket mapping
    if (!userSockets.has(userId)) {
      userSockets.set(userId, new Set());
    }
    userSockets.get(userId).add(socket.id);

    // Initialize subscriptions for this socket
    socketSubscriptions.set(socket.id, new Set());

    // Handle subscribe to market updates
    socket.on('subscribe:market', () => {
      socket.join('market');
      socketSubscriptions.get(socket.id).add('market');
      logger.info('Client subscribed to market', { userId, socketId: socket.id });
      socket.emit('subscribed', { channel: 'market' });
    });

    // Handle subscribe to production updates
    socket.on('subscribe:production', () => {
      socket.join('production');
      socketSubscriptions.get(socket.id).add('production');
      logger.info('Client subscribed to production', { userId, socketId: socket.id });
      socket.emit('subscribed', { channel: 'production' });
    });

    // Handle ping for keep-alive
    socket.on('ping', () => {
      socket.emit('pong', { timestamp: new Date().toISOString() });
    });

    // Handle disconnection
    socket.on('disconnect', (reason) => {
      logger.info('WebSocket client disconnected', { userId, socketId: socket.id, reason });
      
      // Clean up user socket mapping
      const userSocketSet = userSockets.get(userId);
      if (userSocketSet) {
        userSocketSet.delete(socket.id);
        if (userSocketSet.size === 0) {
          userSockets.delete(userId);
        }
      }

      // Clean up subscriptions
      socketSubscriptions.delete(socket.id);
    });

    // Handle connection errors
    socket.on('error', (error) => {
      logger.error('WebSocket error', { userId, socketId: socket.id, error: error.message });
    });
  });

  logger.info('WebSocket server initialized');
  return io;
}

/**
 * Get the Socket.io instance
 * @returns {Server|null}
 */
export function getIO() {
  return io;
}

/**
 * Get all socket IDs for a specific user
 * @param {number} userId - The user ID
 * @returns {Set<string>} Set of socket IDs
 */
export function getUserSockets(userId) {
  return userSockets.get(userId) || new Set();
}

/**
 * Check if WebSocket server is initialized
 * @returns {boolean}
 */
export function isInitialized() {
  return io !== null;
}
