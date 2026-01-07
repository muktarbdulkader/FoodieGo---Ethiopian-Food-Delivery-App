/**
 * Food Routes - With Hotel Isolation
 */
const express = require('express');
const { 
  getAllFoods, 
  getFoodsByHotel,
  getAllHotels,
  getFoodById, 
  createFood, 
  updateFood, 
  deleteFood,
  getCategories
} = require('../controllers/food.controller');
const { protect, authorize, optionalAuth } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public routes
router.get('/hotels', getAllHotels);
router.get('/hotels/:hotelId/foods', getFoodsByHotel);
router.get('/categories', getCategories);
router.get('/:id', getFoodById);

// Protected routes - optionalAuth to differentiate admin vs user view
router.get('/', optionalAuth, getAllFoods);

// Admin only routes
router.post('/', protect, authorize('admin'), createFood);
router.put('/:id', protect, authorize('admin'), updateFood);
router.delete('/:id', protect, authorize('admin'), deleteFood);

module.exports = router;
