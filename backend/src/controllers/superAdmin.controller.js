/**
 * Super Admin Controller
 * Platform-level management: all restaurants, users, orders, revenue
 */
const User = require('../models/User');
const Order = require('../models/Order');
const Food = require('../models/Food');
const Review = require('../models/Review');
const { hashPassword } = require('../utils/hash');
const { generateToken } = require('../utils/jwt');

// ─── PLATFORM DASHBOARD ──────────────────────────────────────────────────────

const getPlatformStats = async (req, res, next) => {
  try {
    const [
      totalUsers,
      totalRestaurants,
      totalDeliveryDrivers,
      totalOrders,
      totalRevenue,
      activeRestaurants,
      pendingOrders,
      totalFoods,
    ] = await Promise.all([
      User.countDocuments({ role: 'user' }),
      User.countDocuments({ role: 'restaurant' }),
      User.countDocuments({ role: 'delivery' }),
      Order.countDocuments(),
      Order.aggregate([
        { $match: { status: { $ne: 'cancelled' } } },
        { $group: { _id: null, total: { $sum: '$totalPrice' } } },
      ]),
      User.countDocuments({ role: 'restaurant', isActive: true }),
      Order.countDocuments({ status: 'pending' }),
      Food.countDocuments(),
    ]);

    // Revenue last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentRevenue = await Order.aggregate([
      { $match: { createdAt: { $gte: sevenDaysAgo }, status: { $ne: 'cancelled' } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
          revenue: { $sum: '$totalPrice' },
          orders: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Top restaurants by revenue
    const topRestaurants = await Order.aggregate([
      { $match: { status: { $ne: 'cancelled' } } },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.hotelId',
          hotelName: { $first: '$items.hotelName' },
          revenue: { $sum: { $multiply: ['$items.price', '$items.quantity'] } },
          orders: { $sum: 1 },
        },
      },
      { $sort: { revenue: -1 } },
      { $limit: 5 },
    ]);

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          totalRestaurants,
          totalDeliveryDrivers,
          totalOrders,
          totalRevenue: totalRevenue[0]?.total || 0,
          activeRestaurants,
          pendingOrders,
          totalFoods,
        },
        recentRevenue,
        topRestaurants,
      },
    });
  } catch (error) {
    next(error);
  }
};

// ─── RESTAURANT MANAGEMENT ───────────────────────────────────────────────────

const getAllRestaurants = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, status } = req.query;
    const skip = (page - 1) * limit;

    const filter = { role: 'restaurant' };
    if (search) {
      filter.$or = [
        { hotelName: { $regex: search, $options: 'i' } },
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
      ];
    }
    if (status === 'active') filter.isActive = true;
    if (status === 'inactive') filter.isActive = false;

    const [restaurants, total] = await Promise.all([
      User.find(filter)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),
      User.countDocuments(filter),
    ]);

    // Attach order counts
    const restaurantIds = restaurants.map((r) => r._id.toString());
    const orderCounts = await Order.aggregate([
      { $unwind: '$items' },
      { $match: { 'items.hotelId': { $in: restaurantIds } } },
      { $group: { _id: '$items.hotelId', count: { $sum: 1 }, revenue: { $sum: '$items.price' } } },
    ]);
    const orderMap = {};
    orderCounts.forEach((o) => { orderMap[o._id] = o; });

    const enriched = restaurants.map((r) => ({
      ...r.toObject(),
      orderCount: orderMap[r._id.toString()]?.count || 0,
      revenue: orderMap[r._id.toString()]?.revenue || 0,
    }));

    res.json({ success: true, count: total, data: enriched });
  } catch (error) {
    next(error);
  }
};

const getRestaurantById = async (req, res, next) => {
  try {
    const restaurant = await User.findOne({ _id: req.params.id, role: 'restaurant' }).select('-password');
    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });

    const [orders, foods, reviews] = await Promise.all([
      Order.find({ 'items.hotelId': req.params.id }).sort({ createdAt: -1 }).limit(20),
      Food.find({ hotelId: req.params.id }),
      Review.find({ hotel: req.params.id }).populate('user', 'name'),
    ]);

    res.json({ success: true, data: { restaurant, orders, foods, reviews } });
  } catch (error) {
    next(error);
  }
};

