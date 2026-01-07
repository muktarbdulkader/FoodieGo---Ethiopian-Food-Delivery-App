/**
 * Auth Controller - Extended for Hotel Management with Isolation
 */
const User = require('../models/User');
const { hashPassword, comparePassword } = require('../utils/hash');
const { generateToken } = require('../utils/jwt');

// Secret code for admin registration
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

    // Determine role - admin requires secret code
    let userRole = 'user';
    if (role === 'admin') {
      if (adminCode !== ADMIN_SECRET_CODE) {
        return res.status(403).json({ success: false, message: 'Invalid admin registration code' });
      }
      
      // Check if hotel name is unique for admins
      if (hotelName) {
        const existingHotel = await User.findOne({ 
          hotelName: { $regex: new RegExp(`^${hotelName}$`, 'i') },
          role: 'admin'
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
          message: 'Hotel name is required for admin registration' 
        });
      }
      
      userRole = 'admin';
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
      isVerified: userRole === 'admin' ? true : false
    };

    // Add hotel info for admins
    if (userRole === 'admin') {
      userData.hotelName = hotelName;
      userData.hotelAddress = hotelAddress;
      userData.hotelPhone = hotelPhone || phone;
      userData.hotelDescription = hotelDescription;
      userData.hotelCategory = hotelCategory || 'restaurant';
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
    // Handle duplicate key error for hotel name
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

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (!user.isActive) {
      return res.status(401).json({ success: false, message: 'Account is deactivated' });
    }

    const isMatch = await comparePassword(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Update last login
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
 * Update hotel settings (admin only)
 */
const updateHotelSettings = async (req, res, next) => {
  try {
    const { 
      hotelDescription, hotelImage, hotelCategory, 
      isOpen, deliveryFee, minOrderAmount, deliveryRadius 
    } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      { 
        hotelDescription, hotelImage, hotelCategory,
        isOpen, deliveryFee, minOrderAmount, deliveryRadius
      },
      { new: true }
    ).select('-password');

    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

module.exports = { register, login, updateLocation, getProfile, updateHotelSettings };
