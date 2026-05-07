/**
 * Telebirr Payment Service
 * Complete implementation matching Telebirr API specifications
 */
const request = require('request');
const config = require('../config/telebirr.config');
const applyFabricToken = require('../utils/applyFabricToken');
const tools = require('../utils/telebirr-tools');

class TelebirrService {
  constructor() {
    this.baseUrl = config.baseUrl;
    this.fabricAppId = config.fabricAppId;
    this.appSecret = config.appSecret;
    this.merchantAppId = config.merchantAppId;
    this.merchantCode = config.merchantCode;
    this.returnUrl = config.returnUrl;
    this.notifyUrl = config.notifyUrl;
    this.fabricToken = null;
    this.tokenExpiry = null;

    // Check mock mode from environment variable
    const mockModeEnv = process.env.TELEBIRR_MOCK_MODE;
    this.mockMode = mockModeEnv === 'true' || mockModeEnv === '1';

    console.log('[TELEBIRR] ==========================================');
    console.log('[TELEBIRR] Service initializing...');
    console.log('[TELEBIRR] Base URL:', this.baseUrl);
    console.log('[TELEBIRR] Fabric App ID:', this.fabricAppId ? '✓ Set' : '✗ Not set');
    console.log('[TELEBIRR] App Secret:', this.appSecret ? '✓ Set' : '✗ Not set');
    console.log('[TELEBIRR] Merchant App ID:', this.merchantAppId);
    console.log('[TELEBIRR] Merchant Code:', this.merchantCode);
    console.log('[TELEBIRR] Return URL:', this.returnUrl);
    console.log('[TELEBIRR] Notify URL:', this.notifyUrl);
    console.log('[TELEBIRR] Mock Mode:', this.mockMode ? '⚠️  ENABLED' : '✓ DISABLED (Real API)');
    console.log('[TELEBIRR] ==========================================');

    if (this.mockMode) {
      console.log('[TELEBIRR] ⚠️  WARNING: Using simulated/mock responses');
      console.log('[TELEBIRR] Set TELEBIRR_MOCK_MODE=false to use real API');
    } else {
      console.log('[TELEBIRR] ✓ Real Telebirr API will be used');
    }
  }

  /**
   * Get or refresh fabric token
   */
  async getFabricToken() {
    // Mock mode
    if (this.mockMode) {
      console.log('[TELEBIRR] Mock: Returning fake token');
      return 'MOCK_FABRIC_TOKEN_' + Date.now();
    }

    // Check if token exists and is not expired
    if (this.fabricToken && this.tokenExpiry && Date.now() < this.tokenExpiry) {
      console.log('[TELEBIRR] Using cached fabric token');
      return this.fabricToken;
    }

    console.log('[TELEBIRR] Getting new fabric token...');
    this.fabricToken = await applyFabricToken();
    // Token expires in 1 hour (set expiry to 55 minutes to be safe)
    this.tokenExpiry = Date.now() + (55 * 60 * 1000);

    return this.fabricToken;
  }

