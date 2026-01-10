const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const {
  createBooking,
  getUserBookings,
  getHotelBookings,
  respondToBooking,
  getEventRecommendations,
  getNearbyEventVenues
} = require('../controllers/eventBooking.controller');

// Public routes
router.get('/recommendations', getEventRecommendations);
router.get('/venues', getNearbyEventVenues);

// User routes
router.post('/', protect, createBooking);
router.get('/my-bookings', protect, getUserBookings);

// Admin routes
router.get('/hotel-bookings', protect, authorize('admin'), getHotelBookings);
router.put('/:bookingId/respond', protect, authorize('admin'), respondToBooking);

module.exports = router;
