/**
 * Socket Manager
 * Singleton class for managing WebSocket connections and broadcasting events
 */

class SocketManager {
  constructor() {
    this.io = null;
    this.connections = new Map(); // userId -> socketId
  }

  /**
   * Initialize Socket Manager with Socket.IO instance
   */
  initialize(io) {
    this.io = io;
    console.log('[SOCKET MANAGER] Initialized');
  }

  /**
   * Get Socket.IO instance
   */
  getIO() {
    if (!this.io) {
      throw new Error('Socket Manager not initialized. Call initialize() first.');
    }
    return this.io;
  }

  /**
   * Register a socket connection
   */
  registerConnection(userId, socketId) {
    this.connections.set(userId, socketId);
    console.log(`[SOCKET MANAGER] Registered connection: ${userId} -> ${socketId}`);
  }

  /**
   * Unregister a socket connection
   */
  unregisterConnection(userId) {
    this.connections.delete(userId);
    console.log(`[SOCKET MANAGER] Unregistered connection: ${userId}`);
  }

  /**
   * Emit event to a specific room
   */
  emitToRoom(roomName, eventType, payload) {
    if (!this.io) {
      console.error('[SOCKET MANAGER] Cannot emit - not initialized');
      return;
    }

    try {
      this.io.to(roomName).emit(eventType, payload);
      console.log(`[SOCKET MANAGER] Emitted ${eventType} to room ${roomName}`);
    } catch (error) {
      console.error(`[SOCKET MANAGER] Error emitting to room ${roomName}:`, error.message);
    }
  }

  /**
   * Emit event to a specific user
   */
  emitToUser(userId, eventType, payload) {
    if (!this.io) {
      console.error('[SOCKET MANAGER] Cannot emit - not initialized');
      return;
    }

    const socketId = this.connections.get(userId);
    if (!socketId) {
      console.warn(`[SOCKET MANAGER] User ${userId} not connected`);
      return;
    }

    try {
      this.io.to(socketId).emit(eventType, payload);
      console.log(`[SOCKET MANAGER] Emitted ${eventType} to user ${userId}`);
    } catch (error) {
      console.error(`[SOCKET MANAGER] Error emitting to user ${userId}:`, error.message);
    }
  }

  /**
   * Broadcast to kitchen room for a specific restaurant
   */
  broadcastToKitchen(restaurantId, eventType, payload) {
    const roomName = `kitchen:${restaurantId}`;
    this.emitToRoom(roomName, eventType, payload);
  }

  /**
   * Broadcast to restaurant admin room
   */
  broadcastToRestaurantAdmin(restaurantId, eventType, payload) {
    const roomName = `restaurant-admin:${restaurantId}`;
    this.emitToRoom(roomName, eventType, payload);
  }

  /**
   * Broadcast to table room
   */
  broadcastToTable(tableId, eventType, payload) {
    const roomName = `table:${tableId}`;
    this.emitToRoom(roomName, eventType, payload);
  }

  /**
   * Get connection count
   */
  getConnectionCount() {
    return this.connections.size;
  }

  /**
   * Get all connected user IDs
   */
  getConnectedUsers() {
    return Array.from(this.connections.keys());
  }

  /**
   * Check if user is connected
   */
  isUserConnected(userId) {
    return this.connections.has(userId);
  }

  /**
   * Validate event payload
   */
  validateEventPayload(eventType, payload) {
    // Basic validation - ensure required fields exist
    if (!payload || typeof payload !== 'object') {
      return { valid: false, error: 'Payload must be an object' };
    }

    if (!payload.timestamp) {
      payload.timestamp = new Date().toISOString();
    }

    // Event-specific validation
    switch (eventType) {
      case 'order:created':
      case 'order:updated':
        if (!payload.orderId || !payload.orderNumber) {
          return { valid: false, error: 'orderId and orderNumber are required' };
        }
        break;

      case 'waiter:called':
        if (!payload.tableId || !payload.tableNumber) {
          return { valid: false, error: 'tableId and tableNumber are required' };
        }
        break;

      case 'table:occupied':
      case 'table:available':
        if (!payload.tableId || !payload.tableNumber) {
          return { valid: false, error: 'tableId and tableNumber are required' };
        }
        break;
    }

    return { valid: true, payload };
  }
}

// Export singleton instance
module.exports = new SocketManager();
