/**
 * Payment Routes
 * Handles payment-related endpoints
 */
const express = require('express');
const router = express.Router();
const paymentController = require('../controllers/payment.controller');
const { protect } = require('../middlewares/auth.middleware');

// Create Telebirr order (for in-app payment flow)
// Can be public or protected depending on your needs
router.post('/create/order', paymentController.createTelebirrOrder);

// Initiate Telebirr payment (protected - requires authentication)
router.post('/telebirr/initiate', protect, paymentController.initiateTelebirrPayment);

// Telebirr webhook (public - called by Telebirr servers)
router.post('/telebirr/webhook', paymentController.telebirrWebhook);

// Verify payment status (protected)
router.get('/verify/:orderId', protect, paymentController.verifyPayment);

// Payment success redirect (public - from Telebirr)
router.get('/success', paymentController.paymentSuccess);

// Payment failed redirect (public - from Telebirr)
router.get('/failed', paymentController.paymentFailed);

module.exports = router;
