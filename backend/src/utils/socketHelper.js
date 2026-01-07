// ============================================================================
// SOCKET HELPER - Utility functions for WebSocket communication
// ============================================================================
// Provides convenient methods for emitting events to users and channels
// ============================================================================

import { getIO, getUserSockets } from '../websocket.js';
import { logger } from '../logger.js';

/**
 * Emit event to a specific user (all their connected sockets)
 * @param {number} userId - The user ID to send to
 * @param {string} event - Event name
 * @param {object} data - Event payload
 * @returns {boolean} True if message was sent to at least one socket
 */
export function emitToUser(userId, event, data) {
  const io = getIO();
  if (!io) {
    logger.warn('WebSocket not initialized, cannot emit to user', { userId, event });
    return false;
  }

  const socketIds = getUserSockets(userId);
  if (socketIds.size === 0) {
    logger.debug('User has no active sockets', { userId, event });
    return false;
  }

  let sent = false;
  for (const socketId of socketIds) {
    io.to(socketId).emit(event, data);
    sent = true;
  }

  if (sent) {
    logger.debug('Emitted event to user', { userId, event, socketCount: socketIds.size });
  }

  return sent;
}

/**
 * Broadcast event to all connected users
 * @param {string} event - Event name
 * @param {object} data - Event payload
 * @returns {boolean} True if WebSocket is available
 */
export function broadcastToAll(event, data) {
  const io = getIO();
  if (!io) {
    logger.warn('WebSocket not initialized, cannot broadcast', { event });
    return false;
  }

  io.emit(event, data);
  logger.debug('Broadcast event to all clients', { event });
  return true;
}

/**
 * Broadcast event to all subscribers of a specific channel
 * @param {string} channel - Channel/room name (e.g., 'market', 'production')
 * @param {string} event - Event name
 * @param {object} data - Event payload
 * @returns {boolean} True if WebSocket is available
 */
export function broadcastToSubscribers(channel, event, data) {
  const io = getIO();
  if (!io) {
    logger.warn('WebSocket not initialized, cannot broadcast to channel', { channel, event });
    return false;
  }

  io.to(channel).emit(event, data);
  logger.debug('Broadcast event to channel', { channel, event });
  return true;
}
