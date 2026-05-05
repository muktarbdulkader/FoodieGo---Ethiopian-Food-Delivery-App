/**
 * Order Controller - With Payment, Delivery & Location
 * Enhanced with Yango-like features: GPS tracking, chat, ratings, earnings
 * Real-time WebSocket events for order updates
 */
const Order = require("../models/Order");
const User = require("../models/User");
const socketManager = require("../socket/socket.manager");
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
      // Restaurant sees orders containing their hotel's items OR dine-in orders for their restaurant
      const hotelIdStr = req.user._id.toString();
      const hotelName = req.user.hotelName;

      const orConditions = [
        { "items.hotelId": hotelIdStr },
        { "items.hotelId": req.user._id },
        { "restaurantId": req.user._id }, // Dine-in orders for this restaurant
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
      .populate("tableId", "tableNumber") // Populate table number for dine-in orders
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
    // Optional authentication - allow guest orders for dine-in
    const token = req.headers.authorization?.split(' ')[1];
    let user = null;
    
    if (token) {
      try {
        const jwt = require('jsonwebtoken');
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        user = await User.findById(decoded.id);
      } catch (err) {
        // Invalid token, but allow guest order for dine-in
        console.log('Invalid token, proceeding as guest');
      }
    }
    
    // Attach user to request if found
    if (user) {
      req.user = user;
    }
    
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
      type = 'delivery', // NEW: order type
      tableId, // NEW: for dine-in orders
      restaurantId, // NEW: for dine-in orders
    } = req.body;

    if (!items || items.length === 0) {
      return res
        .status(400)
        .json({ success: false, message: "Order must have items" });
    }

    // Validate dine-in specific fields
    if (type === 'dine_in') {
      if (!tableId || !restaurantId) {
        return res.status(400).json({ 
          success: false, 
          message: "Table ID and Restaurant ID are required for dine-in orders" 
        });
      }
      
      // Verify table exists and is active, and get table number
      const Table = require('../models/Table');
      const table = await Table.findOne({ 
        _id: tableId, 
        restaurantId,
        isActive: true 
      });
      
      if (!table) {
        return res.status(404).json({ 
          success: false, 
          message: "Table not found or inactive" 
        });
      }
      
      // Store table number for easy display
      req.tableNumber = table.tableNumber;
    }

    const calculatedSubtotal =
      subtotal ||
      items.reduce((sum, item) => sum + item.price * item.quantity, 0);
    
    // For dine-in orders, no delivery fee
    const finalDeliveryFee = type === 'dine_in' ? 0 : deliveryFee;
    
    const calculatedTotal =
      totalPrice || calculatedSubtotal + finalDeliveryFee + tax + tip - discount;

    // For dine-in orders, user can be guest (no login required)
    const userId = type === 'dine_in' && !req.user ? null : req.user._id;

    const orderData = {
      user: userId,
      restaurant,
      items,
      type, // NEW
      subtotal: calculatedSubtotal,
      deliveryFee: finalDeliveryFee,
      tax,
      tip,
      discount,
      totalPrice: calculatedTotal,
      payment: payment || { method: 'cash', status: 'pending' },
      notes,
      promoCode,
    };

    // Add delivery-specific fields only for delivery orders
    if (type !== 'dine_in') {
      orderData.deliveryAddress = deliveryAddress || {};
      orderData.delivery = delivery || { type: 'delivery', fee: finalDeliveryFee };
    }

    // Add dine-in specific fields
    if (type === 'dine_in') {
      orderData.tableId = tableId;
      orderData.tableNumber = req.tableNumber; // Add table number for display
      orderData.restaurantId = restaurantId;
    }

    const order = await Order.create(orderData);

    // If dine-in, add order to table session
    if (type === 'dine_in' && tableId) {
      const Table = require('../models/Table');
      const updateData = {
        $push: { 'currentSession.orderIds': order._id },
        $set: { 
          'currentSession.isOccupied': true,
          'currentSession.startTime': new Date()
        }
      };
      
      // Only set customerId if user is logged in
      if (userId) {
        updateData.$set['currentSession.customerId'] = userId;
      }
      
      await Table.findByIdAndUpdate(tableId, updateData);
    }

    // Send order confirmation email (using hotel's email as sender)
    if (req.user && type !== 'dine_in') { // Skip email for dine-in or if no user
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
    }

    // Emit WebSocket event for dine-in orders
    if (type === 'dine_in' && tableId && restaurantId) {
      try {
        // Emit to kitchen room
        socketManager.broadcastToKitchen(restaurantId, 'order:created', {
          eventType: 'order:created',
          orderId: order._id.toString(),
          orderNumber: order.orderNumber,
          tableId: tableId,
          tableNumber: order.tableNumber,
          restaurantId: restaurantId,
          items: order.items,
          totalPrice: order.totalPrice,
          status: order.status,
          notes: order.notes,
          timestamp: new Date().toISOString()
        });

        // Emit to table room
        socketManager.broadcastToTable(tableId, 'order:created', {
          eventType: 'order:created',
          orderId: order._id.toString(),
          orderNumber: order.orderNumber,
          tableNumber: order.tableNumber,
          status: order.status,
          timestamp: new Date().toISOString()
        });

        console.log(`[ORDER] WebSocket events emitted for order ${order.orderNumber}`);
      } catch (socketError) {
        console.error('[ORDER] Failed to emit WebSocket events:', socketError);
        // Don't fail the request if socket emission fails
      }
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

    // Add customer notification for dine-in orders
    if (order.type === 'dine_in') {
      let notificationMessage = '';
      let notificationType = 'info';
      
      if (status === 'confirmed') {
        notificationMessage = `Your order has been accepted! Table ${order.tableNumber || 'N/A'}. Your food will be ready soon.`;
        notificationType = 'success';
      } else if (status === 'cancelled') {
        notificationMessage = `Sorry, your order has been rejected. Please contact the waiter at Table ${order.tableNumber || 'N/A'} for assistance.`;
        notificationType = 'error';
      } else if (status === 'preparing') {
        notificationMessage = `Your order is being prepared. Table ${order.tableNumber || 'N/A'}.`;
        notificationType = 'info';
      } else if (status === 'ready') {
        notificationMessage = `Your order is ready! Table ${order.tableNumber || 'N/A'}. A waiter will bring it to you shortly.`;
        notificationType = 'success';
      } else if (status === 'completed') {
        notificationMessage = `Thank you for dining with us! Table ${order.tableNumber || 'N/A'}. Enjoy your meal!`;
        notificationType = 'success';
      }
      
      if (notificationMessage) {
        order.customerNotification = {
          message: notificationMessage,
          type: notificationType,
          timestamp: new Date(),
          isRead: false
        };
        await order.save();
      }
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

    // Emit WebSocket events for dine-in orders
    if (order.type === 'dine_in' && order.tableId && order.restaurantId) {
      try {
        const eventPayload = {
          eventType: 'order:updated',
          orderId: order._id.toString(),
          orderNumber: order.orderNumber,
          tableId: order.tableId.toString(),
          tableNumber: order.tableNumber,
          restaurantId: order.restaurantId.toString(),
          status: order.status,
          timestamp: new Date().toISOString()
        };

        // Add notification if present
        if (order.customerNotification) {
          eventPayload.notification = {
            message: order.customerNotification.message,
            type: order.customerNotification.type,
            timestamp: order.customerNotification.timestamp.toISOString()
          };
        }

        // Emit to kitchen room
        socketManager.broadcastToKitchen(order.restaurantId.toString(), 'order:updated', eventPayload);

        // Emit to table room
        socketManager.broadcastToTable(order.tableId.toString(), 'order:updated', eventPayload);

        // Emit to restaurant admin room
        socketManager.broadcastToRestaurantAdmin(order.restaurantId.toString(), 'order:updated', eventPayload);

        console.log(`[ORDER] WebSocket events emitted for order ${order.orderNumber} status update to ${status}`);
      } catch (socketError) {
        console.error('[ORDER] Failed to emit WebSocket events:', socketError);
        // Don't fail the request if socket emission fails
      }
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

// Assign driver to order (restaurant only) - with notification
const assignDriverToOrder = async (req, res, next) => {
  try {
    const { driverId, driverName, driverPhone } = req.body;
    const orderId = req.params.id;

    if (!driverId && !driverName) {
      return res.status(400).json({
        success: false,
        message: "Driver ID or driver name is required",
      });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found",
      });
    }

    // Verify restaurant owns this order
    const hotelIdStr = req.user._id.toString();
    const hotelName = req.user.hotelName;
    const orderHotelId = order.items[0]?.hotelId?.toString();
    const orderHotelName = order.items[0]?.hotelName;

    const isOwner =
      orderHotelId === hotelIdStr ||
      orderHotelName === hotelName ||
      (hotelName &&
        orderHotelName &&
        orderHotelName.toLowerCase().includes(hotelName.toLowerCase()));

    if (!isOwner) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to assign driver to this order",
      });
    }

    // Get restaurant location for pickup
    let pickupLocation = null;
    if (req.user.location) {
      pickupLocation = {
        latitude: req.user.location.latitude,
        longitude: req.user.location.longitude,
        address: req.user.hotelAddress || req.user.location.address,
      };
    }

    // Update order with driver info
    order.delivery = order.delivery || {};
    order.delivery.driverId = driverId;
    order.delivery.driverName = driverName;
    order.delivery.driverPhone = driverPhone || "";
    order.delivery.trackingStatus = "assigned";
    order.delivery.assignedAt = new Date();
    if (pickupLocation) {
      order.delivery.pickupLocation = pickupLocation;
    }
    await order.save();

    // Send notification to driver (this will be picked up by the driver's app)
    // In a real app, this would use Firebase Cloud Messaging or similar
    // For now, we'll create a notification record that the driver app can poll
    const notificationData = {
      type: "driver_assignment",
      orderId: order._id,
      orderNumber: order.orderNumber,
      restaurantName: hotelName || "Restaurant",
      customerName: order.userName || "Customer",
      deliveryAddress: order.deliveryAddress?.fullAddress || "Address",
      totalPrice: order.totalPrice,
      timestamp: new Date(),
    };

    // Send email notification to driver if email exists
    if (driverId) {
      const driver = await User.findById(driverId);
      if (driver && driver.email) {
        sendDriverAssignmentEmail(
          driver.email,
          {
            driverName: driver.name,
            orderNumber: order.orderNumber,
            restaurantName: hotelName || "Restaurant",
            customerName: order.userName || "Customer",
            deliveryAddress: order.deliveryAddress?.fullAddress || "Address",
            totalPrice: order.totalPrice,
          }
        ).catch((err) => console.error("Driver notification email failed:", err));
      }
    }

    res.json({
      success: true,
      data: order,
      notification: notificationData,
      message: "Driver assigned successfully",
    });
  } catch (error) {
    next(error);
  }
};

