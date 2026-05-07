/**
 * Loyalty Points Model
 * Tracks user points, tier status, and transactions
 */
const mongoose = require('mongoose');

const pointTransactionSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  type: {
    type: String,
    enum: ['earned', 'redeemed', 'bonus', 'expired', 'adjusted'],
    required: true
  },
  points: {
    type: Number,
    required: true
  },
  description: {
    type: String,
    required: true
  },
  orderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Order'
  },
  redemptionId: {
    type: String
  },
  expiresAt: {
    type: Date
  }
}, {
  timestamps: true
});

const loyaltyPointsSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  availablePoints: {
    type: Number,
    default: 0,
    min: 0
  },
  lifetimePoints: {
    type: Number,
    default: 0,
    min: 0
  },
  tier: {
    type: String,
    enum: ['Bronze', 'Silver', 'Gold', 'Platinum'],
    default: 'Bronze'
  },
  tierUpdatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Index for faster queries
loyaltyPointsSchema.index({ user: 1, tier: 1 });

// Method to update tier based on lifetime points
loyaltyPointsSchema.methods.updateTier = function() {
  const prevTier = this.tier;
  
  if (this.lifetimePoints >= 10000) {
    this.tier = 'Platinum';
  } else if (this.lifetimePoints >= 5000) {
    this.tier = 'Gold';
  } else if (this.lifetimePoints >= 1000) {
    this.tier = 'Silver';
  } else {
    this.tier = 'Bronze';
  }
  
  if (this.tier !== prevTier) {
    this.tierUpdatedAt = new Date();
  }
  
  return this.tier !== prevTier;
};

// Method to add points
loyaltyPointsSchema.methods.addPoints = function(points, description, orderId = null) {
  this.availablePoints += points;
  this.lifetimePoints += points;
  this.updateTier();
  
  return {
    user: this.user,
    type: 'earned',
    points: points,
    description: description,
    orderId: orderId,
    expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // 1 year expiry
  };
};

// Method to redeem points
loyaltyPointsSchema.methods.redeemPoints = function(points, description, redemptionId) {
  if (this.availablePoints < points) {
    throw new Error('Insufficient points');
  }
  
  this.availablePoints -= points;
  
  return {
    user: this.user,
    type: 'redeemed',
    points: -points,
    description: description,
    redemptionId: redemptionId
  };
};

// Static method to calculate points for an order
loyaltyPointsSchema.statics.calculatePoints = function(orderAmount, tier) {
  let multiplier = 1.0;
  
  switch (tier) {
    case 'Silver':
      multiplier = 1.5;
      break;
    case 'Gold':
      multiplier = 2.0;
      break;
    case 'Platinum':
      multiplier = 3.0;
      break;
  }
  
  return Math.floor((orderAmount / 10) * multiplier);
};

const LoyaltyPoints = mongoose.model('LoyaltyPoints', loyaltyPointsSchema);
const PointTransaction = mongoose.model('PointTransaction', pointTransactionSchema);

module.exports = { LoyaltyPoints, PointTransaction };
