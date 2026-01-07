/**
 * Restaurant Model - For multi-restaurant support
 */
const mongoose = require('mongoose');

const restaurantSchema = new mongoose.Schema({
  name: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  image: { type: String, default: '' },
  address: { type: String, required: true },
  phone: { type: String, required: true },
  email: { type: String, required: true },
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  rating: { type: Number, default: 0, min: 0, max: 5 },
  totalRatings: { type: Number, default: 0 },
  cuisine: [{ type: String }],
  openingHours: {
    open: { type: String, default: '09:00' },
    close: { type: String, default: '22:00' }
  },
  deliveryFee: { type: Number, default: 2.99 },
  minOrder: { type: Number, default: 10 },
  isActive: { type: Boolean, default: true },
  isFeatured: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('Restaurant', restaurantSchema);
