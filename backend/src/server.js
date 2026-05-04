/**
 * Server Entry Point
 * Starts the Express server and connects to MongoDB
 * Implements graceful shutdown and recovery
 */
require('dotenv').config();
const http = require('http');
const app = require('./app');
const { connectDB, isDBConnected } = require('./config/db');
const { initializeSocketServer } = require('./socket/socket.server');

const PORT = process.env.PORT || 5000;

// Track server instance for graceful shutdown
let server;
let io;

// Connect to database and start server
const startServer = async () => {
  try {
    await connectDB();
    
    // Create HTTP server
    server = http.createServer(app);
    
    // Initialize WebSocket server
    io = initializeSocketServer(server);
    
    // Start listening
    server.listen(PORT, () => {
      console.log(`[SERVER] Running on port ${PORT}`);
      console.log(`[SERVER] API available at http://localhost:${PORT}/api`);
      console.log(`[SERVER] WebSocket server ready`);
      console.log(`[SERVER] Environment: ${process.env.NODE_ENV || 'development'}`);
    });

    // Handle server errors
    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`[SERVER] Port ${PORT} is already in use`);
        process.exit(1);
      }
      console.error('[SERVER] Error:', error.message);
    });

  } catch (error) {
    console.error('[SERVER] Failed to start:', error.message);
    process.exit(1);
  }
};

// Graceful shutdown handler
const gracefulShutdown = async (signal) => {
  console.log(`\n[SERVER] ${signal} received. Starting graceful shutdown...`);
  
  if (io) {
    console.log('[SERVER] Closing WebSocket connections...');
    io.close(() => {
      console.log('[SERVER] WebSocket server closed');
    });
  }
  
  if (server) {
    server.close(() => {
      console.log('[SERVER] HTTP server closed');
      process.exit(0);
    });

    // Force close after 10 seconds
    setTimeout(() => {
      console.error('[SERVER] Forcing shutdown after timeout');
      process.exit(1);
    }, 10000);
  } else {
    process.exit(0);
  }
};

// Handle shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('[SERVER] Uncaught Exception:', error);
  gracefulShutdown('uncaughtException');
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('[SERVER] Unhandled Rejection at:', promise, 'reason:', reason);
});

// Add health check endpoint that includes DB status
app.get('/api/health', (req, res) => {
  res.json({
    status: isDBConnected() ? 'healthy' : 'degraded',
    database: isDBConnected() ? 'connected' : 'disconnected',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

startServer();
