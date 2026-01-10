/**
 * Promotion Model - Discounts and offers linked to hotels
 */
const mongoose = require('mongoose');

const promotionSchema = new mongoose.Schema({
  code: { type: String, required: true, uppercase: true },
  description: { type: String, required: true },
  discountType: { type: String, enum: ['percentage', 'fixed'], default: 'percentage' },
  discountValue: { type: Number, required: true },
  minOrderAmount: { type: Number, default: 0 },
  maxDiscount: { type: Number },
  usageLimit: { type: Number, default: 100 },
  usedCount: { type: Number, default: 0 },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  isActive: { type: Boolean, default: true },
  // Link to hotel
  hotelId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  hotelName: { type: String },
  // Promotion type/purpose
  promoType: { 
    type: String, 
    enum: ['food_discount', 'delivery_free', 'event_discount', 'new_user', 'special_offer'],
    default: 'food_discount'
  },
  // Optional: specific foods this applies to
  applicableFoods: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Food' }]
}, { timestamps: true });

// Compound unique index - code unique per hotel
promotionSchema.index({ code: 1, hotelId: 1 }, { unique: true });

module.exports = mongoose.model('Promotion', promotionSchema);
