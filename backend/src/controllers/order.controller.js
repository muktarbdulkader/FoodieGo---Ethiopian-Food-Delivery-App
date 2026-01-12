/**
 * Order Controller - With Payment, Delivery & Location
 * Enhanced with Yango-like features: GPS tracking, chat, ratings, earnings
 */
const Order = require("../models/Order");
const User = require("../models/User");
const {
  sendOrderConfirmationEmail,
  sendOrderStatusEmail,
  sendDriverAssignmentEmail,
} = require("../utils/email");

// Helper: Calculate delivery earnings (base + distance bonus)
const calculateDeliveryEarnings = (order) => {
  const baseFee = 30; // Base delivery fee in ETB
  const distanceBonus = (order.delivery?.distance || 0) * 5; // 5 ETB per km
  return baseFee + distanceBonus;
};

// Get all orders (filtered by role)
const getAllOrders = async (req, res, next) => {
  try {
    let filter = {};
    const userRole = req.user.role;

    if (userRole === "restaurant") {
      // Restaurant sees orders containing their hotel's items
      const hotelIdStr = req.user._id.toString();
      const hotelName = req.user.hotelName;

      const orConditions = [
        { "items.hotelId": hotelIdStr },
        { "items.hotelId": req.user._id },
      ];

      if (hotelName) {
        orConditions.push({ "items.hotelName": hotelName });
        orConditions.push({
          "items.hotelName": { $regex: new RegExp(`^${hotelName}`, "i") },
        });
      }

      filter = { $or: orConditions };
    } else if (userRole === "delivery") {
      // Delivery person sees orders assigned to them (by driverId or driverName)
      // Don't require delivery.type since it might not be set on all orders
      filter = {
        $or: [
          { "delivery.driverId": req.user._id },
          { "delivery.driverName": req.user.name }
        ]
      };
      console.log(`Delivery filter for ${req.user.name} (${req.user._id}):`, JSON.stringify(filter));
    } else {
      // Regular user sees only their own orders
      filter = { user: req.user._id };
    }

    const orders = await Order.find(filter)
      .populate("user", "name email phone address")
      .populate("restaurant", "name")
      .sort({ createdAt: -1 });
    
    console.log(`Found ${orders.length} orders for ${userRole} user ${req.user.name}`);
    
    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

// Get pending delivery orders (for restaurant to assign drivers)
const getPendingDeliveryOrders = async (req, res, next) => {
  try {
    const hotelIdStr = req.user._id.toString();
    const hotelName = req.user.hotelName;

    const orConditions = [
      { "items.hotelId": hotelIdStr },
      { "items.hotelId": req.user._id },
    ];

    if (hotelName) {
      orConditions.push({ "items.hotelName": hotelName });
      orConditions.push({
        "items.hotelName": { $regex: new RegExp(`^${hotelName}`, "i") },
      });
    }

    const orders = await Order.find({
      $or: orConditions,
      "delivery.type": "delivery",
      "delivery.driverName": { $in: [null, ""] },
      status: { $in: ["confirmed", "preparing", "ready"] },
    })
      .populate("user", "name email phone address")
      .sort({ createdAt: -1 });

    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

// Get available delivery orders (for delivery persons to pick up)
const getAvailableDeliveryOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({
      "delivery.type": "delivery",
      "delivery.driverName": { $in: [null, ""] },
      status: { $in: ["ready", "confirmed", "preparing"] },
    })
      .populate("user", "name email phone address")
      .sort({ createdAt: -1 });

    res.json({ success: true, count: orders.length, data: orders });
  } catch (error) {
    next(error);
  }
};

// Delivery person accepts/claims an order
const acceptDeliveryOrder = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id);

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    if (order.delivery.driverName) {
      return res.status(400).json({
        success: false,
        message: "Order already assigned to a driver",
      });
    }

    // Get restaurant location for pickup
    const hotelId = order.items[0]?.hotelId;
    let pickupLocation = null;
    if (hotelId) {
      const hotel = await User.findById(hotelId);
      if (hotel && hotel.location) {
        pickupLocation = {
          latitude: hotel.location.latitude,
          longitude: hotel.location.longitude,
          address: hotel.hotelAddress || hotel.location.address,
        };
      }
    }

    order.delivery.driverId = req.user._id;
    order.delivery.driverName = req.user.name;
    order.delivery.driverPhone = req.user.phone || "";
    order.delivery.trackingStatus = "assigned";
    order.delivery.assignedAt = new Date();
    if (pickupLocation) {
      order.delivery.pickupLocation = pickupLocation;
    }
    await order.save();

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get single order
const getOrderById = async (req, res, next) => {
  try {
    const filter =
      req.user.role === "restaurant"
        ? { _id: req.params.id }
        : { _id: req.params.id, user: req.user._id };

    const order = await Order.findOne(filter)
      .populate("user", "name email")
      .populate("restaurant", "name address");
    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Create order with payment & delivery
const createOrder = async (req, res, next) => {
  try {
    const {
      items,
      subtotal,
      deliveryFee = 2.99,
      tax = 0,
      tip = 0,
      discount = 0,
      totalPrice,
      deliveryAddress,
      payment,
      delivery,
      notes,
      promoCode,
      restaurant,
    } = req.body;

    if (!items || items.length === 0) {
      return res
        .status(400)
        .json({ success: false, message: "Order must have items" });
    }

    const calculatedSubtotal =
      subtotal ||
      items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    const calculatedTotal =
      totalPrice || calculatedSubtotal + deliveryFee + tax + tip - discount;

    const order = await Order.create({
      user: req.user._id,
      restaurant,
      items,
      subtotal: calculatedSubtotal,
      deliveryFee,
      tax,
      tip,
      discount,
      totalPrice: calculatedTotal,
      deliveryAddress: deliveryAddress || {},
      payment: payment || { method: "cash", status: "pending" },
      delivery: delivery || { type: "delivery", fee: deliveryFee },
      notes,
      promoCode,
    });

    // Send order confirmation email (using hotel's email as sender)
    const user = await User.findById(req.user._id);
    if (user && user.email) {
      const hotelName = items[0]?.hotelName || "FoodieGo Partner";
      const hotelId = items[0]?.hotelId;

      // Get hotel's email to use as sender
      let hotelEmail = null;
      if (hotelId) {
        const hotel = await User.findById(hotelId);
        if (hotel && hotel.email) {
          hotelEmail = hotel.email;
        }
      }

      sendOrderConfirmationEmail(
        user.email,
        {
          orderNumber: order.orderNumber,
          userName: user.name,
          hotelName,
          items: order.items,
          totalPrice: order.totalPrice,
          address: deliveryAddress?.fullAddress || "Pickup",
        },
        hotelEmail
      ).catch((err) => console.error("Email send failed:", err));
    }

    res.status(201).json({ success: true, data: order });
  } catch (error) {
    console.error("Order creation error:", error);
    next(error);
  }
};

// Update order status (restaurant only)
const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    ).populate("user", "name email phone");

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    // Send status update email to customer (using hotel's email as sender)
    if (order.user && order.user.email) {
      // Get hotel email from order items
      let hotelEmail = null;
      const hotelId = order.items[0]?.hotelId;
      if (hotelId) {
        const hotel = await User.findById(hotelId);
        if (hotel && hotel.email) {
          hotelEmail = hotel.email;
        }
      }

      sendOrderStatusEmail(
        order.user.email,
        {
          orderNumber: order.orderNumber,
          hotelName: order.items[0]?.hotelName,
          driverName: order.delivery?.driverName,
          driverPhone: order.delivery?.driverPhone,
        },
        status,
        hotelEmail
      ).catch((err) => console.error("Status email failed:", err));
    }

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Update payment status
const updatePaymentStatus = async (req, res, next) => {
  try {
    const { status, transactionId } = req.body;
    const updateData = { "payment.status": status };
    if (transactionId) updateData["payment.transactionId"] = transactionId;
    if (status === "paid") updateData["payment.paidAt"] = new Date();

    const order = await Order.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
    });

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Update delivery tracking
const updateDeliveryStatus = async (req, res, next) => {
  try {
    const { trackingStatus, driverName, driverPhone, latitude, longitude } =
      req.body;
    const updateData = {};

    if (trackingStatus) updateData["delivery.trackingStatus"] = trackingStatus;
    if (driverName) updateData["delivery.driverName"] = driverName;
    if (driverPhone) updateData["delivery.driverPhone"] = driverPhone;

    // Update driver location if provided
    if (latitude && longitude) {
      updateData["delivery.driverLocation"] = {
        latitude,
        longitude,
        updatedAt: new Date(),
      };
    }

    // Track timestamps for each status
    if (trackingStatus === "picked_up") {
      updateData["delivery.pickedUpAt"] = new Date();
    }

    if (trackingStatus === "delivered") {
      updateData["delivery.deliveredAt"] = new Date();
      updateData.status = "delivered";

      // Update driver stats
      const order = await Order.findById(req.params.id);
      if (order && order.delivery?.driverId) {
        const earnings = calculateDeliveryEarnings(order);
        const today = new Date().toDateString();

        await User.findByIdAndUpdate(order.delivery.driverId, {
          $inc: {
            "deliveryStats.totalDeliveries": 1,
            "deliveryStats.totalEarnings": earnings,
            "deliveryStats.todayDeliveries": 1,
            "deliveryStats.todayEarnings": earnings,
            "deliveryStats.weeklyDeliveries": 1,
            "deliveryStats.weeklyEarnings": earnings,
            walletBalance: earnings,
          },
          $set: { "deliveryStats.lastDeliveryDate": new Date() },
          $push: {
            walletTransactions: {
              type: "credit",
              amount: earnings,
              description: `Delivery #${order.orderNumber}`,
              date: new Date().toISOString(),
            },
          },
        });
      }
    }

    const order = await Order.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
    }).populate("user", "name email");

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Cancel order
const cancelOrder = async (req, res, next) => {
  try {
    const { reason } = req.body;
    const order = await Order.findOne({
      _id: req.params.id,
      user: req.user._id,
      status: { $in: ["pending", "confirmed"] },
    });

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found or cannot be cancelled",
      });
    }

    order.status = "cancelled";
    order.cancelReason = reason || "Cancelled by user";
    await order.save();

    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Delete order (restaurant can delete their orders, user can delete own delivered/cancelled)
const deleteOrder = async (req, res, next) => {
  try {
    let order;
    const userRole = req.user.role;

    if (userRole === "restaurant") {
      // Restaurant can delete orders for their hotel
      const hotelIdStr = req.user._id.toString();
      const hotelName = req.user.hotelName;

      const orConditions = [
        { "items.hotelId": hotelIdStr },
        { "items.hotelId": req.user._id },
      ];

      if (hotelName) {
        orConditions.push({ "items.hotelName": hotelName });
      }

      order = await Order.findOneAndDelete({
        _id: req.params.id,
        $or: orConditions,
      });
    } else {
      // User can only delete their own delivered or cancelled orders
      order = await Order.findOneAndDelete({
        _id: req.params.id,
        user: req.user._id,
        status: { $in: ["delivered", "cancelled"] },
      });
    }

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found or cannot be deleted",
      });
    }
    res.json({ success: true, message: "Order deleted" });
  } catch (error) {
    next(error);
  }
};

