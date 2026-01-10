/**
 * Auth Controller - Extended for Hotel Management with Isolation
 * Implements security best practices
 * Roles: user, restaurant, delivery (NO admin role)
 */
const User = require('../models/User');
const OTP = require('../models/OTP');
const { hashPassword, comparePassword } = require('../utils/hash');
const { generateToken } = require('../utils/jwt');
const { isAccountLocked, recordFailedAttempt, clearFailedAttempts } = require('../middlewares/auth.middleware');
const { generateOTP, sendOTPEmail } = require('../utils/email');

// Secret code for restaurant/delivery registration
const ADMIN_SECRET_CODE = 'FOODIEGO_ADMIN_2024';

/**
 * Register a new user
 */
const register = async (req, res, next) => {
  try {
    const { 
      name, email, password, phone, address, role, adminCode, 
      hotelName, hotelAddress, hotelPhone, hotelDescription, hotelCategory,
      location 
    } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }

    // Determine role - restaurant/delivery requires secret code
    let userRole = 'user';
    if (role === 'restaurant') {
      if (adminCode !== ADMIN_SECRET_CODE) {
        return res.status(403).json({ success: false, message: 'Invalid registration code' });
      }
      
      // Check if hotel name is unique for restaurant owners
      if (hotelName) {
        const existingHotel = await User.findOne({ 
          hotelName: { $regex: new RegExp(`^${hotelName}$`, 'i') },
          role: 'restaurant'
        });
        if (existingHotel) {
          return res.status(400).json({ 
            success: false, 
            message: 'Hotel name already registered. Please choose a different name.' 
          });
        }
      } else {
        return res.status(400).json({ 
          success: false, 
          message: 'Hotel name is required for restaurant registration' 
        });
      }
      
      userRole = 'restaurant';
    } else if (role === 'delivery') {
      if (adminCode !== ADMIN_SECRET_CODE) {
        return res.status(403).json({ success: false, message: 'Invalid registration code' });
      }
      userRole = 'delivery';
    }

    // Hash password and create user
    const hashedPassword = await hashPassword(password);
    const userData = {
      name,
      email,
      password: hashedPassword,
      phone,
      address,
      role: userRole,
      location: userRole === 'user' ? location : undefined,
      isVerified: userRole !== 'user'
    };

    // Add hotel info for restaurant owners
    if (userRole === 'restaurant') {
      userData.hotelName = hotelName;
      userData.hotelAddress = hotelAddress;
      userData.hotelPhone = hotelPhone || phone;
      userData.hotelDescription = hotelDescription;
      userData.hotelCategory = hotelCategory || 'restaurant';
      // Handle hotel image (base64 or URL)
      if (req.body.hotelImage) {
        userData.hotelImage = req.body.hotelImage;
      }
    }

    const user = await User.create(userData);

    // Generate token
    const token = generateToken({ id: user._id, role: user.role });

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          address: user.address,
          role: user.role,
          location: user.location,
          hotelName: user.hotelName,
          hotelAddress: user.hotelAddress,
          hotelPhone: user.hotelPhone,
          hotelDescription: user.hotelDescription,
          hotelCategory: user.hotelCategory,
          hotelImage: user.hotelImage,
          hotelRating: user.hotelRating
        },
        token
      }
    });
  } catch (error) {
    if (error.code === 11000 && error.keyPattern?.hotelName) {
      return res.status(400).json({ 
        success: false, 
        message: 'Hotel name already registered. Please choose a different name.' 
      });
    }
    next(error);
  }
};

