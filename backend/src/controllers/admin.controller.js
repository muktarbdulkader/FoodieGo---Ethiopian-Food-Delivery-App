/**
 * Admin Controller - Hotel Isolated Management System
 * Each admin only sees their own hotel's data
 */
const User = require('../models/User');
const Food = require('../models/Food');
const Order = require('../models/Order');
const Review = require('../models/Review');

// Get comprehensive dashboard stats (hotel isolated)
const getDashboardStats = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;

    // Build flexible filter for hotelId matching (string or ObjectId)
    const hotelFilter = {
      $or: [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': hotelId },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ]
    };

    // Count stats for this hotel only (including reviews)
    const [totalFoods, totalOrders, pendingOrders, totalReviews] = await Promise.all([
      Food.countDocuments({ hotelId }),
      Order.countDocuments(hotelFilter),
      Order.countDocuments({ ...hotelFilter, status: 'pending' }),
      Review.countDocuments({ hotel: hotelId })
    ]);

    // Revenue calculations for this hotel
    const revenueStats = await Order.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      { 
        $match: { 
          $or: [
            { 'items.hotelId': hotelIdStr },
            ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
          ]
        } 
      },
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
      { 
        $match: { 
          $or: [
            { 'items.hotelId': hotelIdStr },
            ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
          ]
        } 
      },
      {
        $group: {
          _id: null,
          todayOrders: { $sum: 1 },
          todayRevenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } }
        }
      }
    ]);

    // Recent orders containing this hotel's items
    const recentOrders = await Order.find(hotelFilter)
      .sort({ createdAt: -1 })
      .limit(10)
      .populate('user', 'name email phone');

    // Top selling foods for this hotel
    const topFoods = await Order.aggregate([
      { $unwind: '$items' },
      { 
        $match: { 
          $or: [
            { 'items.hotelId': hotelIdStr },
            ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
          ]
        } 
      },
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
        totalReviews,
        hotelRating: req.user.hotelRating || 4.5,
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
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;
    
    // Build flexible filter
    const hotelFilter = {
      $or: [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': hotelId },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ]
    };
    
    // Get unique users who ordered from this hotel
    const orderUsers = await Order.distinct('user', hotelFilter);
    
    const users = await User.find({ _id: { $in: orderUsers }, role: 'user' })
      .select('-password')
      .sort({ createdAt: -1 });
    
    // Get order stats for each user from this hotel
    const userStats = await Order.aggregate([
      { $match: hotelFilter },
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
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;
    
    const user = await User.findById(req.params.id).select('-password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Build flexible filter
    const hotelFilter = {
      user: req.params.id,
      $or: [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': hotelId },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ]
    };

    // Get orders from this hotel only
    const orders = await Order.find(hotelFilter).sort({ createdAt: -1 }).limit(20);

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
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;
    
    // Build flexible filter
    const hotelFilter = {
      $or: [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': hotelId },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ],
      'payment.status': { $exists: true }
    };
    
    const orders = await Order.find(hotelFilter)
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
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;
    
    // Build flexible filter
    const hotelFilter = {
      $or: [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': hotelId },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ],
      status: { $in: ['confirmed', 'preparing', 'ready', 'out_for_delivery'] }
    };
    
    const activeDeliveries = await Order.find(hotelFilter)
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
    
    console.log(`Assigning driver: ${driverName}, phone: ${driverPhone}`);
    
    // Find the delivery user to get their ID - try multiple ways
    let deliveryUser = await User.findOne({ name: driverName, role: 'delivery' });
    
    // If not found by exact name, try by phone
    if (!deliveryUser && driverPhone) {
      deliveryUser = await User.findOne({ phone: driverPhone, role: 'delivery' });
    }
    
    // If still not found, try case-insensitive name search
    if (!deliveryUser) {
      deliveryUser = await User.findOne({ 
        name: { $regex: new RegExp(`^${driverName}$`, 'i') }, 
        role: 'delivery' 
      });
    }
    
    console.log(`Found delivery user: ${deliveryUser ? deliveryUser._id : 'NOT FOUND'}`);
    
    const updateData = {
      'delivery.driverName': driverName,
      'delivery.driverPhone': driverPhone,
      'delivery.trackingStatus': 'assigned',
      'delivery.assignedAt': new Date(),
      'delivery.type': 'delivery', // Ensure delivery type is set
      status: 'out_for_delivery'
    };
    
    // Set driverId if we found the delivery user
    if (deliveryUser) {
      updateData['delivery.driverId'] = deliveryUser._id;
    }
    
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('user', 'name phone email');

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    
    console.log(`Order ${order.orderNumber} assigned to driver. driverId: ${order.delivery?.driverId}, driverName: ${order.delivery?.driverName}`);

    // Send email notification to customer (using hotel's email as sender)
    if (order.user && order.user.email) {
      const { sendOrderStatusEmail } = require('../utils/email');
      const hotelEmail = req.user.email; // Hotel owner's email
      sendOrderStatusEmail(order.user.email, {
        orderNumber: order.orderNumber,
        hotelName: order.items[0]?.hotelName || req.user.hotelName,
        driverName,
        driverPhone
      }, 'out_for_delivery', hotelEmail).catch(err => console.error('Customer email failed:', err));
    }

    // Send email notification to delivery driver (using hotel's email as sender)
    if (deliveryUser && deliveryUser.email) {
      const { sendDriverAssignmentEmail } = require('../utils/email');
      const hotelName = order.items[0]?.hotelName || req.user.hotelName || 'Restaurant';
      const hotelEmail = req.user.email; // Hotel owner's email
      sendDriverAssignmentEmail(deliveryUser.email, {
        orderNumber: order.orderNumber,
        hotelName,
        hotelAddress: req.user.hotelAddress,
        userName: order.user?.name || 'Customer',
        userPhone: order.user?.phone,
        address: order.deliveryAddress?.fullAddress || 'N/A',
        totalPrice: order.totalPrice
      }, hotelEmail).catch(err => console.error('Driver email failed:', err));
    }

    res.json({ success: true, data: order });
  } catch (error) {
    console.error('Error assigning driver:', error);
    next(error);
  }
};

// Get analytics for this hotel
const getAnalytics = async (req, res, next) => {
  try {
    const hotelId = req.user._id;
    const hotelIdStr = hotelId.toString();
    const hotelName = req.user.hotelName;
    const { period = '7d' } = req.query;
    let startDate = new Date();
    
    switch (period) {
      case '24h': startDate.setHours(startDate.getHours() - 24); break;
      case '7d': startDate.setDate(startDate.getDate() - 7); break;
      case '30d': startDate.setDate(startDate.getDate() - 30); break;
      case '90d': startDate.setDate(startDate.getDate() - 90); break;
    }

    // Build flexible match for hotelId
    const hotelMatch = {
      $or: [
        { 'items.hotelId': hotelIdStr },
        ...(hotelName ? [{ 'items.hotelName': hotelName }] : [])
      ]
    };

    // Daily revenue for this hotel
    const dailyRevenue = await Order.aggregate([
      { $match: { createdAt: { $gte: startDate }, status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      { $match: hotelMatch },
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

// Get all delivery users (for assigning drivers)
const getDeliveryUsers = async (req, res, next) => {
  try {
    const deliveryUsers = await User.find({ role: 'delivery', isActive: true })
      .select('name phone email')
      .sort({ name: 1 });
    
    res.json({ success: true, count: deliveryUsers.length, data: deliveryUsers });
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
  getAnalytics,
  getDeliveryUsers
};
