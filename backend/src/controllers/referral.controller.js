/**
 * Referral Controller
 * Handles referral code generation, tracking, and rewards
 */
const User = require('../models/User');
const Referral = require('../models/Referral');
const { LoyaltyPoints } = require('../models/LoyaltyPoints');

// Generate a unique referral code
const generateReferralCode = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

/**
 * Get user's referral stats
 * GET /referral/stats
 */
const getReferralStats = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    // Get user with referral info
    const user = await User.findById(userId).select('referralCode referralRewards');
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Get all referrals by this user
    const referrals = await Referral.find({ referrer: userId })
      .populate('referredUser', 'name createdAt')
      .sort({ createdAt: -1 });
    
    // Calculate stats
    const totalReferrals = referrals.length;
    const successfulReferrals = referrals.filter(r => r.status === 'completed').length;
    const pendingReferrals = referrals.filter(r => r.status === 'registered').length;
    
    // Calculate pending rewards
    const pendingRewards = referrals
      .filter(r => r.status === 'completed' && !r.rewardPaid)
      .reduce((sum, r) => sum + r.rewardAmount, 0);
    
    res.json({
      success: true,
      data: {
        referralCode: user.referralCode,
        totalReferrals,
        successfulReferrals,
        pendingReferrals,
        totalRewards: user.referralRewards?.totalEarned || 0,
        pendingRewards,
        recentReferrals: referrals.slice(0, 10).map(r => ({
          id: r._id,
          referredUserName: r.referredUser?.name || 'Anonymous',
          status: r.status,
          rewardAmount: r.rewardAmount,
          rewardPaid: r.rewardPaid,
          createdAt: r.createdAt,
          completedAt: r.completedAt
        }))
      }
    });
  } catch (error) {
    console.error('[REFERRAL] Get stats error:', error);
    next(error);
  }
};

/**
 * Apply referral code during registration
 * POST /referral/apply
 */
const applyReferralCode = async (req, res, next) => {
  try {
    const { code, userId } = req.body;
    
    if (!code || !userId) {
      return res.status(400).json({
        success: false,
        message: 'Referral code and userId are required'
      });
    }
    
    // Find referrer by code
    const referrer = await User.findOne({ referralCode: code.toUpperCase() });
    if (!referrer) {
      return res.status(400).json({
        success: false,
        message: 'Invalid referral code'
      });
    }
    
    // Check if user is trying to refer themselves
    if (referrer._id.toString() === userId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot use your own referral code'
      });
    }
    
    // Update new user with referrer info
    const newUser = await User.findByIdAndUpdate(
      userId,
      { referredBy: referrer._id },
      { new: true }
    );
    
    // Create referral record
    const referral = await Referral.create({
      referrer: referrer._id,
      referredUser: userId,
      referralCode: code.toUpperCase(),
      status: 'registered',
      rewardAmount: 50 // 50 ETB reward
    });
    
    // Update referrer's referral count
    await User.findByIdAndUpdate(referrer._id, {
      $inc: { 'referralRewards.totalReferrals': 1 }
    });
    
    // Add welcome bonus points to new user
    try {
      let loyalty = await LoyaltyPoints.findOne({ user: userId });
      if (!loyalty) {
        loyalty = await LoyaltyPoints.create({
          user: userId,
          availablePoints: 100,
          lifetimePoints: 100,
          tier: 'Bronze'
        });
      } else {
        loyalty.availablePoints += 100;
        loyalty.lifetimePoints += 100;
        await loyalty.save();
      }
    } catch (e) {
      console.log('[REFERRAL] Could not add welcome points:', e.message);
    }
    
    res.json({
      success: true,
      message: 'Referral code applied successfully! You got 100 bonus points!',
      data: {
        referrerName: referrer.name,
        welcomeBonus: 100
      }
    });
  } catch (error) {
    console.error('[REFERRAL] Apply code error:', error);
    next(error);
  }
};

/**
 * Mark referral as completed (called when referred user places first order)
 * POST /referral/complete
 */
const completeReferral = async (req, res, next) => {
  try {
    const { referredUserId } = req.body;
    
    // Find referral record
    const referral = await Referral.findOne({
      referredUser: referredUserId,
      status: { $ne: 'completed' }
    });
    
    if (!referral) {
      return res.status(400).json({
        success: false,
        message: 'No pending referral found'
      });
    }
    
    // Update referral status
    referral.status = 'completed';
    referral.completedAt = new Date();
    await referral.save();
    
    // Update referrer's rewards
    await User.findByIdAndUpdate(referral.referrer, {
      $inc: {
        'referralRewards.totalEarned': referral.rewardAmount,
        'referralRewards.pendingAmount': referral.rewardAmount,
        'referralRewards.successfulReferrals': 1
      }
    });
    
    // Add reward to referrer's wallet
    await User.findByIdAndUpdate(referral.referrer, {
      $inc: { walletBalance: referral.rewardAmount },
      $push: {
        walletTransactions: {
          type: 'credit',
          amount: referral.rewardAmount,
          description: `Referral reward for ${referral.referralCode}`,
          date: new Date().toISOString()
        }
      }
    });
    
    res.json({
      success: true,
      message: 'Referral completed successfully',
      data: {
        rewardAmount: referral.rewardAmount
      }
    });
  } catch (error) {
    console.error('[REFERRAL] Complete error:', error);
    next(error);
  }
};

/**
 * Get user's referrals list
 * GET /referral/my-referrals
 */
const getMyReferrals = async (req, res, next) => {
  try {
    const userId = req.user.id;
    
    const referrals = await Referral.find({ referrer: userId })
      .populate('referredUser', 'name email createdAt')
      .sort({ createdAt: -1 });
    
    res.json({
      success: true,
      data: referrals.map(r => ({
        id: r._id,
        referredUser: r.referredUser ? {
          name: r.referredUser.name,
          email: r.referredUser.email,
          joinedAt: r.referredUser.createdAt
        } : null,
        status: r.status,
        rewardAmount: r.rewardAmount,
        rewardPaid: r.rewardPaid,
        createdAt: r.createdAt,
        completedAt: r.completedAt
      }))
    });
  } catch (error) {
    console.error('[REFERRAL] Get referrals error:', error);
    next(error);
  }
};

/**
 * Validate referral code (for registration)
 * GET /referral/validate/:code
 */
const validateReferralCode = async (req, res, next) => {
  try {
    const { code } = req.params;
    
    const user = await User.findOne({ referralCode: code.toUpperCase() });
    
    if (!user) {
      return res.status(400).json({
        success: false,
        message: 'Invalid referral code'
      });
    }
    
    res.json({
      success: true,
      data: {
        valid: true,
        referrerName: user.name
      }
    });
  } catch (error) {
    console.error('[REFERRAL] Validate error:', error);
    next(error);
  }
};

module.exports = {
  getReferralStats,
  applyReferralCode,
  completeReferral,
  getMyReferrals,
  validateReferralCode
};
