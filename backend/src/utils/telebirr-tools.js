/**
 * Telebirr Tools
 * Utility functions for Telebirr API integration
 */
const crypto = require('crypto');
const NodeRSA = require('node-rsa');
const config = require('../config/telebirr.config');

/**
 * Create timestamp in Telebirr format
 */
function createTimeStamp() {
  return Math.floor(Date.now() / 1000).toString();
}

/**
 * Create random nonce string
 */
function createNonceStr(length = 32) {
  return crypto.randomBytes(length).toString('hex').substring(0, length);
}

/**
 * Sign request object with RSA private key
 */
function signRequestObject(requestObject) {
  try {
    // Create sign string from request object
    const signString = createSignString(requestObject);
    
    console.log('[TELEBIRR-TOOLS] Sign string:', signString);
    
    // Load private key
    const privateKey = new NodeRSA(config.privateKey);
    privateKey.setOptions({ signingScheme: 'pkcs1-sha256' });
    
    // Sign the string
    const signature = privateKey.sign(signString, 'base64');
    
    return signature;
  } catch (error) {
    console.error('[TELEBIRR-TOOLS] Signing error:', error);
    throw error;
  }
}

/**
 * Create sign string from request object
 * Concatenates all fields except sign and sign_type
 */
function createSignString(obj) {
  // Get all keys except 'sign' and 'sign_type'
  const keys = Object.keys(obj)
    .filter(key => key !== 'sign' && key !== 'sign_type')
    .sort();
  
  // Build sign string
  const parts = [];
  for (const key of keys) {
    const value = obj[key];
    if (value !== null && value !== undefined && value !== '') {
      if (typeof value === 'object') {
        parts.push(`${key}=${JSON.stringify(value)}`);
      } else {
        parts.push(`${key}=${value}`);
      }
    }
  }
  
  return parts.join('&');
}

/**
 * Encrypt data with public key (if needed)
 */
function encryptWithPublicKey(data, publicKey) {
  try {
    const key = new NodeRSA(publicKey);
    return key.encrypt(data, 'base64');
  } catch (error) {
    console.error('[TELEBIRR-TOOLS] Encryption error:', error);
    return data;
  }
}

/**
 * Decrypt data with private key (if needed)
 */
function decryptWithPrivateKey(encryptedData) {
  try {
    const privateKey = new NodeRSA(config.privateKey);
    return privateKey.decrypt(encryptedData, 'utf8');
  } catch (error) {
    console.error('[TELEBIRR-TOOLS] Decryption error:', error);
    return encryptedData;
  }
}

module.exports = {
  createTimeStamp,
  createNonceStr,
  signRequestObject,
  createSignString,
  encryptWithPublicKey,
  decryptWithPrivateKey
};
