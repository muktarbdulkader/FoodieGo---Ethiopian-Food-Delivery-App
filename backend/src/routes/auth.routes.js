/**
 * Auth Routes
 * Handles authentication endpoints
 */
const express = require('express');
const { register, login, updateLocation, getProfile, updateHotelSettings, getUserStats } = require('../controllers/auth.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);

// Protected routes
router.get('/profile', protect, getProfile);
router.get('/me/stats', protect, getUserStats);
router.put('/location', protect, updateLocation);
router.put('/hotel-settings', protect, authorize('admin'), updateHotelSettings);

module.exports = router;
