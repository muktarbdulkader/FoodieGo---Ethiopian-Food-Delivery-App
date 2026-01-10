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
  getCategories,
  toggleLikeFood,
  incrementViewCount,
  getPopularFoods,
  getAdminCategories
} = require('../controllers/food.controller');
const { protect, authorize, optionalAuth } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public routes
router.get('/hotels', getAllHotels);
router.get('/hotels/:hotelId/foods', getFoodsByHotel);
router.get('/categories', getCategories);
router.get('/popular', getPopularFoods);
router.get('/:id', getFoodById);
router.post('/:id/view', incrementViewCount);

// Protected routes - optionalAuth to differentiate admin vs user view
router.get('/', optionalAuth, getAllFoods);

// User routes (need to be logged in)
router.post('/:id/like', protect, toggleLikeFood);

// Admin only routes
router.get('/admin/categories', protect, authorize('admin'), getAdminCategories);
router.post('/', protect, authorize('admin'), createFood);
router.put('/:id', protect, authorize('admin'), updateFood);
router.delete('/:id', protect, authorize('admin'), deleteFood);

module.exports = router;
