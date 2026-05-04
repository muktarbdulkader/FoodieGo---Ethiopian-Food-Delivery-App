require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/User');

mongoose.connect(process.env.MONGODB_URI)
  .then(async () => {
    console.log('\n=== Restaurants in Database ===\n');
    
    const restaurants = await User.find({ role: 'restaurant' })
      .select('_id hotelName email');
    
    if (restaurants.length === 0) {
      console.log('No restaurants found!');
    } else {
      restaurants.forEach((r, index) => {
        console.log(`${index + 1}. Restaurant ID: ${r._id}`);
        console.log(`   Name: ${r.hotelName || 'Not set'}`);
        console.log(`   Email: ${r.email}`);
        console.log(`   Test URL: https://foodiego-99b1e.web.app/dine-in-menu?restaurantId=${r._id}&tableId=T01`);
        console.log('');
      });
    }
    
    process.exit(0);
  })
  .catch(err => {
    console.error('Error:', err.message);
    process.exit(1);
  });
