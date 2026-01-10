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

    const hotel = await User.findOne({ _id: hotelId, role: 'restaurant' });
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
    const hotels = await User.find({ role: 'restaurant' })
      .select('name hotelName hotelImage address location rating hotelAddress hotelRating');
    res.json({ success: true, data: hotels });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Confirm event completion (user or hotel)
exports.confirmComplete = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userRole = req.user.role;
    
    let booking;
    if (userRole === 'restaurant') {
      // Hotel confirming completion
      booking = await EventBooking.findOne({ _id: bookingId, hotel: req.user._id });
      if (!booking) {
        return res.status(404).json({ success: false, message: 'Booking not found' });
      }
      booking.hotelConfirmedComplete = true;
    } else {
      // User confirming completion
      booking = await EventBooking.findOne({ _id: bookingId, user: req.user._id });
      if (!booking) {
        return res.status(404).json({ success: false, message: 'Booking not found' });
      }
      booking.userConfirmedComplete = true;
    }
    
    // If both confirmed, mark as completed
    if (booking.userConfirmedComplete && booking.hotelConfirmedComplete) {
      booking.status = 'completed';
    }
    
    await booking.save();
    res.json({ success: true, data: booking });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Delete booking (only if both parties confirmed complete)
exports.deleteBooking = async (req, res) => {
  try {
    const { bookingId } = req.params;
    const userRole = req.user.role;
    
    let booking;
    if (userRole === 'restaurant') {
      booking = await EventBooking.findOne({ _id: bookingId, hotel: req.user._id });
    } else {
      booking = await EventBooking.findOne({ _id: bookingId, user: req.user._id });
    }
    
    if (!booking) {
      return res.status(404).json({ success: false, message: 'Booking not found' });
    }
    
    // Only allow delete if both parties confirmed complete OR if cancelled
    if (booking.status === 'cancelled') {
      await EventBooking.findByIdAndDelete(bookingId);
      return res.json({ success: true, message: 'Cancelled booking deleted' });
    }
    
    if (!booking.userConfirmedComplete || !booking.hotelConfirmedComplete) {
      return res.status(400).json({ 
        success: false, 
        message: 'Both user and hotel must confirm completion before deleting',
        userConfirmed: booking.userConfirmedComplete,
        hotelConfirmed: booking.hotelConfirmedComplete
      });
    }
    
    await EventBooking.findByIdAndDelete(bookingId);
    res.json({ success: true, message: 'Booking deleted successfully' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
