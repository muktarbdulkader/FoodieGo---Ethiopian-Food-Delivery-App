/**
 * Order Routes - With Payment, Delivery & Tracking
 * Enhanced with Yango-like features + Dine-in support
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
  acceptDeliveryOrder,
  updateDriverLocation,
  getDriverLocation,
  sendChatMessage,
  getChatMessages,
  rateDriver,
  getDriverEarnings,
  getDriverStats,
  getDineInOrders,
  callWaiter,
  getPendingWaiterCalls,
  acknowledgeWaiterCall,
  getOrderStatusByTable, // NEW
  markNotificationRead, // NEW
  sendNotification, // NEW
  assignDriverToOrder,
} = require('../controllers/order.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

// Public route for dine-in orders (no authentication required)
router.post('/', createOrder); // Move this BEFORE protect middleware

// Public route to check order status by table (no auth required for customers)
router.get('/table/:tableId/status', getOrderStatusByTable);
router.put('/:orderId/notification/read', markNotificationRead);
router.post('/:orderId/notify', sendNotification); // NEW: Send notification to customer

// Public route for calling waiter (no auth required for guests)
router.post('/dine-in/call-waiter', callWaiter);

router.use(protect);

// Dine-in routes (NEW)
router.get('/dine-in', getDineInOrders);
// router.post('/dine-in/call-waiter', callWaiter); // Moved to public section above
router.get('/dine-in/waiter-calls', authorize('restaurant'), getPendingWaiterCalls);
router.put('/dine-in/waiter-calls/:callId/acknowledge', authorize('restaurant'), acknowledgeWaiterCall);

// Delivery routes (must be before /:id routes)
router.get('/delivery/available', getAvailableDeliveryOrders);
router.put('/delivery/accept/:id', acceptDeliveryOrder);
router.put('/delivery/location', authorize('delivery'), updateDriverLocation);
router.get('/delivery/earnings', authorize('delivery'), getDriverEarnings);
router.get('/delivery/stats', authorize('delivery'), getDriverStats);

// Real-time tracking routes
router.get('/:orderId/driver-location', getDriverLocation);

// Chat routes
router.post('/:orderId/chat', sendChatMessage);
router.get('/:orderId/chat', getChatMessages);

// Rating route
router.post('/:orderId/rate-driver', rateDriver);

// Restaurant routes - manage orders for their hotel
router.get('/restaurant/pending-delivery', authorize('restaurant'), getPendingDeliveryOrders);
router.put('/:id/assign-driver', authorize('restaurant'), assignDriverToOrder);

// User routes
router.get('/', getAllOrders);
router.get('/:id', getOrderById);
// router.post('/', createOrder); // Moved to public section above
router.put('/:id/cancel', cancelOrder);
router.delete('/:id', deleteOrder);

// Restaurant status updates
router.put('/:id/status', authorize('restaurant'), updateOrderStatus);
router.put('/:id/payment', authorize('restaurant'), updatePaymentStatus);
router.put('/:id/delivery', updateDeliveryStatus);

module.exports = router;
