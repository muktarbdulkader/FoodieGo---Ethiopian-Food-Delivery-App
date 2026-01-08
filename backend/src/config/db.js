/**
 * Database Configuration
 * Handles MongoDB connection with automatic recovery
 */
const mongoose = require('mongoose');

let isConnected = false;
let reconnectAttempts = 0;
const MAX_RECONNECT_ATTEMPTS = 10;
const RECONNECT_INTERVAL = 5000; // 5 seconds

const connectDB = async () => {
  try {
    // Connection options for reliability
    const options = {
      maxPoolSize: 10,
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
      family: 4 // Use IPv4
    };

    const conn = await mongoose.connect(process.env.MONGODB_URI, options);
    isConnected = true;
    reconnectAttempts = 0;
    console.log(`[DB] MongoDB Connected: ${conn.connection.host}`);

    // Handle connection events for recovery
    mongoose.connection.on('disconnected', () => {
      console.log('[DB] MongoDB disconnected');
      isConnected = false;
      handleReconnect();
    });

    mongoose.connection.on('error', (err) => {
      console.error('[DB] MongoDB error:', err.message);
      isConnected = false;
    });

    mongoose.connection.on('reconnected', () => {
      console.log('[DB] MongoDB reconnected');
      isConnected = true;
      reconnectAttempts = 0;
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('[DB] MongoDB connection closed due to app termination');
      process.exit(0);
    });

  } catch (error) {
    console.error(`[DB] Connection error: ${error.message}`);
    handleReconnect();
  }
};

const handleReconnect = () => {
  if (reconnectAttempts < MAX_RECONNECT_ATTEMPTS) {
    reconnectAttempts++;
    console.log(`[DB] Attempting to reconnect (${reconnectAttempts}/${MAX_RECONNECT_ATTEMPTS})...`);
    setTimeout(connectDB, RECONNECT_INTERVAL);
  } else {
    console.error('[DB] Max reconnection attempts reached. Exiting...');
    process.exit(1);
  }
};

// Health check function
const isDBConnected = () => isConnected;

module.exports = { connectDB, isDBConnected };
