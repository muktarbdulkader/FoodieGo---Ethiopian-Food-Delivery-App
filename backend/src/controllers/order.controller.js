/**
 * Order Controller - With Payment, Delivery & Location
 */
const Order = require('../models/Order');

// Get all orders (filtered by role)
const getAllOrders = async (req, res, next) => {
  try {
    let filter = {};
    const userRole = req.user.role;
    
    if (userRole === 'restaurant') {
      // Restaurant sees only orders containing their hotel's items
      const hotelId = req.user._id.toString();
      filter = { 'items.hotelId': hotelId };
    } else if (userRole === 'delivery') {
      // Delivery person sees orders assigned to them (ready for delivery)
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
    const hotelId = req.user._id.toString();
    
    // Get orders for this restaurant that need delivery assignment
    const orders = await Order.find({
      'items.hotelId': hotelId,
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
    // Get orders ready for delivery that haven't been assigned
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
    const filter = req.user.role === 'admin' 
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

    // Calculate totals if not provided
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

    res.status(201).json({ success: true, data: order });
  } catch (error) {
    console.error('Order creation error:', error);
    next(error);
  }
};

// Update order status (admin only)
const updateOrderStatus = async (req, res, next) => {
  try {
    const { status } = req.body;
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    ).populate('user', 'name email');
    
    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
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

// Delete order (admin can delete any, user can delete own delivered/cancelled)
const deleteOrder = async (req, res, next) => {
  try {
    let order;
    if (req.user.role === 'admin') {
      // Admin can delete any order
      order = await Order.findByIdAndDelete(req.params.id);
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
