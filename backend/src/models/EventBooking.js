const mongoose = require('mongoose');

const eventBookingSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  hotel: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User', // Hotel/Restaurant (admin user)
    required: true
  },
  eventType: {
    type: String,
    enum: ['wedding', 'birthday', 'ceremony', 'corporate', 'graduation', 'anniversary', 'other'],
    required: true
  },
  eventName: {
    type: String,
    required: true,
    trim: true
  },
  eventDate: {
    type: Date,
    required: true
  },
  eventTime: {
    type: String,
    required: true
  },
  guestCount: {
    type: Number,
    required: true,
    min: 1
  },
  venue: {
    type: String,
    enum: ['restaurant', 'outdoor', 'home_delivery', 'custom_location'],
    default: 'restaurant'
  },
  customLocation: {
    address: String,
    city: String,
    latitude: Number,
    longitude: Number
  },
  services: [{
    type: String,
    enum: ['catering', 'decoration', 'cake', 'photography', 'music', 'venue_rental', 'waiters', 'drinks']
  }],
  foodPreferences: {
    type: String,
    enum: ['ethiopian', 'international', 'mixed', 'vegetarian', 'custom'],
    default: 'mixed'
  },
  specialRequests: {
    type: String,
    trim: true
  },
  budget: {
    min: Number,
    max: Number,
    currency: { type: String, default: 'ETB' }
  },
  contactPhone: {
    type: String,
    required: true
  },
  contactEmail: String,
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'in_progress', 'completed', 'cancelled'],
    default: 'pending'
  },
  adminResponse: {
    message: String,
    quotation: Number,
    respondedAt: Date
  },
  recommendedFoods: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Food'
  }],
  totalPrice: {
    type: Number,
    default: 0
  },
  deposit: {
    amount: Number,
    paid: { type: Boolean, default: false },
    paidAt: Date
  }
}, {
  timestamps: true
});

// Index for efficient queries
eventBookingSchema.index({ user: 1, status: 1 });
eventBookingSchema.index({ hotel: 1, status: 1 });
eventBookingSchema.index({ eventDate: 1 });

module.exports = mongoose.model('EventBooking', eventBookingSchema);
