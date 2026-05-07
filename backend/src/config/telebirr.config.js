/**
 * Telebirr Configuration
 * Reads credentials from environment variables for security
 */
module.exports = {
  baseUrl: process.env.TELEBIRR_BASE_URL,
  fabricAppId: process.env.TELEBIRR_FABRIC_APP_ID,
  appSecret: process.env.TELEBIRR_APP_SECRET,
  merchantAppId: process.env.TELEBIRR_MERCHANT_APP_ID,
  merchantCode: process.env.TELEBIRR_MERCHANT_CODE,
  privateKey: process.env.TELEBIRR_PRIVATE_KEY,
  // Return URL after payment
  returnUrl: process.env.WEB_APP_URL || 'https://foodiego-tqz4.onrender.com',
  // Webhook URL for payment notifications
  notifyUrl: process.env.TELEBIRR_NOTIFY_URL || 'https://foodiego-tqz4.onrender.com/api/payments/telebirr/webhook',
};
