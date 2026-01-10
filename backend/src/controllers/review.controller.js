/**
 * Review Controller
 */
const Review = require('../models/Review');
const Food = require('../models/Food');
const Restaurant = require('../models/Restaurant');
const User = require('../models/User');

const createReview = async (req, res, next) => {
  try {
    const { foodId, restaurantId, hotelId, orderId, rating, comment, images } = req.body;
    
    const review = await Review.create({
      user: req.user._id,
      food: foodId,
      restaurant: restaurantId,
      hotel: hotelId,
      order: orderId,
      rating,
      comment,
      images
    });

    // Update food rating
    if (foodId) {
      const food = await Food.findById(foodId);
      if (food) {
        const newTotal = food.totalRatings + 1;
        const newRating = ((food.rating * food.totalRatings) + rating) / newTotal;
        await Food.findByIdAndUpdate(foodId, { rating: newRating, totalRatings: newTotal });
      }
    }

    // Update restaurant rating (legacy support)
    if (restaurantId) {
      const restaurant = await Restaurant.findById(restaurantId);
      if (restaurant) {
        const newTotal = restaurant.totalRatings + 1;
        const newRating = ((restaurant.rating * restaurant.totalRatings) + rating) / newTotal;
        await Restaurant.findByIdAndUpdate(restaurantId, { rating: newRating, totalRatings: newTotal });
      }
    }

    // Update hotel rating (User with role 'restaurant')
    if (hotelId) {
      const hotel = await User.findById(hotelId);
      if (hotel && hotel.role === 'restaurant') {
        const currentRating = hotel.hotelRating || 4.5;
        const totalRatings = hotel.totalRatings || 0;
        const newTotal = totalRatings + 1;
        const newRating = ((currentRating * totalRatings) + rating) / newTotal;
        await User.findByIdAndUpdate(hotelId, { hotelRating: newRating, totalRatings: newTotal });
      }
    }

    // Populate user for response
    await review.populate('user', 'name');

    res.status(201).json({ success: true, data: review });
  } catch (error) {
    next(error);
  }
};

const getReviews = async (req, res, next) => {
  try {
    const { foodId, restaurantId, hotelId } = req.query;
    const filter = {};
    if (foodId) {
      filter.food = foodId;
    }
    if (restaurantId) {
      filter.$or = [{ restaurant: restaurantId }, { hotel: restaurantId }];
    }
    if (hotelId) {
      filter.hotel = hotelId;
    }
    
    const reviews = await Review.find(filter)
      .populate('user', 'name')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: reviews });
  } catch (error) {
    next(error);
  }
};

module.exports = { createReview, getReviews };
