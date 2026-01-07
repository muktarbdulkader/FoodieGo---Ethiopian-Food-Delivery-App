/**
 * Restaurant Controller
 */
const Restaurant = require('../models/Restaurant');
const Food = require('../models/Food');

const getAllRestaurants = async (req, res, next) => {
  try {
    const { cuisine, featured, search } = req.query;
    const filter = { isActive: true };
    if (cuisine) filter.cuisine = cuisine;
    if (featured === 'true') filter.isFeatured = true;
    if (search) filter.name = { $regex: search, $options: 'i' };
    
    const restaurants = await Restaurant.find(filter).sort({ rating: -1 });
    res.json({ success: true, count: restaurants.length, data: restaurants });
  } catch (error) {
    next(error);
  }
};

const getRestaurantById = async (req, res, next) => {
  try {
    const restaurant = await Restaurant.findById(req.params.id);
    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });
    
    const foods = await Food.find({ restaurantId: restaurant._id, isAvailable: true });
    res.json({ success: true, data: { restaurant, foods } });
  } catch (error) {
    next(error);
  }
};

const createRestaurant = async (req, res, next) => {
  try {
    const restaurant = await Restaurant.create({ ...req.body, owner: req.user._id });
    res.status(201).json({ success: true, data: restaurant });
  } catch (error) {
    next(error);
  }
};

const updateRestaurant = async (req, res, next) => {
  try {
    const restaurant = await Restaurant.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });
    res.json({ success: true, data: restaurant });
  } catch (error) {
    next(error);
  }
};

const deleteRestaurant = async (req, res, next) => {
  try {
    const restaurant = await Restaurant.findByIdAndDelete(req.params.id);
    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });
    res.json({ success: true, message: 'Restaurant deleted' });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAllRestaurants, getRestaurantById, createRestaurant, updateRestaurant, deleteRestaurant };
