const EventBooking = require('../models/EventBooking');
const Food = require('../models/Food');
const User = require('../models/User');

// Create event booking
exports.createBooking = async (req, res) => {
  try {
    const {
      hotelId, eventType, eventName, eventDate, eventTime, guestCount,
      venue, customLocation, services, foodPreferences, specialRequests,
      budget, contactPhone, contactEmail
    } = req.body;

    const hotel = await User.findOne({ _id: hotelId, role: 'admin' });
    if (!hotel) {
      return res.status(404).json({ success: false, message: 'Restaurant not found' });
    }

    const booking = new EventBooking({
      user: req.user._id,
      hotel: hotelId,
      eventType,
      eventName,
      eventDate,
      eventTime,
      guestCount,
      venue,
      customLocation,
      services,
      foodPreferences,
      specialRequests,
      budget,
      contactPhone,
      contactEmail
    });

    await booking.save();
    res.status(201).json({ success: true, data: booking });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get user's bookings
exports.getUserBookings = async (req, res) => {
  try {
    const bookings = await EventBooking.find({ user: req.user._id })
      .populate('hotel', 'name hotelName hotelImage address')
      .populate('recommendedFoods', 'name price image')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: bookings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get hotel's bookings (for admin)
exports.getHotelBookings = async (req, res) => {
  try {
    const bookings = await EventBooking.find({ hotel: req.user._id })
      .populate('user', 'name email phone')
      .sort({ createdAt: -1 });
    res.json({ success: true, data: bookings });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Admin respond to booking
exports.respondToBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const { status, message, quotation, recommendedFoods } = req.body;

    const booking = await EventBooking.findOne({ _id: bookingId, hotel: req.user._id });
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }

    booking.status = status || booking.status;
    booking.adminResponse = { message, quotation, respondedAt: new Date() };
    if (recommendedFoods) booking.recommendedFoods = recommendedFoods;
    if (quotation) booking.totalPrice = quotation;

    await booking.save();
    res.json({ success: true, data: booking });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get food recommendations for event
exports.getEventRecommendations = async (req, res) => {
  try {
    const { eventType, hotelId } = req.query;
    let query = { available: true };
    if (hotelId) query.hotel = hotelId;

    const categoryMap = {
      wedding: ['Dessert', 'Bakery', 'Drinks', 'Ethiopian'],
      birthday: ['Dessert', 'Bakery', 'Fast Food', 'Drinks'],
      ceremony: ['Ethiopian', 'Drinks', 'Dessert'],
      corporate: ['Sandwich', 'Coffee', 'Salad', 'Drinks'],
      graduation: ['Dessert', 'Bakery', 'Fast Food'],
      anniversary: ['Dessert', 'Italian', 'Drinks']
    };

    const categories = categoryMap[eventType] || [];
    if (categories.length > 0) query.category = { $in: categories };

    const foods = await Food.find(query).limit(20);
    res.json({ success: true, data: foods });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Get nearby event venues
exports.getNearbyEventVenues = async (req, res) => {
  try {
    const hotels = await User.find({ role: 'admin' })
      .select('name hotelName hotelImage address location rating');
    res.json({ success: true, data: hotels });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
