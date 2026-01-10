const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const {
  createBooking,
  getUserBookings,
  getHotelBookings,
  respondToBooking,
  confirmComplete,
  deleteBooking,
  getEventRecommendations,
  getNearbyEventVenues
} = require('../controllers/eventBooking.controller');

// Public routes
router.get('/recommendations', getEventRecommendations);
router.get('/venues', getNearbyEventVenues);

// User routes
router.post('/', protect, createBooking);
router.get('/my-bookings', protect, getUserBookings);
router.put('/:bookingId/confirm-complete', protect, confirmComplete);
router.delete('/:bookingId', protect, deleteBooking);

// Restaurant routes
router.get('/hotel-bookings', protect, authorize('restaurant'), getHotelBookings);
router.put('/:bookingId/respond', protect, authorize('restaurant'), respondToBooking);

module.exports = router;
