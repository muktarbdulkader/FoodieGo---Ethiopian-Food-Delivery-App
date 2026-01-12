/**
 * Food Controller - With Hotel Isolation
 */
const Food = require('../models/Food');
const User = require('../models/User');

// Get all foods (users see all, restaurants see only their hotel's foods)
const getAllFoods = async (req, res, next) => {
  try {
    const { category, search, available, hotelId, hotelName } = req.query;
    const filter = {};
    
    // If restaurant, only show their hotel's foods
    if (req.user && req.user.role === 'restaurant') {
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
    const { category, search, isOpen, lat, lng, radius } = req.query;
    // Show all restaurant users - they may not have hotelName set yet
    const filter = { role: 'restaurant' };
    
    if (category) filter.hotelCategory = category;
    if (isOpen !== undefined) filter.isOpen = isOpen === 'true';
    if (search) {
      filter.$or = [
        { hotelName: { $regex: search, $options: 'i' } },
        { hotelAddress: { $regex: search, $options: 'i' } },
        { name: { $regex: search, $options: 'i' } } // Also search by user name
      ];
    }

    let hotels = await User.find(filter)
      .select('name hotelName hotelAddress hotelPhone hotelDescription hotelImage hotelRating hotelCategory isOpen deliveryFee minOrderAmount deliveryRadius location email')
      .sort({ hotelRating: -1, createdAt: -1 });

    console.log(`Found ${hotels.length} restaurants in database`);

    // Transform hotels - use name as fallback for hotelName
    hotels = hotels.map(hotel => {
      const hotelObj = hotel.toObject();
      // Use user's name as fallback if hotelName not set
      if (!hotelObj.hotelName) {
        hotelObj.hotelName = hotelObj.name || 'Restaurant';
      }
      return hotelObj;
    });

    // If user location provided, calculate distance and sort by proximity
    if (lat && lng) {
      const userLat = parseFloat(lat);
      const userLng = parseFloat(lng);
      const maxRadius = radius ? parseFloat(radius) : 100; // Default 100km radius (increased)

      // Calculate distance for each hotel
      hotels = hotels.map(hotel => {
        if (hotel.location && hotel.location.latitude && hotel.location.longitude) {
          const distance = calculateDistance(
            userLat, userLng,
            hotel.location.latitude, hotel.location.longitude
          );
          hotel.distance = distance;
          hotel.distanceText = distance < 1 
            ? `${Math.round(distance * 1000)}m` 
            : `${distance.toFixed(1)}km`;
        } else {
          // Hotels without location - don't filter them out, just no distance
          hotel.distance = null;
          hotel.distanceText = null;
        }
        return hotel;
      });
      
      // Sort by distance (hotels with location first, then others)
      hotels.sort((a, b) => {
        if (a.distance === null && b.distance === null) return 0;
        if (a.distance === null) return 1;
        if (b.distance === null) return -1;
        return a.distance - b.distance;
      });
    }

    // Get food count for each hotel
    const hotelsWithCount = await Promise.all(hotels.map(async (hotel) => {
      const hotelId = hotel._id || hotel.id;
      const foodCount = await Food.countDocuments({ hotelId, isAvailable: true });
      return { ...hotel, foodCount };
    }));

    console.log(`Returning ${hotelsWithCount.length} hotels`);
    res.json({ success: true, count: hotelsWithCount.length, data: hotelsWithCount });
  } catch (error) {
    console.error('Error fetching hotels:', error);
    next(error);
  }
};

// Helper function to calculate distance between two coordinates (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg) {
  return deg * (Math.PI / 180);
}

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

// Update food (restaurant only - can only update their own foods)
const updateFood = async (req, res, next) => {
  try {
    // Ensure restaurant can only update their own foods
    const filter = { _id: req.params.id };
    if (req.user.role === 'restaurant') {
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

// Delete food (restaurant only - can only delete their own foods)
const deleteFood = async (req, res, next) => {
  try {
    const filter = { _id: req.params.id };
    if (req.user.role === 'restaurant') {
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

// Like/Unlike food
const toggleLikeFood = async (req, res, next) => {
  try {
    const food = await Food.findById(req.params.id);
    if (!food) {
      return res.status(404).json({ success: false, message: 'Food not found' });
    }

    const userId = req.user._id;
    const isLiked = food.likedBy.includes(userId);

    if (isLiked) {
      // Unlike
      food.likedBy.pull(userId);
      food.likeCount = Math.max(0, food.likeCount - 1);
    } else {
      // Like
      food.likedBy.push(userId);
      food.likeCount += 1;
    }

    await food.save();
    res.json({ 
      success: true, 
      data: { 
        isLiked: !isLiked, 
        likeCount: food.likeCount 
      } 
    });
  } catch (error) {
    next(error);
  }
};

// Increment view count
const incrementViewCount = async (req, res, next) => {
  try {
    const food = await Food.findByIdAndUpdate(
      req.params.id,
      { $inc: { viewCount: 1 } },
      { new: true }
    );
    if (!food) {
      return res.status(404).json({ success: false, message: 'Food not found' });
    }
    res.json({ success: true, data: { viewCount: food.viewCount } });
  } catch (error) {
    next(error);
  }
};

// Get popular foods (by likes and views)
const getPopularFoods = async (req, res, next) => {
  try {
    const { limit = 10 } = req.query;
    const foods = await Food.find({ isAvailable: true })
      .sort({ likeCount: -1, viewCount: -1 })
      .limit(parseInt(limit))
      .populate('hotelId', 'hotelName hotelImage');
    res.json({ success: true, data: foods });
  } catch (error) {
    next(error);
  }
};

// Get admin's custom categories
const getAdminCategories = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const categories = await Food.distinct('category', { hotelId });
    res.json({ success: true, data: categories });
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
  getCategories,
  toggleLikeFood,
  incrementViewCount,
  getPopularFoods,
  getAdminCategories
};
