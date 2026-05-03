/**
 * Payment Controller
 * Handles payment operations including Telebirr integration
 */
const Order = require('../models/Order');
const telebirrService = require('../services/telebirr.service');

/**
 * Create Telebirr order and return rawRequest for in-app payment
 * This endpoint is used by the Telebirr in-app payment flow
 */
const createTelebirrOrder = async (req, res, next) => {
  try {
    const { title, amount, orderId } = req.body;

    console.log('[PAYMENT] Creating Telebirr order:', { title, amount, orderId });

    // If orderId provided, find existing order
    let order;
    if (orderId) {
      // Check if orderId is a valid MongoDB ObjectId
      const mongoose = require('mongoose');
      if (mongoose.Types.ObjectId.isValid(orderId)) {
        order = await Order.findById(orderId).populate('user', 'name phone');
        if (!order) {
          console.log('[PAYMENT] Order not found, creating direct payment');
        } else if (order.payment?.status === 'paid') {
          return res.status(400).json({
            success: false,
            message: 'Order already paid'
          });
        }
      } else {
        console.log('[PAYMENT] Invalid orderId format, creating direct payment');
      }
    }

    // Use provided amount or order total
    const paymentAmount = amount ? parseFloat(amount) : (order ? order.totalPrice : 0);
    const paymentTitle = title || (order ? `FoodieGo Order #${order._id.toString().substring(0, 8)}` : 'Payment');
    const actualOrderId = order ? order._id.toString() : `DIRECT_${Date.now()}`;

    // Create Telebirr payment and get rawRequest
    const paymentResult = await telebirrService.createPayment({
      orderId: actualOrderId,
      amount: paymentAmount,
      customerPhone: order?.user?.phone || '0900000000',
      customerName: order?.user?.name || 'Customer',
      description: paymentTitle
    });

    // Update order with payment info if order exists
    if (order) {
      order.payment = {
        method: 'telebirr',
        status: 'pending',
        transactionId: paymentResult.transactionId
      };
      await order.save();
    }

    console.log('[PAYMENT] Telebirr order created successfully');

    // Return rawRequest for in-app payment
    // The rawRequest is the signed request object that Telebirr app needs
    res.send(paymentResult.rawRequest);
  } catch (error) {
    console.error('[PAYMENT] Create order error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create order'
    });
  }
};

/**
 * Initiate Telebirr payment (Web/H5 flow)
 */
const initiateTelebirrPayment = async (req, res, next) => {
  try {
    const { orderId, phoneNumber, phone, amount, paymentMethod } = req.body;
    const customerPhone = phoneNumber || phone;

    console.log('[PAYMENT] Initiating payment:', { orderId, paymentMethod, phone: customerPhone });

    // Find order
    const order = await Order.findById(orderId).populate('user', 'name phone');
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // Check if already paid
    if (order.payment?.status === 'paid') {
      return res.status(400).json({
        success: false,
        message: 'Order already paid'
      });
    }

    // For Telebirr, create payment
    if (paymentMethod === 'telebirr') {
      const paymentResult = await telebirrService.createPayment({
        orderId: order._id.toString(),
        amount: amount || order.totalPrice,
        customerPhone: customerPhone || order.user?.phone || '0900000000',
        customerName: order.user?.name || 'Customer',
        description: `FoodieGo Order #${order.orderNumber || order._id.toString().substring(0, 8)}`
      });

      // Update order with payment info
      order.payment = {
        method: 'telebirr',
        status: 'pending',
        transactionId: paymentResult.transactionId
      };
      await order.save();

      console.log('[PAYMENT] Telebirr payment initiated:', {
        orderId: order._id,
        transactionId: paymentResult.transactionId
      });

      return res.json({
        success: true,
        data: {
          paymentUrl: paymentResult.paymentUrl,
          toPayUrl: paymentResult.paymentUrl,
          prepayId: paymentResult.prepayId,
          transactionId: paymentResult.transactionId,
          rawRequest: paymentResult.rawRequest
        },
        message: 'Telebirr payment initiated successfully'
      });
    }

    // For M-Pesa and CBE Birr (not yet implemented)
    if (paymentMethod === 'mpesa' || paymentMethod === 'cbe_birr') {
      // Update order with payment method
      order.payment = {
        method: paymentMethod,
        status: 'pending'
      };
      await order.save();

      console.log(`[PAYMENT] ${paymentMethod.toUpperCase()} payment initiated (mock mode)`);

      return res.json({
        success: true,
        data: {
          message: `${paymentMethod.toUpperCase()} payment will be processed`,
          orderId: order._id
        },
        message: `${paymentMethod.toUpperCase()} payment initiated`
      });
    }

    // Default response
    res.json({
      success: true,
      data: {
        orderId: order._id
      },
      message: 'Payment initiated'
    });
  } catch (error) {
    console.error('[PAYMENT] Payment initiation error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to initiate payment'
    });
  }
};