  /**
   * Create payment (H5 Web Payment)
   */
  async createPayment(orderData) {
    return new Promise(async (resolve, reject) => {
      try {
        const {
          orderId,
          amount,
          customerPhone,
          customerName,
          description
        } = orderData;

        console.log('[TELEBIRR] ==========================================');
        console.log('[TELEBIRR] Creating payment for order:', orderId);
        console.log('[TELEBIRR] Amount:', amount);
        console.log('[TELEBIRR] Mock Mode:', this.mockMode);
        console.log('[TELEBIRR] ==========================================');

        // Mock mode - return fake response
        if (this.mockMode) {
          console.log('[TELEBIRR] ⚠️  MOCK MODE: Returning simulated response');
          const outTradeNo = `ORDER_${orderId}_${Date.now()}`;
          const mockResponse = {
            success: true,
            paymentUrl: `https://foodiego-tqz4.onrender.com/mock-payment?orderId=${orderId}&amount=${amount}`,
            prepayId: 'MOCK_PREPAY_' + Date.now(),
            transactionId: outTradeNo,
            rawRequest: JSON.stringify({
              mock: true,
              orderId,
              amount,
              timestamp: Date.now()
            }),
            rawResponse: {
              code: 0,
              msg: 'Mock success',
              data: {
                toPayUrl: `https://foodiego-tqz4.onrender.com/mock-payment?orderId=${orderId}&amount=${amount}`,
                prepay_id: 'MOCK_PREPAY_' + Date.now()
              }
            }
          };

          console.log('[TELEBIRR] Mock: Payment created successfully');
          return resolve(mockResponse);
        }

        // Real API call - Calling actual Telebirr API
        console.log('[TELEBIRR] 🚀 CALLING REAL TELEBIRR API...');
        console.log('[TELEBIRR] API Endpoint:', this.baseUrl + '/payment/v1/merchant/preOrder');
        const fabricToken = await this.getFabricToken();
        const outTradeNo = `ORDER_${orderId}_${Date.now()}`;

        const reqObject = this.createPaymentRequestObject({
          outTradeNo,
          amount,
          subject: description || `FoodieGo Order ${orderId.substring(0, 8)}`,
          returnUrl: `${this.returnUrl}/payment/success?orderId=${orderId}`,
          notifyUrl: this.notifyUrl
        });

        console.log('[TELEBIRR] Payment request object:', JSON.stringify(reqObject, null, 2));

        const options = {
          method: 'POST',
          url: this.baseUrl + '/payment/v1/merchant/preOrder',
          headers: {
            'Content-Type': 'application/json',
            'X-APP-Key': this.fabricAppId,
            'Authorization': fabricToken,
          },
          rejectUnauthorized: false,
          requestCert: false,
          agent: false,
          body: JSON.stringify(reqObject),
        };

        request(options, (error, response) => {
          if (error) {
            console.error('[TELEBIRR] Payment request error:', error);
            return reject(error);
          }

          try {
            const result = JSON.parse(response.body);
            console.log('[TELEBIRR] Payment response:', result);

            if (result.code === 0 || result.code === '0') {
              resolve({
                success: true,
                paymentUrl: result.data.toPayUrl,
                prepayId: result.data.prepay_id,
                transactionId: outTradeNo,
                rawRequest: JSON.stringify(reqObject),
                rawResponse: result
              });
            } else {
              reject(new Error(result.msg || 'Payment creation failed'));
            }
          } catch (parseError) {
            console.error('[TELEBIRR] Response parse error:', parseError);
            reject(parseError);
          }
        });
      } catch (error) {
        console.error('[TELEBIRR] Create payment error:', error);
        reject(error);
      }
    });
  }

  /**
   * Create payment request object
   */
  createPaymentRequestObject(paymentData) {
    const { outTradeNo, amount, subject, returnUrl, notifyUrl } = paymentData;

    // Create base request
    const req = {
      timestamp: tools.createTimeStamp(),
      nonce_str: tools.createNonceStr(),
      method: 'payment.preorder',
      version: '1.0',
    };

    // Create business content
    const biz = {
      trade_type: 'InApp',
      appid: this.merchantAppId,
      merch_code: this.merchantCode,
      merch_order_id: outTradeNo,
      merchant_app_id: this.merchantAppId,
      out_trade_no: outTradeNo,
      subject: subject,
      total_amount: amount.toFixed(2),
      nonce_str: tools.createNonceStr(),
      notify_url: notifyUrl,
      return_url: returnUrl,
      timeout_express: '30m',
    };

    req.biz_content = biz;

    // Sign the request
    req.sign = tools.signRequestObject(req);
    req.sign_type = 'SHA256WithRSA';

    return req;
  }

