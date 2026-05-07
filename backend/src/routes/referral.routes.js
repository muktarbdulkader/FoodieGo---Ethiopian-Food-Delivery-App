/**
 * Referral Routes
 * Handles referral code and rewards endpoints
 */
const express = require('express');
const router = express.Router();
const referralController = require('../controllers/referral.controller');
const { protect } = require('../middlewares/auth.middleware');

// Public routes
router.get('/validate/:code', referralController.validateReferralCode);

// Protected routes (require authentication)
router.use(protect);

// Get user's referral stats
router.get('/stats', referralController.getReferralStats);

// Get user's referrals list
router.get('/my-referrals', referralController.getMyReferrals);

// Apply referral code (for new users)
router.post('/apply', referralController.applyReferralCode);

// Mark referral as completed (internal use)
router.post('/complete', referralController.completeReferral);

module.exports = router;