const updateRestaurant = async (req, res, next) => {
  try {
    const { isActive, isVerified, isOpen, hotelName, hotelCategory, hotelDescription } = req.body;
    const update = {};
    if (isActive !== undefined) update.isActive = isActive;
    if (isVerified !== undefined) update.isVerified = isVerified;
    if (isOpen !== undefined) update.isOpen = isOpen;
    if (hotelName) update.hotelName = hotelName;
    if (hotelCategory) update.hotelCategory = hotelCategory;
    if (hotelDescription) update.hotelDescription = hotelDescription;

    const restaurant = await User.findOneAndUpdate(
      { _id: req.params.id, role: 'restaurant' },
      update,
      { new: true }
    ).select('-password');

    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });
    res.json({ success: true, data: restaurant });
  } catch (error) {
    next(error);
  }
};

const deleteRestaurant = async (req, res, next) => {
  try {
    const restaurant = await User.findOneAndDelete({ _id: req.params.id, role: 'restaurant' });
    if (!restaurant) return res.status(404).json({ success: false, message: 'Restaurant not found' });
    // Also delete their foods
    await Food.deleteMany({ hotelId: req.params.id });
    res.json({ success: true, message: 'Restaurant and associated data deleted' });
  } catch (error) {
    next(error);
  }
};

// ─── USER MANAGEMENT ─────────────────────────────────────────────────────────

const getAllUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, search, role } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (role) filter.role = role;
    else filter.role = { $ne: 'super_admin' }; // hide super admins from list
    if (search) {
      filter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    const [users, total] = await Promise.all([
      User.find(filter).select('-password').sort({ createdAt: -1 }).skip(skip).limit(Number(limit)),
      User.countDocuments(filter),
    ]);

    res.json({ success: true, count: total, data: users });
  } catch (error) {
    next(error);
  }
};

const updateUser = async (req, res, next) => {
  try {
    const { isActive, role, name, email } = req.body;
    const update = {};
    if (isActive !== undefined) update.isActive = isActive;
    if (name) update.name = name;
    if (email) update.email = email;
    // Only allow role changes to non-super_admin roles
    if (role && role !== 'super_admin') update.role = role;

    const user = await User.findByIdAndUpdate(req.params.id, update, { new: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: user });
  } catch (error) {
    next(error);
  }
};

const deleteUser = async (req, res, next) => {
  try {
    // Prevent deleting super admins
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    if (user.role === 'super_admin') {
      return res.status(403).json({ success: false, message: 'Cannot delete super admin accounts' });
    }
    await User.findByIdAndDelete(req.params.id);
    res.json({ success: true, message: 'User deleted' });
  } catch (error) {
    next(error);
  }
};

// ─── ORDER MANAGEMENT (PLATFORM-WIDE) ────────────────────────────────────────

const getAllOrders = async (req, res, next) => {
  try {
    const { page = 1, limit = 20, status, restaurantId } = req.query;
    const skip = (page - 1) * limit;

    const filter = {};
    if (status) filter.status = status;
    if (restaurantId) filter['items.hotelId'] = restaurantId;

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('user', 'name email phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(Number(limit)),
      Order.countDocuments(filter),
    ]);

    res.json({ success: true, count: total, data: orders });
  } catch (error) {
    next(error);
  }
};

// ─── SUPER ADMIN ACCOUNT MANAGEMENT ─────────────────────────────────────────

const createSuperAdmin = async (req, res, next) => {
  try {
    const { name, email, password, superAdminSecret } = req.body;

    // Require a platform-level secret
    if (superAdminSecret !== process.env.SUPER_ADMIN_SECRET) {
      return res.status(403).json({ success: false, message: 'Invalid super admin secret' });
    }

    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ success: false, message: 'Email already registered' });

    const hashed = await hashPassword(password);
    const admin = await User.create({
      name,
      email,
      password: hashed,
      role: 'super_admin',
      isVerified: true,
      isActive: true,
    });

    const token = generateToken({ id: admin._id, role: admin.role });
    res.status(201).json({
      success: true,
      data: { token, user: { id: admin._id, name: admin.name, email: admin.email, role: admin.role } },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getPlatformStats,
  getAllRestaurants,
  getRestaurantById,
  updateRestaurant,
  deleteRestaurant,
  getAllUsers,
  updateUser,
  deleteUser,
  getAllOrders,
  createSuperAdmin,
};
