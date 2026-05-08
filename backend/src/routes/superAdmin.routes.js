/**
 * Super Admin Routes
 * All routes require super_admin role
 */
const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const {
  getPlatformStats,
  getAllRestaurants,
  getRestaurantById,
  updateRestaurant,
  deleteRestaurant,
  getAllUsers,
  updateUser,
  deleteUser,
  getAllOrders,
  createSuperAdmin,
  createManagedUser,
} = require('../controllers/superAdmin.controller');

// Public: create first super admin (requires secret)
router.post('/create', createSuperAdmin);

// All routes below require super_admin role
router.use(protect, authorize('super_admin'));

// Platform dashboard
router.get('/dashboard', getPlatformStats);

// Restaurant management
router.get('/restaurants', getAllRestaurants);
router.get('/restaurants/:id', getRestaurantById);
router.put('/restaurants/:id', updateRestaurant);
router.delete('/restaurants/:id', deleteRestaurant);

// User management
router.get('/users', getAllUsers);
router.post('/users', createManagedUser);
router.put('/users/:id', updateUser);
router.delete('/users/:id', deleteUser);

// Platform-wide orders
router.get('/orders', getAllOrders);

module.exports = router;
