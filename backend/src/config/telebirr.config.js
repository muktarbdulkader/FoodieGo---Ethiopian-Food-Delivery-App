/**
 * Telebirr Configuration
 * Reads credentials from environment variables for security
 */

// Default Telebirr sandbox/production URLs
const DEFAULT_BASE_URL = 'https://developerportal.ethiotelebirr.et:38443/apiaccess/payment/gateway';

// Validate required credentials
const config = {
  baseUrl: process.env.TELEBIRR_BASE_URL || DEFAULT_BASE_URL,
  fabricAppId: process.env.TELEBIRR_FABRIC_APP_ID,
  appSecret: process.env.TELEBIRR_APP_SECRET,
  merchantAppId: process.env.TELEBIRR_MERCHANT_APP_ID,
  merchantCode: process.env.TELEBIRR_MERCHANT_CODE,
  privateKey: process.env.TELEBIRR_PRIVATE_KEY,
  // Return URL after payment
  returnUrl: process.env.WEB_APP_URL || 'https://foodiego-99b1e.web.app',
  // Webhook URL for payment notifications
  notifyUrl: process.env.TELEBIRR_NOTIFY_URL || 'https://foodiego-tqz4.onrender.com/api/payments/telebirr/webhook',
};

// Log config status (without exposing secrets)
console.log('[TELEBIRR CONFIG] ==========================================');
console.log('[TELEBIRR CONFIG] Base URL:', config.baseUrl);
console.log('[TELEBIRR CONFIG] Fabric App ID:', config.fabricAppId ? `✓ Set (${config.fabricAppId.substring(0, 8)}...)` : '✗ NOT SET!');
console.log('[TELEBIRR CONFIG] App Secret:', config.appSecret ? `✓ Set (${config.appSecret.length} chars)` : '✗ NOT SET!');
console.log('[TELEBIRR CONFIG] Merchant App ID:', config.merchantAppId ? `✓ Set (${config.merchantAppId.substring(0, 8)}...)` : '✗ NOT SET!');
console.log('[TELEBIRR CONFIG] Merchant Code:', config.merchantCode ? `✓ Set (${config.merchantCode})` : '✗ NOT SET!');
console.log('[TELEBIRR CONFIG] Private Key:', config.privateKey ? `✓ Set (${config.privateKey.length} chars)` : '✗ NOT SET!');
console.log('[TELEBIRR CONFIG] Return URL:', config.returnUrl);
console.log('[TELEBIRR CONFIG] Notify URL:', config.notifyUrl);
console.log('[TELEBIRR CONFIG] ==========================================');

// Validate required fields
const requiredFields = ['fabricAppId', 'appSecret', 'merchantAppId', 'merchantCode'];
const missingFields = requiredFields.filter(field => !config[field]);

if (missingFields.length > 0) {
  console.error('[TELEBIRR CONFIG] ❌ ERROR: Missing required environment variables:');
  missingFields.forEach(field => {
    console.error(`[TELEBIRR CONFIG]    - TELEBIRR_${field.toUpperCase().replace(/([A-Z])/g, '_$1')}`);
  });
  console.error('[TELEBIRR CONFIG] Telebirr payments will NOT work without these!');
}

module.exports = config;
