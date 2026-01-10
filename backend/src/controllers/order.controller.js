/**
 * Order Controller - With Payment, Delivery & Location
 */
const Order = require('../models/Order');
const User = require('../models/User');
const { sendOrderConfirmationEmail, sendOrderStatusEmail, sendDriverAssignmentEmail } = require('../utils/email');

// Get all orders (filtered by role)
const getAllOrders = async (req, res, next) => {
  try {
    let filter = {};
    const userRole = req.user.role;
    
    if (userRole === 'restaurant') {
      // Restaurant sees orders containing their hotel's items
      const hotelIdStr = req.user._id.toString();
      const hotelName = req.user.hotelName;
      
      const orConditions = [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': req.user._id }
      ];
      
      if (hotelName) {
        orConditions.push({ 'items.hotelName': hotelName });
        orConditions.push({ 'items.hotelName': { $regex: new RegExp(`^${hotelName}`, 'i') } });
      }
      
      filter = { $or: orConditions };
    } else if (userRole === 'delivery') {
      // Delivery person sees orders assigned to them
      filter = { 
        'delivery.driverName': req.user.name,
        'delivery.type': 'delivery'
      };
    } else {
      // Regular user sees only their own orders
      filter = { user: req.user._id };
    }
    
    const orders = await Order.find(filter)
      .populate('user', 'name email phone address')
      .populate('restaurant', 'name')
      .sort({ createdAt: -1 });
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
      { 'items.hotelId': hotelIdStr },
      { 'items.hotelId': req.user._id }
    ];
    
    if (hotelName) {
      orConditions.push({ 'items.hotelName': hotelName });
      orConditions.push({ 'items.hotelName': { $regex: new RegExp(`^${hotelName}`, 'i') } });
    }
    
    const orders = await Order.find({
      $or: orConditions,
      'delivery.type': 'delivery',
      'delivery.driverName': { $in: [null, ''] },
      status: { $in: ['confirmed', 'preparing', 'ready'] }
    })
    .populate('user', 'name email phone address')
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
      'delivery.type': 'delivery',
      'delivery.driverName': { $in: [null, ''] },
      status: { $in: ['ready', 'confirmed', 'preparing'] }
    })
    .populate('user', 'name email phone address')
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
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    
    if (order.delivery.driverName) {
      return res.status(400).json({ success: false, message: 'Order already assigned to a driver' });
    }
    
    order.delivery.driverName = req.user.name;
    order.delivery.driverPhone = req.user.phone || '';
    order.delivery.trackingStatus = 'assigned';
    await order.save();
    
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Get single order
const getOrderById = async (req, res, next) => {
  try {
    const filter = req.user.role === 'restaurant' 
      ? { _id: req.params.id }
      : { _id: req.params.id, user: req.user._id };
    
    const order = await Order.findOne(filter)
      .populate('user', 'name email')
      .populate('restaurant', 'name address');
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
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
      restaurant
    } = req.body;
    
    if (!items || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Order must have items' });
    }

    const calculatedSubtotal = subtotal || items.reduce((sum, item) => sum + (item.price * item.quantity), 0);
    const calculatedTotal = totalPrice || (calculatedSubtotal + deliveryFee + tax + tip - discount);

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
      payment: payment || { method: 'cash', status: 'pending' },
      delivery: delivery || { type: 'delivery', fee: deliveryFee },
      notes,
      promoCode
    });

    // Send order confirmation email (using hotel's email as sender)
    const user = await User.findById(req.user._id);
    if (user && user.email) {
      const hotelName = items[0]?.hotelName || 'FoodieGo Partner';
      const hotelId = items[0]?.hotelId;
      
      // Get hotel's email to use as sender
      let hotelEmail = null;
      if (hotelId) {
        const hotel = await User.findById(hotelId);
        if (hotel && hotel.email) {
          hotelEmail = hotel.email;
        }
      }
      
      sendOrderConfirmationEmail(user.email, {
        orderNumber: order.orderNumber,
        userName: user.name,
        hotelName,
        items: order.items,
        totalPrice: order.totalPrice,
        address: deliveryAddress?.fullAddress || 'Pickup'
      }, hotelEmail).catch(err => console.error('Email send failed:', err));
    }

    res.status(201).json({ success: true, data: order });
  } catch (error) {
    console.error('Order creation error:', error);
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
    ).populate('user', 'name email phone');
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
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
      
      sendOrderStatusEmail(order.user.email, {
        orderNumber: order.orderNumber,
        hotelName: order.items[0]?.hotelName,
        driverName: order.delivery?.driverName,
        driverPhone: order.delivery?.driverPhone
      }, status, hotelEmail).catch(err => console.error('Status email failed:', err));
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
    const updateData = { 'payment.status': status };
    if (transactionId) updateData['payment.transactionId'] = transactionId;
    if (status === 'paid') updateData['payment.paidAt'] = new Date();

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    );
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }
    res.json({ success: true, data: order });
  } catch (error) {
    next(error);
  }
};

// Update delivery tracking
const updateDeliveryStatus = async (req, res, next) => {
  try {
    const { trackingStatus, driverName, driverPhone } = req.body;
    const updateData = {};
    if (trackingStatus) updateData['delivery.trackingStatus'] = trackingStatus;
    if (driverName) updateData['delivery.driverName'] = driverName;
    if (driverPhone) updateData['delivery.driverPhone'] = driverPhone;
    if (trackingStatus === 'delivered') {
      updateData['delivery.deliveredAt'] = new Date();
      updateData.status = 'delivered';
    }

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      updateData,
      { new: true }
    ).populate('user', 'name email');
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
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
      status: { $in: ['pending', 'confirmed'] }
    });

    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found or cannot be cancelled' 
      });
    }

    order.status = 'cancelled';
    order.cancelReason = reason || 'Cancelled by user';
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
    
    if (userRole === 'restaurant') {
      // Restaurant can delete orders for their hotel
      const hotelIdStr = req.user._id.toString();
      const hotelName = req.user.hotelName;
      
      const orConditions = [
        { 'items.hotelId': hotelIdStr },
        { 'items.hotelId': req.user._id }
      ];
      
      if (hotelName) {
        orConditions.push({ 'items.hotelName': hotelName });
      }
      
      order = await Order.findOneAndDelete({
        _id: req.params.id,
        $or: orConditions
      });
    } else {
      // User can only delete their own delivered or cancelled orders
      order = await Order.findOneAndDelete({
        _id: req.params.id,
        user: req.user._id,
        status: { $in: ['delivered', 'cancelled'] }
      });
    }
    
    if (!order) {
      return res.status(404).json({ 
        success: false, 
        message: 'Order not found or cannot be deleted' 
      });
    }
    res.json({ success: true, message: 'Order deleted' });
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
  acceptDeliveryOrder
};
