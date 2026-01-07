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
  deleteOrder 
} = require('../controllers/order.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.use(protect);

router.get('/', getAllOrders);
router.get('/:id', getOrderById);
router.post('/', createOrder);
router.put('/:id/status', authorize('admin'), updateOrderStatus);
router.put('/:id/payment', authorize('admin'), updatePaymentStatus);
router.put('/:id/delivery', authorize('admin'), updateDeliveryStatus);
router.put('/:id/cancel', cancelOrder);
router.delete('/:id', authorize('admin'), deleteOrder);

module.exports = router;
