/**
 * Review Model - Customer reviews for foods and restaurants
 */
const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
  restaurant: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant' },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: '' },
  images: [{ type: String }]
}, { timestamps: true });

module.exports = mongoose.model('Review', reviewSchema);
