/**
 * Promotion Controller - Hotel-linked promotions
 */
const Promotion = require('../models/Promotion');

// Get all active promotions (for users)
const getAllPromotions = async (req, res, next) => {
  try {
    const now = new Date();
    const promotions = await Promotion.find({
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now }
    }).sort({ createdAt: -1 });
    res.json({ success: true, data: promotions });
  } catch (error) {
    next(error);
  }
};

// Get promotions for a specific hotel (for restaurant portal)
const getHotelPromotions = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const promotions = await Promotion.find({ hotelId }).sort({ createdAt: -1 });
    res.json({ success: true, data: promotions });
  } catch (error) {
    next(error);
  }
};

const validatePromoCode = async (req, res, next) => {
  try {
    const { code, orderAmount, hotelId } = req.body;
    const now = new Date();
    
    // Find promo - optionally filter by hotel
    const query = {
      code: code.toUpperCase(),
      isActive: true,
      startDate: { $lte: now },
      endDate: { $gte: now }
    };
    if (hotelId) query.hotelId = hotelId;
    
    const promo = await Promotion.findOne(query);

    if (!promo) return res.status(400).json({ success: false, message: 'Invalid promo code' });
    if (promo.usedCount >= promo.usageLimit) return res.status(400).json({ success: false, message: 'Promo code expired' });
    if (orderAmount < promo.minOrderAmount) return res.status(400).json({ success: false, message: `Minimum order amount is ${promo.minOrderAmount}` });

    let discount = promo.discountType === 'percentage' 
      ? (orderAmount * promo.discountValue / 100)
      : promo.discountValue;
    
    if (promo.maxDiscount && discount > promo.maxDiscount) discount = promo.maxDiscount;

    res.json({ success: true, data: { discount, description: promo.description, promoType: promo.promoType } });
  } catch (error) {
    next(error);
  }
};

// Create promotion - links to hotel from authenticated user
const createPromotion = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const hotelName = req.user.hotelName || req.user.name || 'Restaurant';
    
    const promotionData = {
      ...req.body,
      hotelId,
      hotelName
    };
    
    const promotion = await Promotion.create(promotionData);
    res.status(201).json({ success: true, data: promotion });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, message: 'Promo code already exists for this hotel' });
    }
    next(error);
  }
};

// Update promotion - only if owned by hotel
const updatePromotion = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const promotion = await Promotion.findOneAndUpdate(
      { _id: req.params.id, hotelId },
      req.body,
      { new: true }
    );
    if (!promotion) return res.status(404).json({ success: false, message: 'Promotion not found or not authorized' });
    res.json({ success: true, data: promotion });
  } catch (error) {
    next(error);
  }
};

// Delete promotion - only if owned by hotel
const deletePromotion = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const result = await Promotion.findOneAndDelete({ _id: req.params.id, hotelId });
    if (!result) return res.status(404).json({ success: false, message: 'Promotion not found or not authorized' });
    res.json({ success: true, message: 'Promotion deleted' });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAllPromotions, getHotelPromotions, validatePromoCode, createPromotion, updatePromotion, deletePromotion };
