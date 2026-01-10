/**
 * Order Routes - With Payment, Delivery & Tracking
 */
const express = require('express');
const { 
  getAllOrders, 
  getOrderById, 
  createOrder, 
  updateOrderStatus, 
  updatePaymentStatus,
  updateDeliveryStatus,
  cancelOrder,
  deleteOrder,
  getPendingDeliveryOrders,
  getAvailableDeliveryOrders,
  acceptDeliveryOrder
} = require('../controllers/order.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

// Delivery routes (must be before /:id routes)
router.get('/delivery/available', getAvailableDeliveryOrders);
router.put('/delivery/accept/:id', acceptDeliveryOrder);

// Restaurant routes - manage orders for their hotel
router.get('/restaurant/pending-delivery', authorize('restaurant'), getPendingDeliveryOrders);

// User routes
router.get('/', getAllOrders);
router.get('/:id', getOrderById);
router.post('/', createOrder);
router.put('/:id/cancel', cancelOrder);
router.delete('/:id', deleteOrder);

// Restaurant status updates
router.put('/:id/status', authorize('restaurant'), updateOrderStatus);
router.put('/:id/payment', authorize('restaurant'), updatePaymentStatus);
router.put('/:id/delivery', updateDeliveryStatus);

module.exports = router;
