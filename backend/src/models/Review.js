/**
 * Review Model - Customer reviews for foods and restaurants
 */
const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
  restaurant: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant' },
  hotel: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  order: { type: mongoose.Schema.Types.ObjectId, ref: 'Order' },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: '' },
  images: [{ type: String }],
  // Engagement
  likeCount: { type: Number, default: 0 },
  likedBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  isVerifiedPurchase: { type: Boolean, default: false }
}, { timestamps: true });

// Index for efficient queries
reviewSchema.index({ food: 1, createdAt: -1 });
reviewSchema.index({ hotel: 1, createdAt: -1 });
reviewSchema.index({ user: 1 });

module.exports = mongoose.model('Review', reviewSchema);
