const express = require('express');
const { getAllRestaurants, getRestaurantById, createRestaurant, updateRestaurant, deleteRestaurant } = require('../controllers/restaurant.controller');
const { protect, authorize } = require('../middlewares/auth.middleware');

const router = express.Router();

router.get('/', getAllRestaurants);
router.get('/:id', getRestaurantById);
router.post('/', protect, authorize('restaurant'), createRestaurant);
router.put('/:id', protect, authorize('restaurant'), updateRestaurant);
router.delete('/:id', protect, authorize('restaurant'), deleteRestaurant);

module.exports = router;