// Get dine-in orders grouped by table (restaurant only)
const getDineInOrders = async (req, res, next) => {
  try {
    const { restaurantId, status } = req.query;
    
    // Build filter
    const filter = { type: 'dine_in' };
    
    // If restaurant user, only show their orders
    if (req.user.role === 'restaurant') {
      filter.restaurantId = req.user._id;
    } else if (restaurantId) {
      filter.restaurantId = restaurantId;
    }
    
    // Filter by status if provided
    if (status) {
      filter.status = status;
    }

    const orders = await Order.find(filter)
      .populate('user', 'name email phone')
      .populate('tableId', 'tableNumber location capacity')
      .populate('restaurantId', 'hotelName hotelAddress')
      .sort({ createdAt: -1 });

    // Group orders by table
    const ordersByTable = {};
    orders.forEach(order => {
      const tableId = order.tableId?._id?.toString() || 'no-table';
      if (!ordersByTable[tableId]) {
        ordersByTable[tableId] = {
          table: order.tableId || null,
          orders: [],
          totalAmount: 0,
          itemCount: 0
        };
      }
      ordersByTable[tableId].orders.push(order);
      ordersByTable[tableId].totalAmount += order.totalPrice;
      ordersByTable[tableId].itemCount += order.items.reduce((sum, item) => sum + item.quantity, 0);
    });

    res.json({ 
      success: true, 
      count: orders.length,
      data: orders,
      groupedByTable: Object.values(ordersByTable)
    });
  } catch (error) {
    next(error);
  }
};

