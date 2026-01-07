/**
 * Order Model - With Payment, Delivery & Location
 */
const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  food: { type: mongoose.Schema.Types.ObjectId, ref: 'Food' },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true, min: 1 },
  hotelId: { type: String },
  hotelName: { type: String },
  image: { type: String }
});

const deliveryAddressSchema = new mongoose.Schema({
  label: { type: String, default: 'Home' }, // Home, Work, Other
  fullAddress: { type: String, required: true },
  street: { type: String },
  city: { type: String },
  state: { type: String },
  zipCode: { type: String },
  country: { type: String, default: 'USA' },
  latitude: { type: Number },
  longitude: { type: Number },
  instructions: { type: String } // Delivery instructions
}, { _id: false });

const paymentSchema = new mongoose.Schema({
  method: { 
    type: String, 
    enum: ['cash', 'card', 'wallet', 'paypal'],
    default: 'cash'
  },
  status: {
    type: String,
    enum: ['pending', 'paid', 'failed', 'refunded'],
    default: 'pending'
  },
  transactionId: { type: String },
  cardLast4: { type: String }, // Last 4 digits of card
  paidAt: { type: Date }
}, { _id: false });

const deliverySchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['delivery', 'pickup'],
    default: 'delivery'
  },
  fee: { type: Number, default: 2.99 },
  estimatedTime: { type: Number, default: 30 }, // minutes
  distance: { type: Number }, // km
  driverName: { type: String },
  driverPhone: { type: String },
  trackingStatus: {
    type: String,
    enum: ['pending', 'assigned', 'picked_up', 'on_the_way', 'arrived', 'delivered'],
    default: 'pending'
  },
  deliveredAt: { type: Date }
}, { _id: false });

const orderSchema = new mongoose.Schema({
  orderNumber: { type: String },
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  restaurant: { type: mongoose.Schema.Types.ObjectId, ref: 'Restaurant' },
  items: [orderItemSchema],
  
  // Pricing
  subtotal: { type: Number, required: true },
  deliveryFee: { type: Number, default: 2.99 },
  tax: { type: Number, default: 0 },
  discount: { type: Number, default: 0 },
  tip: { type: Number, default: 0 },
  totalPrice: { type: Number, required: true },
  
  // Status
  status: {
    type: String,
    enum: ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled'],
    default: 'pending'
  },
  
  // Payment & Delivery
  payment: paymentSchema,
  delivery: deliverySchema,
  deliveryAddress: deliveryAddressSchema,
  
  // Additional
  notes: { type: String, default: '' },
  promoCode: { type: String },
  cancelReason: { type: String }
}, { timestamps: true });

// Generate order number before saving
orderSchema.pre('save', async function(next) {
  if (!this.orderNumber) {
    const count = await mongoose.model('Order').countDocuments();
    this.orderNumber = `ORD${String(count + 1).padStart(6, '0')}`;
  }
  next();
});

module.exports = mongoose.model('Order', orderSchema);
