/**
 * Apply Fabric Token for Telebirr API
 * Gets authentication token from Telebirr
 */
const config = require("../config/telebirr.config");
const request = require("request");

function applyFabricToken() {
  return new Promise((resolve, reject) => {
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

    console.log('[TELEBIRR] Requesting fabric token...');

    request(options, function (error, response) {
      if (error) {
        console.error('[TELEBIRR] Token request error:', error);
        return reject(error);
      }

      try {
        const result = JSON.parse(response.body);
        console.log('[TELEBIRR] Token response:', result);
        
        if (result.code === 0 || result.code === '0') {
          console.log('[TELEBIRR] Fabric token obtained successfully');
          // Return just the token string
          resolve(result.data.token);
        } else {
          console.error('[TELEBIRR] Token request failed:', result);
          reject(new Error(result.msg || 'Failed to get fabric token'));
        }
      } catch (parseError) {
        console.error('[TELEBIRR] Token response parse error:', parseError);
        console.error('[TELEBIRR] Response body:', response.body);
        reject(parseError);
      }
    });
  });
}

module.exports = applyFabricToken;