/**
 * Handle Telebirr webhook callback
 */
const telebirrWebhook = async (req, res, next) => {
  try {
    console.log('[PAYMENT] Telebirr webhook received:', req.body);

    // Verify payment
    const verification = await telebirrService.verifyPayment(req.body);

    if (verification.success) {
      // Find and update order
      const order = await Order.findById(verification.orderId);
      
      if (order) {
        order.payment = {
          method: 'telebirr',
          status: 'paid',
          transactionId: verification.transactionId,
          paidAt: verification.paidAt
        };
        order.status = 'confirmed';
        await order.save();

        console.log(`[PAYMENT] Order ${order._id} paid successfully via webhook`);
      } else {
        console.error(`[PAYMENT] Order ${verification.orderId} not found`);
      }
    }

    // Always return success to Telebirr
    res.json({ code: 0, msg: 'success' });
  } catch (error) {
    console.error('[PAYMENT] Webhook error:', error);
    res.json({ code: 1, msg: 'failed' });
  }
};

/**
 * Verify payment status
 */
const verifyPayment = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    console.log('[PAYMENT] Verifying payment for order:', orderId);

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found'
      });
    }

    // If already paid, return success
    if (order.payment?.status === 'paid') {
      return res.json({
        success: true,
        payment: order.payment,
        orderStatus: order.status,
        message: 'Payment already confirmed'
      });
    }

    // Query Telebirr for payment status if transaction ID exists
    if (order.payment?.transactionId) {
      try {
        const paymentStatus = await telebirrService.queryPayment(order.payment.transactionId);

        if (paymentStatus.success && 
            (paymentStatus.status === 'TRADE_SUCCESS' || paymentStatus.status === 'SUCCESS')) {
          order.payment.status = 'paid';
          order.payment.paidAt = new Date();
          order.status = 'confirmed';
          await order.save();

          console.log(`[PAYMENT] Order ${order._id} payment confirmed via query`);
        }
      } catch (queryError) {
        console.error('[PAYMENT] Query error:', queryError.message);
        // Continue even if query fails
      }
    }

    res.json({
      success: true,
      payment: order.payment,
      orderStatus: order.status
    });
  } catch (error) {
    console.error('[PAYMENT] Verification error:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to verify payment'
    });
  }
};

/**
 * Handle payment success redirect (from Telebirr)
 */
const paymentSuccess = async (req, res) => {
  try {
    const { orderId } = req.query;
    
    console.log('[PAYMENT] Payment success redirect for order:', orderId);

    // Redirect to frontend success page
    res.redirect(`${process.env.WEB_APP_URL || 'http://localhost:5173'}/payment/success?orderId=${orderId}`);
  } catch (error) {
    console.error('[PAYMENT] Success redirect error:', error);
    res.redirect(`${process.env.WEB_APP_URL || 'http://localhost:5173'}/payment/failed`);
  }
};

/**
 * Handle payment failure redirect (from Telebirr)
 */
const paymentFailed = async (req, res) => {
  try {
    const { orderId } = req.query;
    
    console.log('[PAYMENT] Payment failed redirect for order:', orderId);

    // Redirect to frontend failed page
    res.redirect(`${process.env.WEB_APP_URL || 'http://localhost:5173'}/payment/failed?orderId=${orderId}`);
  } catch (error) {
    console.error('[PAYMENT] Failed redirect error:', error);
    res.redirect(`${process.env.WEB_APP_URL || 'http://localhost:5173'}/payment/failed`);
  }
};

module.exports = {
  createTelebirrOrder,
  initiateTelebirrPayment,
  telebirrWebhook,
  verifyPayment,
  paymentSuccess,
  paymentFailed
};
