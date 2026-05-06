/**
 * WebSocket Server
 * Initializes Socket.IO server and handles connection events
 */
const { Server } = require('socket.io');
const { authenticateSocket, authorizeRoom, rateLimiter } = require('../middlewares/socket.middleware');
const socketManager = require('./socket.manager');
const Order = require('../models/Order');

/**
 * Initialize Socket.IO server
 */
function initializeSocketServer(httpServer) {
  const io = new Server(httpServer, {
    cors: {
      origin: process.env.FRONTEND_URL || '*',
      methods: ['GET', 'POST'],
      credentials: true
    },
    pingTimeout: 60000,
    pingInterval: 25000,
    transports: ['websocket', 'polling']
  });

  // Initialize Socket Manager
  socketManager.initialize(io);

  // Authentication middleware
  io.use(authenticateSocket);

  // Connection handler
  io.on('connection', (socket) => {
    const user = socket.user;
    console.log(`[SOCKET] Client connected: ${user.name} (${user.role}) - Socket ID: ${socket.id}`);

    // Register connection
    socketManager.registerConnection(user._id.toString(), socket.id);

    // Send connection established event
    socket.emit('connection:established', {
      eventType: 'connection:established',
      clientId: socket.id,
      userId: user._id.toString(),
      userName: user.name,
      userRole: user.role,
      timestamp: new Date().toISOString()
    });

    // Handle room join requests
    socket.on('join:room', async (data) => {
      try {
        const { roomName } = data;

        if (!roomName) {
          socket.emit('error', { message: 'Room name is required' });
          return;
        }

        // Check rate limit
        if (!rateLimiter.check(socket.id)) {
          socket.emit('error', { message: 'Rate limit exceeded. Please slow down.' });
          return;
        }

        // Authorize room access
        if (!authorizeRoom(socket, roomName)) {
          socket.emit('error', { 
            message: 'Unauthorized access to room',
            roomName 
          });
          console.warn(`[SOCKET] Unauthorized room access attempt: ${user.name} -> ${roomName}`);
          return;
        }

        // For table rooms, verify customer has an active order
        if (roomName.startsWith('table:') && user.role !== 'restaurant') {
          const tableId = roomName.split(':')[1];
          const hasActiveOrder = await Order.findOne({
            tableId,
            status: { $nin: ['completed', 'cancelled'] }
          });

          if (!hasActiveOrder) {
            socket.emit('error', { 
              message: 'No active order for this table',
              roomName 
            });
            return;
          }
        }

        // Join the room
        socket.join(roomName);
        console.log(`[SOCKET] ${user.name} joined room: ${roomName}`);

        socket.emit('room:joined', {
          roomName,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('[SOCKET] Error joining room:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    // Handle room leave requests
    socket.on('leave:room', (data) => {
      try {
        const { roomName } = data;

        if (!roomName) {
          socket.emit('error', { message: 'Room name is required' });
          return;
        }

        socket.leave(roomName);
        console.log(`[SOCKET] ${user.name} left room: ${roomName}`);

        socket.emit('room:left', {
          roomName,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('[SOCKET] Error leaving room:', error);
        socket.emit('error', { message: 'Failed to leave room' });
      }
    });

    // Handle chat messages
    socket.on('chat:message', (data) => {
      try {
        const { orderId, message, senderRole, type, metadata } = data;
        
        if (!orderId) {
          socket.emit('error', { message: 'Order ID is required for chat' });
          return;
        }

        // Broadcast to order room
        const roomName = `order:${orderId}`;
        io.to(roomName).emit('chat:message', {
          orderId,
          id: data.id,
          message,
          sender: user.name,
          senderRole: senderRole || user.role,
          type: type || 'text',
          timestamp: new Date().toISOString(),
          metadata
        });

        console.log(`[SOCKET] Chat message sent in order ${orderId} by ${user.name}`);
      } catch (error) {
        console.error('[SOCKET] Error handling chat message:', error);
        socket.emit('error', { message: 'Failed to send chat message' });
      }
    });

    // Handle driver location updates
    socket.on('driver:location', (data) => {
      try {
        const { orderId, location, driverName } = data;
        
        if (!orderId || !location) {
          socket.emit('error', { message: 'Order ID and location are required' });
          return;
        }

        // Broadcast to order room
        const roomName = `order:${orderId}`;
        io.to(roomName).emit('driver:location', {
          orderId,
          driverId: user._id.toString(),
          driverName: driverName || user.name,
          location,
          timestamp: new Date().toISOString()
        });

        console.log(`[SOCKET] Driver location updated for order ${orderId}`);
      } catch (error) {
        console.error('[SOCKET] Error handling driver location:', error);
        socket.emit('error', { message: 'Failed to update location' });
      }
    });

    // Handle ping/pong for connection health
    socket.on('ping', () => {
      socket.emit('pong', { timestamp: new Date().toISOString() });
    });

    // Handle disconnection
    socket.on('disconnect', (reason) => {
      console.log(`[SOCKET] Client disconnected: ${user.name} - Reason: ${reason}`);
      socketManager.unregisterConnection(user._id.toString());
    });

    // Handle errors
    socket.on('error', (error) => {
      console.error(`[SOCKET] Socket error for ${user.name}:`, error);
    });
  });

  // Log connection metrics every 60 seconds
  setInterval(() => {
    const connectionCount = socketManager.getConnectionCount();
    console.log(`[SOCKET] Active connections: ${connectionCount}`);
  }, 60000);

  console.log('[SOCKET] WebSocket server initialized');
  return io;
}

module.exports = { initializeSocketServer };
