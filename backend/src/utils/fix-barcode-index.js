/**
 * Fix Duplicate Barcode Index
 * This script drops the old barcode index and recreates it properly
 */
require('dotenv').config();
const mongoose = require('mongoose');
const Food = require('../models/Food');

const fixBarcodeIndex = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get all indexes
    const indexes = await Food.collection.getIndexes();
    console.log('\n📋 Current indexes:', Object.keys(indexes));

    // Drop the duplicate barcode index if it exists
    try {
      await Food.collection.dropIndex('barcode_1');
      console.log('✅ Dropped old barcode_1 index');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ️  Index barcode_1 does not exist (already dropped)');
      } else {
        console.log('⚠️  Could not drop barcode_1:', error.message);
      }
    }

    // Recreate the index properly
    await Food.collection.createIndex(
      { barcode: 1 }, 
      { unique: true, sparse: true, name: 'barcode_unique' }
    );
    console.log('✅ Created new barcode_unique index');

    // Verify indexes
    const newIndexes = await Food.collection.getIndexes();
    console.log('\n📋 Updated indexes:', Object.keys(newIndexes));

    console.log('\n✅ Barcode index fixed successfully!');
    console.log('ℹ️  Restart your server to see the changes\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error fixing index:', error);
    process.exit(1);
  }
};

fixBarcodeIndex();
