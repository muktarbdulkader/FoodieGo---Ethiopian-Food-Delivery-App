/**
 * Table Routes - For QR-based dine-in ordering
 */
const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const {
  getAllTables,
  getTableById,
  getTableByQRCode,
  createTable,
  updateTable,
  deleteTable,
  startTableSession,
  endTableSession,
  addOrderToTable,
  bulkCreateTables
} = require('../controllers/table.controller');

// Public route - get table by QR code scan
router.get('/qr', getTableByQRCode);

// Protected routes
router.use(protect);

// Get all tables (restaurant sees their own, others can query by restaurantId)
router.get('/', getAllTables);

// Get single table
router.get('/:id', getTableById);

// Table session management
router.post('/:tableId/session/start', startTableSession);
router.post('/:tableId/session/end', endTableSession);
router.post('/session/add-order', addOrderToTable);

// Restaurant-only routes
router.post('/', authorize('restaurant'), createTable);
router.post('/bulk', authorize('restaurant'), bulkCreateTables);
router.put('/:id', authorize('restaurant'), updateTable);
router.delete('/:id', authorize('restaurant'), deleteTable);

module.exports = router;
