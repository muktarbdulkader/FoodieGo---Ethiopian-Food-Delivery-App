/**
 * Migration script to update all 'admin' roles to 'restaurant'
 */
require('dotenv').config();
const mongoose = require('mongoose');

const migrate = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Update all users with role 'admin' to 'restaurant'
    const result = await mongoose.connection.db.collection('users').updateMany(
      { role: 'admin' },
      { $set: { role: 'restaurant' } }
    );

    console.log(`Updated ${result.modifiedCount} users from 'admin' to 'restaurant'`);
    
    // Verify the update
    const adminCount = await mongoose.connection.db.collection('users').countDocuments({ role: 'admin' });
    const restaurantCount = await mongoose.connection.db.collection('users').countDocuments({ role: 'restaurant' });
    
    console.log(`Remaining admin users: ${adminCount}`);
    console.log(`Total restaurant users: ${restaurantCount}`);
    
    process.exit(0);
  } catch (error) {
    console.error('Migration error:', error);
    process.exit(1);
  }
};

migrate();
