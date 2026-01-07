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
  }]
}, { timestamps: true });

// Index for efficient queries
foodSchema.index({ hotelId: 1, category: 1 });
foodSchema.index({ hotelName: 1 });

module.exports = mongoose.model('Food', foodSchema);