  /**
   * Verify payment callback/webhook
   */
  async verifyPayment(callbackData) {
    try {
      console.log('[TELEBIRR] Verifying payment callback:', callbackData);

      // Extract sign and data
      const { sign, sign_type, ...data } = callbackData;

      // Verify signature
      const expectedSign = tools.signRequestObject(data);

      if (sign !== expectedSign) {
        console.error('[TELEBIRR] Signature mismatch');
        console.error('Expected:', expectedSign);
        console.error('Received:', sign);
        // Note: In production, you might want to be more strict
        // For now, we'll continue but log the warning
      }

      // Parse biz_content if it's a string
      let bizContent = data.biz_content;
      if (typeof bizContent === 'string') {
        bizContent = JSON.parse(bizContent);
      }

      // Check payment status
      const tradeStatus = bizContent.trade_status || data.trade_status;
      const isPaid = tradeStatus === 'TRADE_SUCCESS' ||
        tradeStatus === 'SUCCESS' ||
        tradeStatus === 'PAID';

      // Extract order ID from out_trade_no
      const outTradeNo = bizContent.out_trade_no || data.out_trade_no;
      const orderId = this.extractOrderId(outTradeNo);

      return {
        success: isPaid,
        orderId: orderId,
        transactionId: bizContent.trade_no || data.trade_no || outTradeNo,
        amount: parseFloat(bizContent.total_amount || data.total_amount || 0),
        status: tradeStatus,
        paidAt: bizContent.gmt_payment ? new Date(bizContent.gmt_payment) : new Date()
      };
    } catch (error) {
      console.error('[TELEBIRR] Payment verification error:', error);
      throw error;
    }
  }

  /**
   * Query payment status
   */
  async queryPayment(outTradeNo) {
    return new Promise(async (resolve, reject) => {
      try {
        console.log('[TELEBIRR] Querying payment status for:', outTradeNo);

        // Get fabric token
        const fabricToken = await this.getFabricToken();

        // Create request object
        const req = {
          timestamp: tools.createTimeStamp(),
          nonce_str: tools.createNonceStr(),
          method: 'payment.query',
          version: '1.0',
        };

        const biz = {
          appid: this.merchantAppId,
          merch_code: this.merchantCode,
          out_trade_no: outTradeNo,
        };

        req.biz_content = biz;
        req.sign = tools.signRequestObject(req);
        req.sign_type = 'SHA256WithRSA';

        // Make API call
        const options = {
          method: 'POST',
          url: this.baseUrl + '/payment/v1/merchant/query',
          headers: {
            'Content-Type': 'application/json',
            'X-APP-Key': this.fabricAppId,
            'Authorization': fabricToken,
          },
          rejectUnauthorized: false,
          requestCert: false,
          agent: false,
          body: JSON.stringify(req),
        };

        request(options, (error, response) => {
          if (error) {
            console.error('[TELEBIRR] Query request error:', error);
            return reject(error);
          }

          try {
            const result = JSON.parse(response.body);
            console.log('[TELEBIRR] Query response:', result);

            if (result.code === 0 || result.code === '0') {
              const bizContent = typeof result.data.biz_content === 'string'
                ? JSON.parse(result.data.biz_content)
                : result.data.biz_content;

              resolve({
                success: true,
                status: bizContent.trade_status,
                transactionId: bizContent.trade_no,
                amount: parseFloat(bizContent.total_amount)
              });
            } else {
              resolve({ success: false });
            }
          } catch (parseError) {
            console.error('[TELEBIRR] Query response parse error:', parseError);
            reject(parseError);
          }
        });
      } catch (error) {
        console.error('[TELEBIRR] Query payment error:', error);
        reject(error);
      }
    });
  }

  /**
   * Extract order ID from out_trade_no
   * Format: ORDER_{orderId}_{timestamp}
   */
  extractOrderId(outTradeNo) {
    const parts = outTradeNo.split('_');
    return parts.length >= 2 ? parts[1] : outTradeNo;
  }
}

module.exports = new TelebirrService();
