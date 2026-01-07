/**
 * Promotion Controller
 */
const Promotion = require('../models/Promotion');

const getAllPromotions = async (req, res, next) => {
  try {
    const now = new Date();
    const promotions = await Promotion.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now }
    });
    res.json({ success: true, data: promotions });
  } catch (error) {
    next(error);
  }
};

const validatePromoCode = async (req, res, next) => {
  try {
    const { code, orderAmount } = req.body;
    const now = new Date();
    
    const promo = await Promotion.findOne({
      code: code.toUpperCase(),
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now }
    });

    if (!promo) return res.status(400).json({ success: false, message: 'Invalid promo code' });
    if (promo.usedCount >= promo.usageLimit) return res.status(400).json({ success: false, message: 'Promo code expired' });
    if (orderAmount < promo.minOrderAmount) return res.status(400).json({ success: false, message: `Minimum order amount is $${promo.minOrderAmount}` });

    let discount = promo.discountType === 'percentage' 
      ? (orderAmount * promo.discountValue / 100)
      : promo.discountValue;
    
    if (promo.maxDiscount && discount > promo.maxDiscount) discount = promo.maxDiscount;

    res.json({ success: true, data: { discount, description: promo.description } });
  } catch (error) {
    next(error);
  }
};

const createPromotion = async (req, res, next) => {
  try {
    const promotion = await Promotion.create(req.body);
    res.status(201).json({ success: true, data: promotion });
  } catch (error) {
    next(error);
  }
};

const updatePromotion = async (req, res, next) => {
  try {
    const promotion = await Promotion.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!promotion) return res.status(404).json({ success: false, message: 'Promotion not found' });
    res.json({ success: true, data: promotion });
  } catch (error) {
    next(error);
  }
};

const deletePromotion = async (req, res, next) => {
  try {
    await Promotion.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'Promotion deleted' });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAllPromotions, validatePromoCode, createPromotion, updatePromotion, deletePromotion };
