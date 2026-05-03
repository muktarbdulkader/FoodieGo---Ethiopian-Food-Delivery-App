/**
 * Update all table QR codes to use production URL
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Table = require('../models/Table');

const OLD_URL = 'http://localhost:5173';
const NEW_URL = process.env.WEB_APP_URL || 'https://foodiego-99b1e.web.app';

async function updateQRUrls() {
  try {
    console.log('🚀 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    console.log(`📝 Updating QR codes from ${OLD_URL} to ${NEW_URL}...\n`);

    // Find all tables with old URL
    const tables = await Table.find({ qrCodeData: { $regex: OLD_URL } });
    console.log(`Found ${tables.length} tables to update\n`);

    let updated = 0;
    for (const table of tables) {
      const oldQR = table.qrCodeData;
      const newQR = oldQR.replace(OLD_URL, NEW_URL);
      
      table.qrCodeData = newQR;
      await table.save();
      
      console.log(`✅ Updated ${table.tableNumber}: ${newQR}`);
      updated++;
    }

    console.log(`\n🎉 Successfully updated ${updated} tables!`);
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

updateQRUrls();
