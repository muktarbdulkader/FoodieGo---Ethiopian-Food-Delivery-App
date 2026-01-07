/**
 * Food Controller - With Hotel Isolation
 */
const Food = require('../models/Food');
const User = require('../models/User');

// Get all foods (users see all, admins see only their hotel's foods)
const getAllFoods = async (req, res, next) => {
  try {
    const { category, search, available, hotelId, hotelName } = req.query;
    const filter = {};
    
    // If admin, only show their hotel's foods
    if (req.user && req.user.role === 'admin') {
      filter.hotelId = req.user._id;
    }
    
    // Filter by specific hotel if requested
    if (hotelId) filter.hotelId = hotelId;
    if (hotelName) filter.hotelName = { $regex: hotelName, $options: 'i' };
    
    if (category && category !== 'All') filter.category = category;
    if (available !== undefined) filter.isAvailable = available === 'true';
    if (search) filter.name = { $regex: search, $options: 'i' };

    const foods = await Food.find(filter)
      .populate('hotelId', 'hotelName hotelImage hotelRating hotelAddress isOpen')
      .sort({ createdAt: -1 });
    res.json({ success: true, count: foods.length, data: foods });
  } catch (error) {
    next(error);
  }
};

// Get foods by hotel
const getFoodsByHotel = async (req, res, next) => {
  try {
    const { hotelId } = req.params;
    const { category } = req.query;
    
    const filter = { hotelId, isAvailable: true };
    if (category && category !== 'All') filter.category = category;

    const foods = await Food.find(filter).sort({ isFeatured: -1, createdAt: -1 });
    
    // Get hotel info
    const hotel = await User.findById(hotelId).select(
      'hotelName hotelAddress hotelPhone hotelDescription hotelImage hotelRating hotelCategory isOpen deliveryFee minOrderAmount'
    );

    res.json({ 
      success: true, 
      hotel,
      count: foods.length, 
      data: foods 
    });
  } catch (error) {
    next(error);
  }
};

// Get all hotels (for users to browse)
const getAllHotels = async (req, res, next) => {
  try {
    const { category, search, isOpen } = req.query;
    const filter = { role: 'admin', hotelName: { $exists: true, $ne: null } };
    
    if (category) filter.hotelCategory = category;
    if (isOpen !== undefined) filter.isOpen = isOpen === 'true';
    if (search) {
      filter.$or = [
        { hotelName: { $regex: search, $options: 'i' } },
        { hotelAddress: { $regex: search, $options: 'i' } }
      ];
    }

    const hotels = await User.find(filter)
      .select('hotelName hotelAddress hotelPhone hotelDescription hotelImage hotelRating hotelCategory isOpen deliveryFee minOrderAmount deliveryRadius')
      .sort({ hotelRating: -1 });

    // Get food count for each hotel
    const hotelsWithCount = await Promise.all(hotels.map(async (hotel) => {
      const foodCount = await Food.countDocuments({ hotelId: hotel._id, isAvailable: true });
      return { ...hotel.toObject(), foodCount };
    }));

    res.json({ success: true, count: hotels.length, data: hotelsWithCount });
  } catch (error) {
    next(error);
  }
};

// Get single food
const getFoodById = async (req, res, next) => {
  try {
    const food = await Food.findById(req.params.id)
      .populate('hotelId', 'hotelName hotelImage hotelRating hotelAddress isOpen deliveryFee');
    if (!food) {
      return res.status(404).json({ success: false, message: 'Food not found' });
    }
    res.json({ success: true, data: food });
  } catch (error) {
    next(error);
  }
};

// Create food (admin only - linked to their hotel)
const createFood = async (req, res, next) => {
  try {
    // Ensure admin can only create food for their hotel
    const foodData = {
      ...req.body,
      hotelId: req.user._id,
      hotelName: req.user.hotelName
    };
    
    const food = await Food.create(foodData);
    res.status(201).json({ success: true, data: food });
  } catch (error) {
    next(error);
  }
};

// Update food (admin only - can only update their own foods)
const updateFood = async (req, res, next) => {
  try {
    // Ensure admin can only update their own foods
    const filter = { _id: req.params.id };
    if (req.user.role === 'admin') {
      filter.hotelId = req.user._id;
    }

    const food = await Food.findOneAndUpdate(filter, req.body, {
      new: true,
      runValidators: true
    });
    if (!food) {
      return res.status(404).json({ success: false, message: 'Food not found or not authorized' });
    }
    res.json({ success: true, data: food });
  } catch (error) {
    next(error);
  }
};

// Delete food (admin only - can only delete their own foods)
const deleteFood = async (req, res, next) => {
  try {
    const filter = { _id: req.params.id };
    if (req.user.role === 'admin') {
      filter.hotelId = req.user._id;
    }

    const food = await Food.findOneAndDelete(filter);
    if (!food) {
      return res.status(404).json({ success: false, message: 'Food not found or not authorized' });
    }
    res.json({ success: true, message: 'Food deleted' });
  } catch (error) {
    next(error);
  }
};

// Get categories for a hotel
const getCategories = async (req, res, next) => {
  try {
    const filter = {};
    if (req.query.hotelId) filter.hotelId = req.query.hotelId;
    
    const categories = await Food.distinct('category', filter);
    res.json({ success: true, data: ['All', ...categories] });
  } catch (error) {
    next(error);
  }
};

module.exports = { 
  getAllFoods, 
  getFoodsByHotel,
  getAllHotels,
  getFoodById, 
  createFood, 
  updateFood, 
  deleteFood,
  getCategories
};
