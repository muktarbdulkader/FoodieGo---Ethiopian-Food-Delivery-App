const express = require('express');
const { getAllPromotions, validatePromoCode, createPromotion, updatePromotion, deletePromotion } = require('../controllers/promotion.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/', getAllPromotions);
router.post('/validate', protect, validatePromoCode);
router.post('/', protect, authorize('admin'), createPromotion);
router.put('/:id', protect, authorize('admin'), updatePromotion);
router.delete('/:id', protect, authorize('admin'), deletePromotion);

module.exports = router;
