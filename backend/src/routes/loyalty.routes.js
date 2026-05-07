/**
 * Loyalty Routes
 * Handles points, transactions, and redemption endpoints
 */
const express = require('express');
const router = express.Router();
const loyaltyController = require('../controllers/loyalty.controller');
const { protect } = require('../middlewares/auth.middleware');

// All loyalty routes require authentication
router.use(protect);

// Get user's loyalty points and tier status
router.get('/points', loyaltyController.getLoyaltyPoints);

// Get point transaction history
router.get('/transactions', loyaltyController.getTransactions);

// Get available redemption options
router.get('/options', loyaltyController.getRedemptionOptions);

// Redeem points for a reward
router.post('/redeem', loyaltyController.redeemPoints);

// Apply points discount to an order
router.post('/apply-discount', loyaltyController.applyPointsDiscount);

module.exports = router;
