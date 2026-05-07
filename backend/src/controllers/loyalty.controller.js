/**
 * Loyalty Controller
 * Handles points earning, redemption, and tier management
 */
const { LoyaltyPoints, PointTransaction } = require('../models/LoyaltyPoints');
const User = require('../models/User');

// Redemption options (mirrors frontend options)
const REDEMPTION_OPTIONS = [
  {
    id: 'discount_50',
    name: '50 ETB Off',
    description: 'Get 50 ETB discount on your next order',
    pointsCost: 500,
    value: 50,
    type: 'discount'
  },
  {
    id: 'discount_100',
    name: '100 ETB Off',
    description: 'Get 100 ETB discount on your next order',
    pointsCost: 900,
    value: 100,
    type: 'discount'
  },
  {
    id: 'free_delivery',
    name: 'Free Delivery',
    description: 'Free delivery on your next 3 orders',
    pointsCost: 300,
    value: 0,
    type: 'free_delivery'
  },
  {
    id: 'bonus_200',
    name: '200 Bonus Points',
    description: 'Get 200 bonus loyalty points',
    pointsCost: 0,
    value: 200,
    type: 'bonus'
  }
];

/**
 * Get user's loyalty points and tier status
 * GET /loyalty/points
 */
const getLoyaltyPoints = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    // Find or create loyalty record
    let loyalty = await LoyaltyPoints.findOne({ user: userId });
    
    if (!loyalty) {
      loyalty = await LoyaltyPoints.create({
        user: userId,
        availablePoints: 0,
        lifetimePoints: 0,
        tier: 'Bronze'
      });
    }
    
    // Get recent transactions count
    const recentTransactions = await PointTransaction.countDocuments({
      user: userId,
      createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
    });
    
    // Calculate next tier progress
    let nextTierPoints = 0;
    let currentTierMin = 0;
    
    switch (loyalty.tier) {
      case 'Bronze':
        nextTierPoints = 1000;
        currentTierMin = 0;
        break;
      case 'Silver':
        nextTierPoints = 5000;
        currentTierMin = 1000;
        break;
      case 'Gold':
        nextTierPoints = 10000;
        currentTierMin = 5000;
        break;
      case 'Platinum':
        nextTierPoints = loyalty.lifetimePoints;
        currentTierMin = 10000;
        break;
    }
    
    const progress = loyalty.tier === 'Platinum' 
      ? 100 
      : Math.min(100, Math.round(((loyalty.lifetimePoints - currentTierMin) / (nextTierPoints - currentTierMin)) * 100));
    
    res.json({
      success: true,
      data: {
        availablePoints: loyalty.availablePoints,
        lifetimePoints: loyalty.lifetimePoints,
        tier: loyalty.tier,
        tierUpdatedAt: loyalty.tierUpdatedAt,
        nextTier: loyalty.tier === 'Platinum' ? null : 
          loyalty.tier === 'Bronze' ? 'Silver' :
          loyalty.tier === 'Silver' ? 'Gold' : 'Platinum',
        nextTierPoints,
        progress,
        recentTransactions
      }
    });
  } catch (error) {
    console.error('[LOYALTY] Get points error:', error);
    next(error);
  }
};

/**
 * Get point transaction history
 * GET /loyalty/transactions
 */
const getTransactions = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    
    const transactions = await PointTransaction.find({ user: userId })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .populate('orderId', 'orderNumber totalPrice');
    
    const total = await PointTransaction.countDocuments({ user: userId });
    
    res.json({
      success: true,
      data: transactions.map(t => ({
        id: t._id,
        type: t.type,
        points: t.points,
        description: t.description,
        orderId: t.orderId?._id,
        orderNumber: t.orderId?.orderNumber,
        redemptionId: t.redemptionId,
        createdAt: t.createdAt,
        expiresAt: t.expiresAt
      })),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('[LOYALTY] Get transactions error:', error);
    next(error);
  }
};

/**
 * Redeem points for a reward
 * POST /loyalty/redeem
 */
