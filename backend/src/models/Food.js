/**
 * Food Model - Enhanced with hotel/admin reference
 */
const mongoose = require('mongoose');

const foodSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true, maxlength: 100 },
  description: { type: String, required: true, maxlength: 500 },
  price: { type: Number, required: true, min: 0 },
  // Link to admin user who owns this food item
  hotelId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  hotelName: { type: String, required: true, trim: true },
  image: { type: String, default: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400' },
  category: { type: String, default: 'General' },
  isAvailable: { type: Boolean, default: true },
  rating: { type: Number, default: 0, min: 0, max: 5 },
  totalRatings: { type: Number, default: 0 },
  preparationTime: { type: Number, default: 20 }, // minutes
  calories: { type: Number },
  isVegetarian: { type: Boolean, default: false },
  isSpicy: { type: Boolean, default: false },
  isFeatured: { type: Boolean, default: false },
  discount: { type: Number, default: 0, min: 0, max: 100 },
  allergens: [{ type: String }],
  ingredients: [{ type: String }],
  sizes: [{
    name: { type: String },
    price: { type: Number }
  }],
  addons: [{
    name: { type: String },
    price: { type: Number }
  }],
  // NEW: Barcode for scanning (unique index defined separately below)
  barcode: { type: String },
  // NEW: Menu types - food can be available for multiple menu types
  menuTypes: [{ 
    type: String, 
    enum: ['delivery', 'dine_in', 'takeaway'], 
    default: ['delivery', 'dine_in'] 
  }],
  // NEW: Dine-in specific pricing (optional, if different from delivery)
  dineInPrice: { type: Number },
  // Engagement metrics
  viewCount: { type: Number, default: 0 },
  likeCount: { type: Number, default: 0 },
  likedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  orderCount: { type: Number, default: 0 }
}, { timestamps: true });

// Index for efficient queries
foodSchema.index({ hotelId: 1, category: 1 });
foodSchema.index({ hotelName: 1 });
foodSchema.index({ likeCount: -1 });
foodSchema.index({ viewCount: -1 });
foodSchema.index({ barcode: 1 }, { unique: true, sparse: true }); // NEW: Unique index for barcode lookup
foodSchema.index({ menuTypes: 1 }); // NEW: Index for menu type filtering

module.exports = mongoose.model('Food', foodSchema);