// Update driver's current location (called by driver app)
const updateDriverLocation = async (req, res, next) => {
  try {
    const { latitude, longitude, orderId } = req.body;

    // Update driver's current location in User model
    await User.findByIdAndUpdate(req.user._id, {
      currentLocation: {
        latitude,
        longitude,
        updatedAt: new Date(),
      },
    });

    // If orderId provided, update order's driver location too
    if (orderId) {
      await Order.findByIdAndUpdate(orderId, {
        "delivery.driverLocation": {
          latitude,
          longitude,
          updatedAt: new Date(),
        },
      });
    }

    res.json({ success: true, message: "Location updated" });
  } catch (error) {
    next(error);
  }
};

// Get driver's current location for an order (called by customer)
const getDriverLocation = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.orderId);

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    // Only return location if order is being delivered
    if (
      !["assigned", "picked_up", "on_the_way", "arrived"].includes(
        order.delivery?.trackingStatus
      )
    ) {
      return res.json({
        success: true,
        data: null,
        message: "Driver not yet assigned or delivery completed",
      });
    }

    res.json({
      success: true,
      data: {
        driverLocation: order.delivery?.driverLocation,
        pickupLocation: order.delivery?.pickupLocation,
        deliveryLocation: {
          latitude: order.deliveryAddress?.latitude,
          longitude: order.deliveryAddress?.longitude,
          address: order.deliveryAddress?.fullAddress,
        },
        trackingStatus: order.delivery?.trackingStatus,
        estimatedTime: order.delivery?.estimatedTime,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Send chat message
const sendChatMessage = async (req, res, next) => {
  try {
    const { message } = req.body;
    const orderId = req.params.orderId;

    const order = await Order.findById(orderId);
    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    // Determine sender role
    const senderRole = req.user.role === "delivery" ? "driver" : "user";

    // Verify user is part of this order
    const isCustomer = order.user.toString() === req.user._id.toString();
    // Check driver by driverId OR driverName (in case driverId wasn't set)
    const isDriver =
      order.delivery?.driverId?.toString() === req.user._id.toString() ||
      order.delivery?.driverName === req.user.name;

    if (!isCustomer && !isDriver) {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized" });
    }

    const chatMessage = {
      senderId: req.user._id,
      senderRole,
      message,
      timestamp: new Date(),
      isRead: false,
    };

    order.chatMessages.push(chatMessage);
    await order.save();

    res.json({ success: true, data: chatMessage });
  } catch (error) {
    next(error);
  }
};

// Get chat messages for an order
const getChatMessages = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.orderId).select(
      "chatMessages user delivery"
    );

    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    // Verify user is part of this order
    const isCustomer = order.user.toString() === req.user._id.toString();
    // Check driver by driverId OR driverName (in case driverId wasn't set)
    const isDriver =
      order.delivery?.driverId?.toString() === req.user._id.toString() ||
      order.delivery?.driverName === req.user.name;

    if (!isCustomer && !isDriver) {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized" });
    }

    // Mark messages as read
    const otherRole = req.user.role === "delivery" ? "user" : "driver";
    order.chatMessages.forEach((msg) => {
      if (msg.senderRole === otherRole) {
        msg.isRead = true;
      }
    });
    await order.save();

    res.json({ success: true, data: order.chatMessages });
  } catch (error) {
    next(error);
  }
};

