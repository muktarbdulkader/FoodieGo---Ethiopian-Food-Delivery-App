/**
 * Apply Fabric Token for Telebirr API
 * Gets authentication token from Telebirr
 */
const config = require("../config/telebirr.config");
const request = require("request");

// Retry configuration
const MAX_RETRIES = 2;
const REQUEST_TIMEOUT = 30000; // 30 seconds

function applyFabricTokenWithRetry(retryCount = 0) {
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
      timeout: REQUEST_TIMEOUT,
      body: JSON.stringify({
        appSecret: config.appSecret,
      }),
    };

    console.log(`[TELEBIRR] Requesting fabric token (attempt ${retryCount + 1}/${MAX_RETRIES})...`);
    console.log('[TELEBIRR] URL:', config.baseUrl + '/payment/v1/token');

    request(options, function (error, response) {
      if (error) {
        console.error('[TELEBIRR] ❌ Token request error:', error.message);

        // Check if it's a timeout error
        if (error.code === 'ETIMEDOUT' || error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
          console.error('[TELEBIRR] ⚠️ Network error - Telebirr API may be unreachable from this server');

          // Retry if we haven't exceeded max retries
          if (retryCount < MAX_RETRIES - 1) {
            console.log(`[TELEBIRR] Retrying in 2 seconds... (${retryCount + 1}/${MAX_RETRIES})`);
            setTimeout(() => {
              applyFabricTokenWithRetry(retryCount + 1)
                .then(resolve)
                .catch(reject);
            }, 2000);
            return;
          }

          // Final error with helpful message
          return reject(new Error(
            `Telebirr API is unreachable (timeout). This may be due to:\n` +
            `1. Network restrictions between your server and Telebirr\n` +
            `2. IP whitelisting required by Telebirr\n` +
            `3. Firewall blocking the connection\n` +
            `Please contact Telebirr support or try from a different server.`
          ));
        }

        return reject(new Error(`Telebirr API connection failed: ${error.message}`));
      }

      console.log('[TELEBIRR] Token response status:', response.statusCode);

      try {
        const result = JSON.parse(response.body);

        if (result.code === 0 || result.code === '0') {
          console.log('[TELEBIRR] ✅ Fabric token obtained successfully');
          resolve(result.data.token);
        } else {
          console.error('[TELEBIRR] ❌ Token request failed - Code:', result.code, 'Message:', result.msg);
          reject(new Error(`Telebirr token error: ${result.msg || 'Unknown error'} (code: ${result.code})`));
        }
      } catch (parseError) {
        console.error('[TELEBIRR] ❌ Token response parse error:', parseError.message);
        console.error('[TELEBIRR] Raw response:', response.body);
        reject(new Error(`Failed to parse Telebirr response: ${parseError.message}`));
      }
    });
  });
}

// Main function with retry wrapper
function applyFabricToken() {
  return applyFabricTokenWithRetry(0);
}

module.exports = applyFabricToken;