// In-memory storage for waiter calls (could be moved to database later)
const waiterCalls = new Map();

// Call waiter (dine-in feature)
const callWaiter = async (req, res, next) => {
  try {
    const { tableId, message } = req.body;

    if (!tableId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Table ID is required' 
      });
    }

    const Table = require('../models/Table');
    const table = await Table.findById(tableId).populate('restaurantId', 'hotelName');

    if (!table) {
      return res.status(404).json({ 
        success: false, 
        message: 'Table not found' 
      });
    }

    const restaurantId = table.restaurantId._id.toString();
    
    // Store waiter call
    const callId = `${tableId}_${Date.now()}`;
    const waiterCall = {
      _id: callId,
      id: callId,
      tableId: tableId,
      tableNumber: table.tableNumber,
      restaurantId: restaurantId,
      message: message || 'Customer needs assistance',
      createdAt: new Date().toISOString(),
      status: 'pending'
    };
    
    // Store in memory (grouped by restaurant)
    if (!waiterCalls.has(restaurantId)) {
      waiterCalls.set(restaurantId, []);
    }
    waiterCalls.get(restaurantId).push(waiterCall);

    // Emit WebSocket event to notify restaurant staff
    try {
      socketManager.broadcastToKitchen(restaurantId, 'waiter:called', {
        eventType: 'waiter:called',
        ...waiterCall
      });

      console.log(`[ORDER] Waiter called for table ${table.tableNumber}`);
    } catch (socketError) {
      console.error('[ORDER] Failed to emit waiter call event:', socketError);
      // Don't fail the request if socket emission fails
    }

    res.json({ 
      success: true, 
      message: 'Waiter has been notified',
      data: {
        tableNumber: table.tableNumber,
        restaurantName: table.restaurantId?.hotelName,
        requestMessage: message || 'Customer needs assistance'
      }
    });
  } catch (error) {
    next(error);
  }
};