// Rate driver after delivery
const rateDriver = async (req, res, next) => {
  try {
    const { rating, review } = req.body;
    const orderId = req.params.orderId;

    const order = await Order.findById(orderId);
    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    // Only customer can rate
    if (order.user.toString() !== req.user._id.toString()) {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized" });
    }

    // Only rate delivered orders
    if (order.status !== "delivered") {
      return res
        .status(400)
        .json({ success: false, message: "Can only rate delivered orders" });
    }

    // Save rating to order
    order.delivery.driverRating = rating;
    order.delivery.driverReview = review || "";
    await order.save();

    // Update driver's average rating
    if (order.delivery?.driverId) {
      const driver = await User.findById(order.delivery.driverId);
      if (driver) {
        const currentTotal =
          (driver.deliveryStats?.averageRating || 5) *
          (driver.deliveryStats?.totalRatings || 0);
        const newTotalRatings = (driver.deliveryStats?.totalRatings || 0) + 1;
        const newAverage = (currentTotal + rating) / newTotalRatings;

        await User.findByIdAndUpdate(order.delivery.driverId, {
          "deliveryStats.averageRating": Math.round(newAverage * 10) / 10,
          "deliveryStats.totalRatings": newTotalRatings,
        });
      }
    }

    res.json({ success: true, message: "Rating submitted" });
  } catch (error) {
    next(error);
  }
};

