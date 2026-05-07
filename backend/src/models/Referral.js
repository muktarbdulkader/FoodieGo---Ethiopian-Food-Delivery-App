/**
 * Referral Model
 * Tracks user referrals and rewards
 */
const mongoose = require('mongoose');

const referralSchema = new mongoose.Schema({
  // The user who shared the code (referrer)
  referrer: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },

  // The user who signed up (referred user)
  referredUser: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },

  // Unique referral code used
  referralCode: {
    type: String,
    required: true,
    index: true
  },

  // Status tracking
  status: {
    type: String,
    enum: ['pending', 'registered', 'completed'],
    default: 'pending'
  },

  // Reward information
  rewardAmount: {
    type: Number,
    default: 30 // 50 ETB default reward
  },

  // Whether reward has been paid
  rewardPaid: {
    type: Boolean,
    default: false
  },

  // When referred user completed first order
  completedAt: {
    type: Date
  }
}, {
  timestamps: true
});

// Index for faster queries
referralSchema.index({ referrer: 1, status: 1 });
referralSchema.index({ referralCode: 1, status: 1 });
referralSchema.index({ referredUser: 1 });

module.exports = mongoose.model('Referral', referralSchema);
