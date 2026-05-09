/**
 * Socket.IO Middleware
 * Handles authentication and authorization for WebSocket connections
 */
const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * Authenticate socket connection using JWT token
 */
const authenticateSocket = async (socket, next) => {
  try {
    const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];

    if (!token) {
      // Allow guest connections for dine-in support
      socket.user = { 
        _id: 'guest_' + Math.random().toString(36).substring(2, 9),
        name: 'Guest',
        role: 'user',
        isGuest: true
      };
      socket.userId = socket.user._id;
      socket.userRole = 'user';
      console.log(`[SOCKET] Guest connected: ${socket.id}`);
      return next();
    }

    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const user = await User.findById(decoded.id).select('-password');
    
    if (!user) {
      // If token is invalid/user deleted, still allow as guest rather than blocking
      socket.user = { _id: 'guest_fallback', name: 'Guest', role: 'user', isGuest: true };
      socket.userId = 'guest_fallback';
      socket.userRole = 'user';
      return next();
    }

    // Attach user to socket
    socket.user = user;
    socket.userId = user._id.toString();
    socket.userRole = user.role;
    
    console.log(`[SOCKET] User authenticated: ${user.name} (${user.role})`);
    next();
  } catch (error) {
    console.error('[SOCKET] Authentication error:', error.message);
    // On error, allow as guest instead of disconnecting
    socket.user = { _id: 'guest_error_fallback', name: 'Guest', role: 'user', isGuest: true };
    socket.userId = 'guest_error_fallback';
    socket.userRole = 'user';
    next();
  }
};

/**
 * Authorize room subscription based on user role and room type
 */
const authorizeRoom = (socket, roomName) => {
  const user = socket.user;
  
  // Parse room name (format: "type:id")
  const [roomType, roomId] = roomName.split(':');
  
  switch (roomType) {
    case 'table':
      // Customers can join table rooms if they have an active order
      // Restaurant staff can join any table room for their restaurant
      if (user.role === 'restaurant') {
        return true; // Restaurant staff can access all their tables
      }
      // For customers, we'll verify they have an active order in the join handler
      return true;
      
    case 'kitchen':
      // Only restaurant staff can join kitchen rooms for their restaurant
      if (user.role === 'restaurant' && user._id.toString() === roomId) {
        return true;
      }
      return false;
      
    case 'restaurant-admin':
      // Only restaurant staff can join admin rooms for their restaurant
      if (user.role === 'restaurant' && user._id.toString() === roomId) {
        return true;
      }
      return false;
      
    default:
      console.warn(`[SOCKET] Unknown room type: ${roomType}`);
      return false;
  }
};

/**
 * Rate limiting for socket events
 */
class RateLimiter {
  constructor() {
    this.requests = new Map(); // socketId -> { count, resetTime }
    this.maxRequests = 100; // Max requests per window
    this.windowMs = 60000; // 1 minute window
  }

  check(socketId) {
    const now = Date.now();
    const record = this.requests.get(socketId);

    if (!record || now > record.resetTime) {
      // New window
      this.requests.set(socketId, {
        count: 1,
        resetTime: now + this.windowMs
      });
      return true;
    }

    if (record.count >= this.maxRequests) {
      return false; // Rate limit exceeded
    }

    record.count++;
    return true;
  }

  cleanup() {
    const now = Date.now();
    for (const [socketId, record] of this.requests.entries()) {
      if (now > record.resetTime) {
        this.requests.delete(socketId);
      }
    }
  }
}

const rateLimiter = new RateLimiter();

// Cleanup rate limiter every 5 minutes
setInterval(() => rateLimiter.cleanup(), 5 * 60 * 1000);

module.exports = {
  authenticateSocket,
  authorizeRoom,
  rateLimiter
};
