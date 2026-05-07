/**
 * Apply Fabric Token for Telebirr API
 * Gets authentication token from Telebirr
 */
const config = require("../config/telebirr.config");
const request = require("request");

function applyFabricToken() {
  return new Promise((resolve, reject) => {
    // Validate credentials before making request
    if (!config.fabricAppId || !config.appSecret) {
      const missing = [];
      if (!config.fabricAppId) missing.push('TELEBIRR_FABRIC_APP_ID');
      if (!config.appSecret) missing.push('TELEBIRR_APP_SECRET');
      console.error('[TELEBIRR] ❌ Cannot request token - missing credentials:', missing);
      return reject(new Error(`Missing Telebirr credentials: ${missing.join(', ')}`));
    }

    const options = {
      method: "POST",
      url: config.baseUrl + "/payment/v1/token",
      headers: {
        "Content-Type": "application/json",
        "X-APP-Key": config.fabricAppId,
      },
      rejectUnauthorized: false, // for HTTPS
      requestCert: false, // for HTTPS
      agent: false, // for HTTPS
      body: JSON.stringify({
        appSecret: config.appSecret,
      }),
    };

    console.log('[TELEBIRR] Requesting fabric token from:', config.baseUrl + '/payment/v1/token');
    console.log('[TELEBIRR] Using Fabric App ID:', config.fabricAppId.substring(0, 8) + '...');

    request(options, function (error, response) {
      if (error) {
        console.error('[TELEBIRR] ❌ Token request error:', error.message);
        console.error('[TELEBIRR] Error details:', error);
        return reject(new Error(`Telebirr API connection failed: ${error.message}`));
      }

      console.log('[TELEBIRR] Token response status:', response.statusCode);
      console.log('[TELEBIRR] Token response body:', response.body);

      try {
        const result = JSON.parse(response.body);
        console.log('[TELEBIRR] Parsed response:', result);

        if (result.code === 0 || result.code === '0') {
          console.log('[TELEBIRR] ✅ Fabric token obtained successfully');
          // Return just the token string
          resolve(result.data.token);
        } else {
          console.error('[TELEBIRR] ❌ Token request failed - Code:', result.code, 'Message:', result.msg);
          reject(new Error(`Telebirr token error: ${result.msg || 'Unknown error'} (code: ${result.code})`));
        }
      } catch (parseError) {
        console.error('[TELEBIRR] ❌ Token response parse error:', parseError.message);
        console.error('[TELEBIRR] Raw response body:', response.body);
        reject(new Error(`Failed to parse Telebirr response: ${parseError.message}`));
      }
    });
  });
}

module.exports = applyFabricToken;
