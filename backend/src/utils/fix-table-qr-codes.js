/**
 * Fix QR Code Data for Existing Tables
 * Run this script to update all tables with proper qrCodeData URLs
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Table = require('../models/Table');

const WEB_APP_URL = process.env.WEB_APP_URL || 'https://foodiego-99b1e.web.app';

async function fixTableQRCodes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all tables
    const tables = await Table.find({});
    console.log(`\n📊 Found ${tables.length} tables to update`);

    let updatedCount = 0;
    let skippedCount = 0;

    for (const table of tables) {
      // Check if qrCodeData is missing or invalid
      if (!table.qrCodeData || table.qrCodeData === 'temp' || !table.qrCodeData.startsWith('http')) {
        // Generate proper QR code data
        const newQRCodeData = `${WEB_APP_URL}/dine-in-menu?restaurantId=${table.restaurantId}&tableId=${table._id}`;
        
        table.qrCodeData = newQRCodeData;
        await table.save();
        
        console.log(`✅ Updated Table ${table.tableNumber} (${table._id})`);
        console.log(`   QR Code: ${newQRCodeData}`);
        updatedCount++;
      } else {
        console.log(`⏭️  Skipped Table ${table.tableNumber} (already has valid QR code)`);
        skippedCount++;
      }
    }

    console.log('\n' + '='.repeat(60));
    console.log('📊 Summary:');
    console.log(`   Total tables: ${tables.length}`);
    console.log(`   ✅ Updated: ${updatedCount}`);
    console.log(`   ⏭️  Skipped: ${skippedCount}`);
    console.log('='.repeat(60));

    if (updatedCount > 0) {
      console.log('\n✨ All tables have been updated with proper QR codes!');
      console.log('🎉 You can now download QR codes from the admin panel.');
    } else {
      console.log('\n✨ All tables already have valid QR codes!');
    }

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\n👋 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Run the script
console.log('🚀 Starting QR Code Fix Script...');
console.log(`🌐 Web App URL: ${WEB_APP_URL}\n`);
fixTableQRCodes();