// Get pending waiter calls (for kitchen display)
const getPendingWaiterCalls = async (req, res, next) => {
  try {
    const restaurantId = req.user._id.toString();
    
    // Get calls for this restaurant
    const calls = waiterCalls.get(restaurantId) || [];
    
    // Filter only pending calls
    const pendingCalls = calls.filter(call => call.status === 'pending');
    
    res.json({ 
      success: true, 
      count: pendingCalls.length,
      data: pendingCalls 
    });
  } catch (error) {
    next(error);
  }
};

// Acknowledge waiter call (mark as attended)
const acknowledgeWaiterCall = async (req, res, next) => {
  try {
    const { callId } = req.params;
    const restaurantId = req.user._id.toString();
    
    const calls = waiterCalls.get(restaurantId) || [];
    const callIndex = calls.findIndex(call => call._id === callId || call.id === callId);
    
    if (callIndex === -1) {
      return res.status(404).json({ 
        success: false, 
        message: 'Waiter call not found' 
      });
    }
    
    // Remove the call from pending list
    calls.splice(callIndex, 1);
    
    res.json({ 
      success: true, 
      message: 'Waiter call acknowledged' 
    });
  } catch (error) {
    next(error);
  }
};

// Get order status by table (for customer to check their order)
const getOrderStatusByTable = async (req, res, next) => {
  try {
    const { tableId } = req.params;

    if (!tableId) {
      return res.status(400).json({ 
        success: false, 
        message: 'Table ID is required' 
      });
    }

    // Find the most recent order for this table
    const order = await Order.findOne({ 
      tableId,
      type: 'dine_in',
      status: { $nin: ['completed', 'cancelled'] } // Exclude completed/cancelled orders
    })
    .sort({ createdAt: -1 })
    .populate('tableId', 'tableNumber');

    if (!order) {
      return res.json({ 
        success: true, 
        data: null,
        message: 'No active order found for this table'
      });
    }

    res.json({ 
      success: true, 
      data: {
        orderId: order._id,
        orderNumber: order.orderNumber,
        status: order.status,
        tableNumber: order.tableNumber,
        items: order.items,
        totalPrice: order.totalPrice,
        createdAt: order.createdAt,
        notification: order.customerNotification
      }
    });
  } catch (error) {
    next(error);
  }
};

// Mark notification as read
const markNotificationRead = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    const order = await Order.findByIdAndUpdate(
      orderId,
      { 'customerNotification.isRead': true },
      { new: true }
    );

    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found' 
      });
    }

    res.json({ 
      success: true, 
      message: 'Notification marked as read'
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
  getDineInOrders,
  callWaiter,
  getPendingWaiterCalls,
  acknowledgeWaiterCall,
  getOrderStatusByTable, // NEW
  markNotificationRead, // NEW
  assignDriverToOrder,
};
