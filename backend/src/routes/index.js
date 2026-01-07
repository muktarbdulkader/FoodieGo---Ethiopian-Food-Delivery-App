/**
 * Main Router - All API routes
 */
const express = require('express');
const authRoutes = require('./auth.routes');
const foodRoutes = require('./food.routes');
const orderRoutes = require('./order.routes');
const adminRoutes = require('./admin.routes');
const restaurantRoutes = require('./restaurant.routes');
const promotionRoutes = require('./promotion.routes');
const reviewRoutes = require('./review.routes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/foods', foodRoutes);
router.use('/orders', orderRoutes);
router.use('/admin', adminRoutes);
router.use('/restaurants', restaurantRoutes);
router.use('/promotions', promotionRoutes);
router.use('/reviews', reviewRoutes);

module.exports = router;
