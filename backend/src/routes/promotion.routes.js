const express = require('express');
const { getAllPromotions, getHotelPromotions, validatePromoCode, createPromotion, updatePromotion, deletePromotion } = require('../controllers/promotion.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/', getAllPromotions);
router.get('/hotel', protect, authorize('restaurant'), getHotelPromotions);
router.post('/validate', protect, validatePromoCode);
router.post('/', protect, authorize('restaurant'), createPromotion);
router.put('/:id', protect, authorize('restaurant'), updatePromotion);
router.delete('/:id', protect, authorize('restaurant'), deletePromotion);

module.exports = router;