const redeemPoints = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { redemptionId, points } = req.body;
    
    // Validate redemption option
    const option = REDEMPTION_OPTIONS.find(opt => opt.id === redemptionId);
    if (!option) {
      return res.status(400).json({
        success: false,
        message: 'Invalid redemption option'
      });
    }
    
    // Check points match
    if (points !== option.pointsCost) {
      return res.status(400).json({
        success: false,
        message: 'Points cost mismatch'
      });
    }
    
    // Get user's loyalty record
    let loyalty = await LoyaltyPoints.findOne({ user: userId });
    if (!loyalty) {
      return res.status(400).json({
        success: false,
        message: 'No loyalty points found'
      });
    }
    
    // Check sufficient points
    if (loyalty.availablePoints < option.pointsCost) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient points'
      });
    }
    
    // Process redemption based on type
    let reward = {};
    
    if (option.type === 'bonus') {
      // Bonus points - add instead of deduct
      const bonusTransaction = new PointTransaction({
        user: userId,
        type: 'bonus',
        points: option.value,
        description: `Bonus: ${option.name}`,
        redemptionId: option.id
      });
      await bonusTransaction.save();
      
      loyalty.availablePoints += option.value;
      loyalty.lifetimePoints += option.value;
      loyalty.updateTier();
      await loyalty.save();
      
      reward = {
        type: 'bonus_points',
        points: option.value,
        message: `You've earned ${option.value} bonus points!`
      };
    } else {
      // Regular redemption - deduct points
      const transactionData = loyalty.redeemPoints(
        option.pointsCost,
        `Redeemed: ${option.name}`,
        option.id
      );
      
      const transaction = new PointTransaction(transactionData);
      await transaction.save();
      await loyalty.save();
      
      reward = {
        type: option.type,
        name: option.name,
        value: option.value,
        message: `Successfully redeemed ${option.name}!`
      };
      
      // Add promo code to user's account for discounts
      if (option.type === 'discount') {
        const promoCode = `REDEEM${option.value}_${Date.now().toString(36).toUpperCase()}`;
        reward.promoCode = promoCode;
        reward.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
      }
    }
    
    res.json({
      success: true,
      message: reward.message,
      data: {
        availablePoints: loyalty.availablePoints,
        tier: loyalty.tier,
        reward
      }
    });
  } catch (error) {
    console.error('[LOYALTY] Redeem error:', error);
    next(error);
  }
};

/**
 * Apply points discount to an order
 * POST /loyalty/apply-discount
 */
const applyPointsDiscount = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { orderId, points } = req.body;
    
    // Validate minimum points (100 points = 10 ETB minimum)
    if (points < 100) {
      return res.status(400).json({
        success: false,
        message: 'Minimum 100 points required for discount'
      });
    }
    
    // Get loyalty record
    let loyalty = await LoyaltyPoints.findOne({ user: userId });
    if (!loyalty || loyalty.availablePoints < points) {
      return res.status(400).json({
        success: false,
        message: 'Insufficient points'
      });
    }
    
    // Calculate discount (100 points = 10 ETB)
    const discountAmount = Math.floor(points / 10);
    
    // Deduct points
    const transactionData = loyalty.redeemPoints(
      points,
      `Applied ${points} points for ${discountAmount} ETB discount on order`,
      `discount_${orderId}`
    );
    
    const transaction = new PointTransaction({
      ...transactionData,
      orderId
    });
    await transaction.save();
    await loyalty.save();
    
    res.json({
      success: true,
      message: `Discount of ${discountAmount} ETB applied`,
      data: {
        discountAmount,
        pointsUsed: points,
        availablePoints: loyalty.availablePoints
      }
    });
  } catch (error) {
    console.error('[LOYALTY] Apply discount error:', error);
    next(error);
  }
};

/**
 * Get available redemption options
 * GET /loyalty/options
 */
const getRedemptionOptions = async (req, res, next) => {
  try {
    // Get user's available points to determine affordability
    const userId = req.user.id;
    const loyalty = await LoyaltyPoints.findOne({ user: userId });
    const availablePoints = loyalty?.availablePoints || 0;
    
    const options = REDEMPTION_OPTIONS.map(opt => ({
      ...opt,
      canAfford: availablePoints >= opt.pointsCost
    }));
    
    res.json({
      success: true,
      data: options
    });
  } catch (error) {
    console.error('[LOYALTY] Get options error:', error);
    next(error);
  }
};

/**
 * Earn points from completed order (internal use)
 * Called when order is marked as delivered
 */
const earnPointsFromOrder = async (userId, orderId, orderAmount) => {
  try {
    let loyalty = await LoyaltyPoints.findOne({ user: userId });
    
    if (!loyalty) {
      loyalty = new LoyaltyPoints({
        user: userId,
        availablePoints: 0,
        lifetimePoints: 0,
        tier: 'Bronze'
      });
    }
    
    // Calculate points with tier multiplier
    const pointsToEarn = LoyaltyPoints.calculatePoints(orderAmount, loyalty.tier);
    
    if (pointsToEarn > 0) {
      const transactionData = loyalty.addPoints(
        pointsToEarn,
        `Earned from order #${orderId.toString().slice(-6)}`,
        orderId
      );
      
      const transaction = new PointTransaction(transactionData);
      await transaction.save();
      
      const tierChanged = loyalty.updateTier();
      await loyalty.save();
      
      return {
        pointsEarned: pointsToEarn,
        newTier: tierChanged ? loyalty.tier : null,
        totalPoints: loyalty.availablePoints
      };
    }
    
    return { pointsEarned: 0 };
  } catch (error) {
    console.error('[LOYALTY] Earn points error:', error);
    throw error;
  }
};

module.exports = {
  getLoyaltyPoints,
  getTransactions,
  redeemPoints,
  applyPointsDiscount,
  getRedemptionOptions,
  earnPointsFromOrder
};
