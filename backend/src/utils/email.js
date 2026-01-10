/**
 * Email Service - Handles all email notifications
 * Uses Nodemailer with Gmail SMTP
 * Can use hotel's email dynamically or fallback to system email
 */
const nodemailer = require('nodemailer');

// Create transporter with optional custom email credentials
const createTransporter = (customEmail = null, customPass = null) => {
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false,
    auth: {
      user: customEmail || process.env.EMAIL_USER,
      pass: customPass || process.env.EMAIL_PASS
    }
  });
};

// Create transporter using hotel's email (if available)
const createHotelTransporter = (hotelEmail) => {
  // For now, use system email but set "from" as hotel
  // In production, each hotel would have their own app password
  return nodemailer.createTransport({
    host: process.env.EMAIL_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.EMAIL_PORT) || 587,
    secure: false,
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Generate 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP email for password reset
const sendOTPEmail = async (email, otp, userName) => {
  const transporter = createTransporter();
  
  const mailOptions = {
    from: process.env.EMAIL_FROM || 'FoodieGo <noreply@foodiego.com>',
    to: email,
    subject: '🔐 Password Reset OTP - FoodieGo',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; margin: 0; padding: 20px; }
          .container { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #FF6B35, #FF8A5C); padding: 30px; text-align: center; }
          .header h1 { color: white; margin: 0; font-size: 24px; }
          .content { padding: 30px; }
          .otp-box { background: #f1f5f9; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }
          .otp-code { font-size: 36px; font-weight: bold; color: #FF6B35; letter-spacing: 8px; }
          .warning { background: #fef3c7; border-left: 4px solid #f59e0b; padding: 12px; margin: 20px 0; border-radius: 0 8px 8px 0; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #64748b; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🍔 FoodieGo</h1>
          </div>
          <div class="content">
            <h2>Password Reset Request</h2>
            <p>Hi ${userName || 'there'},</p>
            <p>We received a request to reset your password. Use the OTP below to proceed:</p>
            <div class="otp-box">
              <div class="otp-code">${otp}</div>
              <p style="color: #64748b; margin: 10px 0 0 0;">Valid for 10 minutes</p>
            </div>
            <div class="warning">
              ⚠️ If you didn't request this, please ignore this email or contact support.
            </div>
          </div>
          <div class="footer">
            <p>© 2024 FoodieGo. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

// Send order confirmation email (uses hotel email if provided)
const sendOrderConfirmationEmail = async (email, orderData, hotelEmail = null) => {
  const transporter = createHotelTransporter(hotelEmail);
  
  const itemsHtml = orderData.items.map(item => `
    <tr>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0;">${item.name}</td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: center;">${item.quantity}</td>
      <td style="padding: 10px; border-bottom: 1px solid #e2e8f0; text-align: right;">ETB ${item.total ? item.total.toFixed(2) : (item.price * item.quantity).toFixed(2)}</td>
    </tr>
  `).join('');

  // Use hotel email as sender if available
  const fromEmail = hotelEmail 
    ? `${orderData.hotelName || 'Restaurant'} <${hotelEmail}>`
    : process.env.EMAIL_FROM || 'FoodieGo <noreply@foodiego.com>';

  const mailOptions = {
    from: fromEmail,
    to: email,
    subject: `✅ Order Confirmed #${orderData.orderNumber} - FoodieGo`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; margin: 0; padding: 20px; }
          .container { max-width: 600px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #10B981, #34D399); padding: 30px; text-align: center; }
          .header h1 { color: white; margin: 0; }
          .content { padding: 30px; }
          .order-info { background: #f1f5f9; border-radius: 12px; padding: 20px; margin: 20px 0; }
          table { width: 100%; border-collapse: collapse; }
          th { background: #f1f5f9; padding: 12px; text-align: left; }
          .total-row { font-weight: bold; font-size: 18px; color: #FF6B35; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #64748b; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✅ Order Confirmed!</h1>
          </div>
          <div class="content">
            <h2>Thank you for your order, ${orderData.userName}!</h2>
            <div class="order-info">
              <p><strong>Order #:</strong> ${orderData.orderNumber}</p>
              <p><strong>Restaurant:</strong> ${orderData.hotelName || 'FoodieGo Partner'}</p>
              <p><strong>Delivery Address:</strong> ${orderData.address || 'Pickup'}</p>
            </div>
            <h3>Order Items</h3>
            <table>
              <thead>
                <tr>
                  <th>Item</th>
                  <th style="text-align: center;">Qty</th>
                  <th style="text-align: right;">Price</th>
                </tr>
              </thead>
              <tbody>
                ${itemsHtml}
                <tr class="total-row">
                  <td colspan="2" style="padding: 15px;">Total</td>
                  <td style="padding: 15px; text-align: right;">ETB ${orderData.totalPrice.toFixed(2)}</td>
                </tr>
              </tbody>
            </table>
            <p style="margin-top: 20px;">We'll notify you when your order is on the way! 🚴</p>
          </div>
          <div class="footer">
            <p>© 2024 FoodieGo. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

// Send order status update email (uses hotel email if provided)
const sendOrderStatusEmail = async (email, orderData, newStatus, hotelEmail = null) => {
  const transporter = createHotelTransporter(hotelEmail);
  
  const statusMessages = {
    confirmed: { emoji: '✅', title: 'Order Confirmed', message: 'Your order has been confirmed and is being prepared.' },
    preparing: { emoji: '👨‍🍳', title: 'Preparing Your Order', message: 'The restaurant is now preparing your delicious food!' },
    ready: { emoji: '📦', title: 'Order Ready', message: 'Your order is ready and waiting for pickup/delivery.' },
    out_for_delivery: { emoji: '🚴', title: 'Out for Delivery', message: 'Your order is on the way! Get ready to enjoy your meal.' },
    delivered: { emoji: '🎉', title: 'Order Delivered', message: 'Your order has been delivered. Enjoy your meal!' },
    cancelled: { emoji: '❌', title: 'Order Cancelled', message: 'Your order has been cancelled. Contact support for assistance.' }
  };

  const status = statusMessages[newStatus] || { emoji: '📋', title: 'Order Update', message: `Your order status is now: ${newStatus}` };

  // Use hotel email as sender if available
  const fromEmail = hotelEmail 
    ? `${orderData.hotelName || 'Restaurant'} <${hotelEmail}>`
    : process.env.EMAIL_FROM || 'FoodieGo <noreply@foodiego.com>';

  const mailOptions = {
    from: fromEmail,
    to: email,
    subject: `${status.emoji} ${status.title} - Order #${orderData.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; margin: 0; padding: 20px; }
          .container { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #FF6B35, #FF8A5C); padding: 30px; text-align: center; }
          .header h1 { color: white; margin: 0; font-size: 48px; }
          .content { padding: 30px; text-align: center; }
          .status-box { background: #f1f5f9; border-radius: 12px; padding: 20px; margin: 20px 0; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #64748b; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>${status.emoji}</h1>
          </div>
          <div class="content">
            <h2>${status.title}</h2>
            <div class="status-box">
              <p><strong>Order #:</strong> ${orderData.orderNumber}</p>
              <p>${status.message}</p>
            </div>
            ${newStatus === 'out_for_delivery' && orderData.driverName ? `
              <p><strong>Driver:</strong> ${orderData.driverName}</p>
              <p><strong>Contact:</strong> ${orderData.driverPhone || 'N/A'}</p>
            ` : ''}
          </div>
          <div class="footer">
            <p>© 2024 FoodieGo. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

// Send delivery assignment notification to driver (uses hotel email if provided)
const sendDriverAssignmentEmail = async (email, orderData, hotelEmail = null) => {
  const transporter = createHotelTransporter(hotelEmail);

  // Use hotel email as sender if available
  const fromEmail = hotelEmail 
    ? `${orderData.hotelName || 'Restaurant'} <${hotelEmail}>`
    : process.env.EMAIL_FROM || 'FoodieGo <noreply@foodiego.com>';

  const mailOptions = {
    from: fromEmail,
    to: email,
    subject: `🚴 New Delivery Assignment - Order #${orderData.orderNumber}`,
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { font-family: 'Segoe UI', Arial, sans-serif; background: #f8fafc; margin: 0; padding: 20px; }
          .container { max-width: 500px; margin: 0 auto; background: white; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
          .header { background: linear-gradient(135deg, #8B5CF6, #A78BFA); padding: 30px; text-align: center; }
          .header h1 { color: white; margin: 0; }
          .content { padding: 30px; }
          .info-box { background: #f1f5f9; border-radius: 12px; padding: 15px; margin: 10px 0; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; color: #64748b; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚴 New Delivery!</h1>
          </div>
          <div class="content">
            <h2>You have a new delivery assignment</h2>
            <div class="info-box">
              <p><strong>Order #:</strong> ${orderData.orderNumber}</p>
              <p><strong>Restaurant:</strong> ${orderData.hotelName}</p>
              <p><strong>Pickup:</strong> ${orderData.hotelAddress || 'Contact restaurant'}</p>
            </div>
            <div class="info-box">
              <p><strong>Customer:</strong> ${orderData.userName}</p>
              <p><strong>Phone:</strong> ${orderData.userPhone || 'N/A'}</p>
              <p><strong>Delivery Address:</strong> ${orderData.address}</p>
            </div>
            <p style="text-align: center; margin-top: 20px;">
              <strong>Total: ETB ${orderData.totalPrice.toFixed(2)}</strong>
            </p>
          </div>
          <div class="footer">
            <p>© 2024 FoodieGo. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Email send error:', error);
    return { success: false, error: error.message };
  }
};

module.exports = {
  generateOTP,
  sendOTPEmail,
  sendOrderConfirmationEmail,
  sendOrderStatusEmail,
  sendDriverAssignmentEmail
};