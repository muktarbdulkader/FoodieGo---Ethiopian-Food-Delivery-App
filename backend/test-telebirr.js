/**
 * Test Telebirr Integration
 * Run this to test if Telebirr service is working
 * Usage: node test-telebirr.js
 */
require('dotenv').config();
const telebirrService = require('./src/services/telebirr.service');
const applyFabricToken = require('./src/utils/applyFabricToken');

async function testTelebirr() {
  console.log('='.repeat(60));
  console.log('🧪 Testing Telebirr Integration');
  console.log('='.repeat(60));

  try {
    // Test 1: Get Fabric Token
    console.log('\n📝 Test 1: Getting Fabric Token...');
    const token = await applyFabricToken();
    console.log('✅ Fabric Token obtained successfully!');
    console.log('Token (first 50 chars):', token.substring(0, 50) + '...');

    // Test 2: Create Payment
    console.log('\n📝 Test 2: Creating test payment...');
    const paymentResult = await telebirrService.createPayment({
      orderId: 'TEST' + Date.now(),
      amount: 10.00, // 10 ETB test amount
      customerPhone: '0911234567',
      customerName: 'Test Customer',
      description: 'Test Order Payment - FoodieGo'
    });

    console.log('✅ Payment created successfully!');
    console.log('\n📱 Payment Details:');
    console.log('   Payment URL:', paymentResult.paymentUrl);
    console.log('   Transaction ID:', paymentResult.transactionId);
    console.log('   Prepay ID:', paymentResult.prepayId);
    
    console.log('\n🌐 Next Steps:');
    console.log('   1. Open this URL in your browser:');
    console.log('   ', paymentResult.paymentUrl);
    console.log('   2. Complete the payment with Telebirr');
    console.log('   3. Check your backend logs for webhook callback');

    // Test 3: Query Payment (optional - will fail if payment not completed)
    console.log('\n📝 Test 3: Querying payment status...');
    try {
      const queryResult = await telebirrService.queryPayment(paymentResult.transactionId);
      console.log('✅ Query successful:', queryResult);
    } catch (queryError) {
      console.log('ℹ️  Query failed (expected if payment not completed):', queryError.message);
    }

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
    console.error('\n💡 Troubleshooting:');
    console.error('   - Check your Telebirr credentials in backend/src/config/telebirr.config.js');
    console.error('   - Ensure your merchant account is active');
    console.error('   - Verify network connectivity to Telebirr API');
  }

  console.log('\n' + '='.repeat(60));
}

// Run the test
testTelebirr().then(() => {
  console.log('\n✨ Test completed!');
  process.exit(0);
}).catch((error) => {
  console.error('\n💥 Test failed:', error);
  process.exit(1);
});
