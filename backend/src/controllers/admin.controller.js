/**
 * Admin Controller - Hotel Isolated Management System
 * Each admin only sees their own hotel's data
 */
const User = require('../models/User');
const Food = require('../models/Food');
const Order = require('../models/Order');

// Get comprehensive dashboard stats (hotel isolated)
const getDashboardStats = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const hotelName = req.user.hotelName;

    // Get hotel's foods
    const hotelFoods = await Food.find({ hotelId }).select('_id');
    const foodIds = hotelFoods.map(f => f._id);

    // Count stats for this hotel only
    const [totalFoods, totalOrders, pendingOrders] = await Promise.all([
      Food.countDocuments({ hotelId }),
      Order.countDocuments({ 'items.hotelId': hotelId }),
      Order.countDocuments({ 'items.hotelId': hotelId, status: 'pending' })
    ]);

    // Revenue calculations for this hotel
    const revenueStats = await Order.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      { $match: { 'items.hotelId': hotelId.toString() } },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
          totalItems: { $sum: '$items.quantity' }
        }
      }
    ]);

    // Today's stats for this hotel
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStats = await Order.aggregate([
      { $match: { createdAt: { $gte: today }, status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      { $match: { 'items.hotelId': hotelId.toString() } },
      {
        $group: {
          _id: null,
          todayOrders: { $sum: 1 },
          todayRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
        }
      }
    ]);

    // Recent orders containing this hotel's items
    const recentOrders = await Order.find({ 'items.hotelId': hotelId.toString() })
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('user', 'name email phone');

    // Top selling foods for this hotel
    const topFoods = await Order.aggregate([
      { $unwind: '$items' },
      { $match: { 'items.hotelId': hotelId.toString() } },
      { 
        $group: { 
          _id: '$items.name', 
          totalSold: { $sum: '$items.quantity' }, 
          revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } } 
        } 
      },
      { $sort: { totalSold: -1 } },
      { $limit: 5 }
    ]);

    res.json({
      success: true,
      data: {
        hotelName,
        totalFoods,
        totalOrders,
        pendingOrders,
        totalRevenue: revenueStats[0]?.totalRevenue || 0,
        todayOrders: todayStats[0]?.todayOrders || 0,
        todayRevenue: todayStats[0]?.todayRevenue || 0,
        recentOrders,
        topFoods
      }
    });
  } catch (error) {
    next(error);
  }
};


// Get all users (customers who ordered from this hotel)
const getAllUsers = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    
    // Get unique users who ordered from this hotel
    const orderUsers = await Order.distinct('user', { 'items.hotelId': hotelId.toString() });
    
    const users = await User.find({ _id: { $in: orderUsers }, role: 'user' })
      .select('-password')
      .sort({ createdAt: -1 });
    
    // Get order stats for each user from this hotel
    const userStats = await Order.aggregate([
      { $match: { 'items.hotelId': hotelId.toString() } },
      { $group: { _id: '$user', orderCount: { $sum: 1 }, totalSpent: { $sum: '$totalPrice' } } }
    ]);
    
    const statsMap = userStats.reduce((acc, s) => ({ ...acc, [s._id]: s }), {});
    
    const usersWithStats = users.map(user => ({
      ...user.toObject(),
      orderCount: statsMap[user._id]?.orderCount || 0,
      totalSpent: statsMap[user._id]?.totalSpent || 0
    }));

    res.json({ success: true, count: users.length, data: usersWithStats });
  } catch (error) {
    next(error);
  }
};

// Get single user details
const getUserDetails = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get orders from this hotel only
    const orders = await Order.find({ 
      user: req.params.id,
      'items.hotelId': hotelId.toString()
    }).sort({ createdAt: -1 }).limit(20);

    res.json({ success: true, data: { user, orders } });
  } catch (error) {
    next(error);
  }
};

// Update user (limited for hotel admins)
const updateUser = async (req, res, next) => {
  try {
    const { name, phone, address, isActive, isVerified } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { name, phone, address, isActive, isVerified },
      { new: true }
    ).select('-password');
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

// Update user role
const updateUserRole = async (req, res, next) => {
  try {
    const { role } = req.body;
    const user = await User.findByIdAndUpdate(req.params.id, { role }, { new: true }).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

// Delete user
const deleteUser = async (req, res, next) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    await Order.deleteMany({ user: req.params.id });
    res.json({ success: true, message: 'User and associated orders deleted' });
  } catch (error) {
    next(error);
  }
};

// Get all payments for this hotel
const getAllPayments = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    
    const orders = await Order.find({ 
      'items.hotelId': hotelId.toString(),
      'payment.status': { $exists: true } 
    })
      .select('orderNumber totalPrice payment delivery user createdAt items')
      .populate('user', 'name email phone')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: { transactions: orders, stats: [] } });
  } catch (error) {
    next(error);
  }
};

// Update payment status
const updatePaymentStatus = async (req, res, next) => {
  try {
    const { status, transactionId } = req.body;
    const updateData = { 'payment.status': status };
    if (transactionId) updateData['payment.transactionId'] = transactionId;
    if (status === 'paid') updateData['payment.paidAt'] = new Date();

    const order = await Order.findByIdAndUpdate(req.params.id, updateData, { new: true })
      .populate('user', 'name email');
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get delivery management data for this hotel
const getDeliveryManagement = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    
    const activeDeliveries = await Order.find({
      'items.hotelId': hotelId.toString(),
      status: { $in: ['confirmed', 'preparing', 'ready', 'out_for_delivery'] }
    })
      .populate('user', 'name phone address')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: { activeDeliveries, stats: [] } });
  } catch (error) {
    next(error);
  }
};

// Assign driver to order
const assignDriver = async (req, res, next) => {
  try {
    const { driverName, driverPhone } = req.body;
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      {
        'delivery.driverName': driverName,
        'delivery.driverPhone': driverPhone,
        'delivery.trackingStatus': 'assigned',
        status: 'out_for_delivery'
      },
      { new: true }
    ).populate('user', 'name phone');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get analytics for this hotel
const getAnalytics = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const { period = '7d' } = req.query;
    let startDate = new Date();
    
    switch (period) {
      case '24h': startDate.setHours(startDate.getHours() - 24); break;
      case '7d': startDate.setDate(startDate.getDate() - 7); break;
      case '30d': startDate.setDate(startDate.getDate() - 30); break;
      case '90d': startDate.setDate(startDate.getDate() - 90); break;
    }

    // Daily revenue for this hotel
    const dailyRevenue = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate }, status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      { $match: { 'items.hotelId': hotelId.toString() } },
      { $group: {
        _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
        revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
        orders: { $sum: 1 }
      }},
      { $sort: { _id: 1 } }
    ]);

    res.json({ success: true, data: { dailyRevenue, period } });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getDashboardStats,
  getAllUsers,
  getUserDetails,
  updateUser,
  updateUserRole,
  deleteUser,
  getAllPayments,
  updatePaymentStatus,
  getDeliveryManagement,
  assignDriver,
  getAnalytics
};
