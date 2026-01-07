/**
 * Admin Routes - Full Hotel Management
 */
const express = require('express');
const {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  updateUser,
  updateUserRole,
  deleteUser,
  getAllPayments,
  updatePaymentStatus,
  getDeliveryManagement,
  assignDriver,
  getAnalytics
} = require('../controllers/admin.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect, authorize('admin'));

// Dashboard
router.get('/dashboard', getDashboardStats);
router.get('/analytics', getAnalytics);

// User management
router.get('/users', getAllUsers);
router.get('/users/:id', getUserDetails);
router.put('/users/:id', updateUser);
router.put('/users/:id/role', updateUserRole);
router.delete('/users/:id', deleteUser);

// Payment management
router.get('/payments', getAllPayments);
router.put('/payments/:id', updatePaymentStatus);

// Delivery management
router.get('/deliveries', getDeliveryManagement);
router.put('/deliveries/:id/assign', assignDriver);

module.exports = router;