// Get driver earnings (for driver dashboard)
const getDriverEarnings = async (req, res, next) => {
  try {
    const driver = await User.findById(req.user._id).select(
      "deliveryStats walletBalance walletTransactions"
    );

    if (!driver) {
      return res
        .status(404)
        .json({ success: false, message: "Driver not found" });
    }

    // Get recent transactions (last 20)
    const recentTransactions = (driver.walletTransactions || [])
      .slice(-20)
      .reverse();

    res.json({
      success: true,
      data: {
        stats: driver.deliveryStats || {},
        walletBalance: driver.walletBalance || 0,
        recentTransactions,
      },
    });
  } catch (error) {
    next(error);
  }
};

// Get driver stats summary
const getDriverStats = async (req, res, next) => {
  try {
    const driver = await User.findById(req.user._id).select(
      "deliveryStats name"
    );

    // Get today's completed deliveries
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const todayOrders = await Order.countDocuments({
      "delivery.driverId": req.user._id,
      "delivery.deliveredAt": { $gte: today },
      status: "delivered",
    });

    // Get this week's deliveries
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);

    const weekOrders = await Order.countDocuments({
      "delivery.driverId": req.user._id,
      "delivery.deliveredAt": { $gte: weekStart },
      status: "delivered",
    });

    res.json({
      success: true,
      data: {
        name: driver?.name,
        totalDeliveries: driver?.deliveryStats?.totalDeliveries || 0,
        totalEarnings: driver?.deliveryStats?.totalEarnings || 0,
        todayDeliveries: todayOrders,
        weeklyDeliveries: weekOrders,
        averageRating: driver?.deliveryStats?.averageRating || 5.0,
        totalRatings: driver?.deliveryStats?.totalRatings || 0,
      },
    });
  } catch (error) {
    next(error);
  }
};
module.exports = {
  getAllOrders,
  getOrderById,
  createOrder,
  updateOrderStatus,
  updatePaymentStatus,
  updateDeliveryStatus,
  cancelOrder,
  deleteOrder,
  getPendingDeliveryOrders,
  getAvailableDeliveryOrders,
  acceptDeliveryOrder,
  updateDriverLocation,
  getDriverLocation,
  sendChatMessage,
  getChatMessages,
  rateDriver,
  getDriverEarnings,
  getDriverStats,
};
