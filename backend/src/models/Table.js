/**
 * Table Model - For QR-based dine-in ordering
 */
const mongoose = require('mongoose');

const tableSchema = new mongoose.Schema({
  restaurantId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  tableNumber: { 
    type: String, 
    required: true 
  },
  qrCodeData: { 
    type: String, 
    required: true,
    unique: true 
  },
  capacity: { 
    type: Number, 
    default: 4 
  },
  isActive: { 
    type: Boolean, 
    default: true 
  },
  location: { 
    type: String, 
    default: '' 
  }, // e.g., "Ground Floor", "Terrace"
  currentSession: {
    isOccupied: { type: Boolean, default: false },
    customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    startTime: { type: Date },
    orderIds: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Order' }]
  }
}, { timestamps: true });

// Compound index for restaurant and table number
tableSchema.index({ restaurantId: 1, tableNumber: 1 }, { unique: true });

module.exports = mongoose.model('Table', tableSchema);
