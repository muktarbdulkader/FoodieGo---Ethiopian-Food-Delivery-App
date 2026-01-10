/**
 * Auth Routes
 * Handles authentication endpoints
 */
const express = require('express');
const { 
  register, 
  login, 
  updateLocation, 
  getProfile, 
  updateHotelSettings, 
  getUserStats,
  updateProfile,
  changePassword,
  getWallet,
  topUpWallet,
  deleteAccount,
  forgotPassword,
  verifyOTP,
  resetPassword,
  toggleFavoriteHotel,
  getFavoriteHotels,
  checkFavoriteHotel
} = require('../controllers/auth.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOTP);
router.post('/reset-password', resetPassword);

// Protected routes
router.get('/profile', protect, getProfile);
router.get('/me/stats', protect, getUserStats);
router.put('/location', protect, updateLocation);
router.put('/profile', protect, updateProfile);
router.put('/password', protect, changePassword);
router.get('/wallet', protect, getWallet);
router.post('/wallet/topup', protect, topUpWallet);
router.delete('/account', protect, deleteAccount);
router.put('/hotel-settings', protect, authorize('restaurant'), updateHotelSettings);

// Favorite hotels
router.post('/favorites/hotels', protect, toggleFavoriteHotel);
router.get('/favorites/hotels', protect, getFavoriteHotels);
router.get('/favorites/hotels/:hotelId', protect, checkFavoriteHotel);

module.exports = router;
