/**
 * Review Controller
 */
const Review = require('../models/Review');
const Food = require('../models/Food');
const Restaurant = require('../models/Restaurant');

const createReview = async (req, res, next) => {
  try {
    const { foodId, restaurantId, orderId, rating, comment, images } = req.body;
    
    const review = await Review.create({
      user: req.user._id,
      food: foodId,
      restaurant: restaurantId,
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

    // Update restaurant rating
    if (restaurantId) {
      const restaurant = await Restaurant.findById(restaurantId);
      if (restaurant) {
        const newTotal = restaurant.totalRatings + 1;
        const newRating = ((restaurant.rating * restaurant.totalRatings) + rating) / newTotal;
        await Restaurant.findByIdAndUpdate(restaurantId, { rating: newRating, totalRatings: newTotal });
      }
    }

    res.status(201).json({ success: true, data: review });
  } catch (error) {
    next(error);
  }
};

const getReviews = async (req, res, next) => {
  try {
    const { foodId, restaurantId } = req.query;
    const filter = {};
    if (foodId) filter.food = foodId;
    if (restaurantId) filter.restaurant = restaurantId;
    
    const reviews = await Review.find(filter)
      .populate('user', 'name')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: reviews });
  } catch (error) {
    next(error);
  }
};

module.exports = { createReview, getReviews };
