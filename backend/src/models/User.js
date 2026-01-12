/**
 * User Model - Extended for Hotel Management
 */
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    maxlength: [50, 'Name cannot exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters']
  },
  phone: {
    type: String,
    trim: true
  },
  address: {
    type: String,
    trim: true
  },
  // User location
  location: {
    latitude: Number,
    longitude: Number,
    address: String,
    city: String
  },
  role: {
    type: String,
    enum: ['user', 'restaurant', 'delivery'],
    default: 'user'
  },
  // For restaurant owners - their hotel ID (uses their user _id)
  hotelId: {
    type: String,
    trim: true
  },
  // For admin/restaurant owners - hotelName must be unique for admins
  hotelName: {
    type: String,
    trim: true
  },
  hotelAddress: {
    type: String,
    trim: true
  },
  hotelPhone: {
    type: String,
    trim: true
  },
  hotelDescription: {
    type: String,
    trim: true
  },
  hotelImage: {
    type: String,
    default: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800'
  },
  hotelRating: {
    type: Number,
    default: 4.5,
    min: 0,
    max: 5
  },
  totalRatings: {
    type: Number,
    default: 0
  },
  hotelCategory: {
    type: String,
    enum: ['restaurant', 'cafe', 'fast_food', 'fine_dining', 'bakery', 'other'],
    default: 'restaurant'
  },
  deliveryRadius: {
    type: Number,
    default: 10 // km
  },
  minOrderAmount: {
    type: Number,
    default: 0
  },
  deliveryFee: {
    type: Number,
    default: 50
  },
  // Account status
  isActive: {
    type: Boolean,
    default: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  isOpen: {
    type: Boolean,
    default: true
  },
  // Stats
  totalOrders: {
    type: Number,
    default: 0
  },
  totalSpent: {
    type: Number,
    default: 0
  },
  totalRevenue: {
    type: Number,
    default: 0
  },
  // Wallet
  walletBalance: {
    type: Number,
    default: 0
  },
  walletTransactions: [{
    type: { type: String, enum: ['credit', 'debit'] },
    amount: Number,
    description: String,
    date: String
  }],
  // Delivery driver stats
  deliveryStats: {
    totalDeliveries: { type: Number, default: 0 },
    totalEarnings: { type: Number, default: 0 },
    todayDeliveries: { type: Number, default: 0 },
    todayEarnings: { type: Number, default: 0 },
    weeklyDeliveries: { type: Number, default: 0 },
    weeklyEarnings: { type: Number, default: 0 },
    averageRating: { type: Number, default: 5.0 },
    totalRatings: { type: Number, default: 0 },
    lastDeliveryDate: { type: Date }
  },
  // Driver current location (for real-time tracking)
  currentLocation: {
    latitude: { type: Number },
    longitude: { type: Number },
    updatedAt: { type: Date }
  },
  // Driver availability status
  isAvailable: {
    type: Boolean,
    default: true
  },
  level: {
    type: String,
    default: 'Regular'
  },
  // Favorite hotels (for users)
  favoriteHotels: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  lastLogin: {
    type: Date
  }
}, { timestamps: true });

// Ensure hotelName is unique for restaurant users (sparse index)
userSchema.index(
  { hotelName: 1 }, 
  { 
    unique: true, 
    sparse: true,
    partialFilterExpression: { 
      role: 'restaurant', 
      hotelName: { $exists: true, $ne: null, $ne: '' } 
    }
  }
);

module.exports = mongoose.model('User', userSchema);