/**
 * Login user
 */
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'Please provide email and password' });
    }

    // Check if account is locked
    if (isAccountLocked(email)) {
      return res.status(423).json({ 
        success: false, 
        message: 'Account temporarily locked. Please try again in 15 minutes.' 
      });
    }

    const user = await User.findOne({ email });
    if (!user) {
      recordFailedAttempt(email);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      recordFailedAttempt(email);
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    clearFailedAttempts(email);
    user.lastLogin = new Date();
    await user.save();

    const token = generateToken({ id: user._id, role: user.role });

    res.json({
      success: true,
      data: {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          address: user.address,
          role: user.role,
          location: user.location,
          hotelName: user.hotelName,
          hotelAddress: user.hotelAddress,
          hotelPhone: user.hotelPhone,
          hotelDescription: user.hotelDescription,
          hotelCategory: user.hotelCategory,
          hotelImage: user.hotelImage,
          hotelRating: user.hotelRating,
          isOpen: user.isOpen,
          deliveryFee: user.deliveryFee,
          totalOrders: user.totalOrders,
          totalSpent: user.totalSpent,
          totalRevenue: user.totalRevenue
        },
        token
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user location
 */
const updateLocation = async (req, res, next) => {
  try {
    const { latitude, longitude, address, city } = req.body;
    
    const user = await User.findByIdAndUpdate(
      req.user._id,
      { location: { latitude, longitude, address, city } },
      { new: true }
    ).select('-password');

    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Get current user profile
 */
const getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id).select('-password');
    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Update hotel settings (restaurant only)
 */
const updateHotelSettings = async (req, res, next) => {
  try {
    const { 
      hotelName, hotelAddress, hotelPhone, hotelDescription, hotelImage, hotelCategory, 
      isOpen, deliveryFee, minOrderAmount, deliveryRadius 
    } = req.body;

    // If changing hotel name, check uniqueness
    if (hotelName) {
      const existingHotel = await User.findOne({ 
        hotelName: { $regex: new RegExp(`^${hotelName}$`, 'i') },
        role: 'restaurant',
        _id: { $ne: req.user._id }
      });
      if (existingHotel) {
        return res.status(400).json({ 
          success: false, 
          message: 'Hotel name already taken. Please choose a different name.' 
        });
      }
    }

    const updateData = {};
    if (hotelName !== undefined) updateData.hotelName = hotelName;
    if (hotelAddress !== undefined) updateData.hotelAddress = hotelAddress;
    if (hotelPhone !== undefined) updateData.hotelPhone = hotelPhone;
    if (hotelDescription !== undefined) updateData.hotelDescription = hotelDescription;
    if (hotelImage !== undefined) updateData.hotelImage = hotelImage;
    if (hotelCategory !== undefined) updateData.hotelCategory = hotelCategory;
    if (isOpen !== undefined) updateData.isOpen = isOpen;
    if (deliveryFee !== undefined) updateData.deliveryFee = deliveryFee;
    if (minOrderAmount !== undefined) updateData.minOrderAmount = minOrderAmount;
    if (deliveryRadius !== undefined) updateData.deliveryRadius = deliveryRadius;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true }
    ).select('-password');

    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Get user stats
 */
const getUserStats = async (req, res, next) => {
  try {
    const Order = require('../models/Order');
    const ordersCount = await Order.countDocuments({ user: req.user._id });
    const user = await User.findById(req.user._id);

    res.json({
      success: true,
      data: {
        ordersCount,
        favoritesCount: 0,
        reviewsCount: 0,
        totalSpent: user?.totalSpent || 0,
        walletBalance: user?.walletBalance || 0,
        level: user?.level || 'Regular'
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Update user profile
 */
const updateProfile = async (req, res, next) => {
  try {
    const { name, phone, address } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { name, phone, address },
      { new: true, runValidators: true }
    ).select('-password');

    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

/**
 * Change password
 */
const changePassword = async (req, res, next) => {
  try {
    const { currentPassword, newPassword } = req.body;

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const isMatch = await comparePassword(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: 'Current password is incorrect' });
    }

    user.password = await hashPassword(newPassword);
    await user.save();

    res.json({ success: true, message: 'Password changed successfully' });
  } catch (error) {
    next(error);
  }
};

/**
 * Get wallet info
 */
const getWallet = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id);
    
    res.json({
      success: true,
      data: {
        balance: user?.walletBalance || 0,
        transactions: user?.walletTransactions || []
      }
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Top up wallet
 */
const topUpWallet = async (req, res, next) => {
  try {
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Invalid amount' });
    }

    const user = await User.findById(req.user._id);
    user.walletBalance = (user.walletBalance || 0) + amount;
    user.walletTransactions = user.walletTransactions || [];
    user.walletTransactions.unshift({
      type: 'credit',
      amount,
      description: 'Wallet Top Up',
      date: new Date().toISOString()
    });
    await user.save();

    res.json({ success: true, data: { balance: user.walletBalance } });
  } catch (error) {
    next(error);
  }
};

/**
 * Delete account
 */
const deleteAccount = async (req, res, next) => {
  try {
    await User.findByIdAndDelete(req.user._id);
    res.json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    next(error);
  }
};

/**
 * Toggle favorite hotel
 */
const toggleFavoriteHotel = async (req, res, next) => {
  try {
    const { hotelId } = req.body;
    
    if (!hotelId) {
      return res.status(400).json({ success: false, message: 'Hotel ID is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const favoriteIndex = user.favoriteHotels?.indexOf(hotelId) ?? -1;
    let isFavorite = false;

    if (favoriteIndex === -1) {
      // Add to favorites
      user.favoriteHotels = user.favoriteHotels || [];
      user.favoriteHotels.push(hotelId);
      isFavorite = true;
    } else {
      // Remove from favorites
      user.favoriteHotels.splice(favoriteIndex, 1);
      isFavorite = false;
    }

    await user.save();

    res.json({ 
      success: true, 
      data: { 
        isFavorite, 
        favoriteCount: user.favoriteHotels.length 
      } 
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Get favorite hotels
 */
const getFavoriteHotels = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id)
      .populate('favoriteHotels', 'hotelName hotelAddress hotelPhone hotelDescription hotelImage hotelRating hotelCategory isOpen deliveryFee minOrderAmount totalRatings');

    const hotels = (user.favoriteHotels || []).map(hotel => ({
      _id: hotel._id,
      id: hotel._id,
      hotelName: hotel.hotelName,
      name: hotel.hotelName,
      hotelAddress: hotel.hotelAddress,
      address: hotel.hotelAddress,
      hotelPhone: hotel.hotelPhone,
      phone: hotel.hotelPhone,
      hotelDescription: hotel.hotelDescription,
      description: hotel.hotelDescription,
      hotelImage: hotel.hotelImage,
      image: hotel.hotelImage,
      hotelRating: hotel.hotelRating,
      rating: hotel.hotelRating,
      hotelCategory: hotel.hotelCategory,
      category: hotel.hotelCategory,
      isOpen: hotel.isOpen,
      deliveryFee: hotel.deliveryFee,
      minOrderAmount: hotel.minOrderAmount,
      totalRatings: hotel.totalRatings
    }));

    res.json({ success: true, data: hotels });
  } catch (error) {
    next(error);
  }
};

/**
 * Check if hotel is favorite
 */
const checkFavoriteHotel = async (req, res, next) => {
  try {
    const { hotelId } = req.params;
    const user = await User.findById(req.user._id);
    
    const isFavorite = user.favoriteHotels?.includes(hotelId) || false;
    
    res.json({ success: true, data: { isFavorite } });
  } catch (error) {
    next(error);
  }
};

/**
 * Forgot Password - Send OTP to email
 */
const forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email is required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      // Don't reveal if email exists for security
      return res.json({ success: true, message: 'If the email exists, an OTP has been sent' });
    }

    // Delete any existing OTPs for this email
    await OTP.deleteMany({ email: email.toLowerCase() });

    // Generate new OTP
    const otp = generateOTP();
    
    // Save OTP to database
    await OTP.create({
      email: email.toLowerCase(),
      otp,
      expiresAt: new Date(Date.now() + 10 * 60 * 1000) // 10 minutes
    });

    // Send OTP email
    const emailResult = await sendOTPEmail(email, otp, user.name);
    
    if (!emailResult.success) {
      console.error('Failed to send OTP email:', emailResult.error);
      // Still return success to not reveal email existence
    }

    res.json({ 
      success: true, 
      message: 'If the email exists, an OTP has been sent',
      // In development, return OTP for testing (remove in production)
      ...(process.env.NODE_ENV === 'development' && { devOtp: otp })
    });
  } catch (error) {
    next(error);
  }
};

/**
 * Verify OTP
 */
const verifyOTP = async (req, res, next) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({ success: false, message: 'Email and OTP are required' });
    }

    const otpRecord = await OTP.findOne({ 
      email: email.toLowerCase(), 
      otp,
      expiresAt: { $gt: new Date() }
    });

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
    }

    // Mark OTP as verified
    otpRecord.verified = true;
    await otpRecord.save();

    res.json({ success: true, message: 'OTP verified successfully' });
  } catch (error) {
    next(error);
  }
};

/**
 * Reset Password (after OTP verification)
 */
const resetPassword = async (req, res, next) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ success: false, message: 'Email, OTP, and new password are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }

    // Find verified OTP
    const otpRecord = await OTP.findOne({ 
      email: email.toLowerCase(), 
      otp,
      verified: true,
      expiresAt: { $gt: new Date() }
    });

    if (!otpRecord) {
      return res.status(400).json({ success: false, message: 'Invalid or expired OTP. Please request a new one.' });
    }

    // Find user and update password
    const user = await User.findOne({ email: email.toLowerCase() });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Hash new password and save
    user.password = await hashPassword(newPassword);
    await user.save();

    // Delete used OTP
    await OTP.deleteMany({ email: email.toLowerCase() });

    // Clear any failed login attempts
    clearFailedAttempts(email);

    res.json({ success: true, message: 'Password reset successfully. You can now login with your new password.' });
  } catch (error) {
    next(error);
  }
};

module.exports = { 
  register, 
  login, 
  updateLocation, 
  getProfile, 
  updateHotelSettings, 
  getUserStats,
  updateProfile,
  changePassword,
  getWallet,
  deleteAccount,
  topUpWallet,
  forgotPassword,
  verifyOTP,
  resetPassword,
  toggleFavoriteHotel,
  getFavoriteHotels,
  checkFavoriteHotel
};
