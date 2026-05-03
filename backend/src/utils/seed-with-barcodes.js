/**
 * Enhanced Database Seeder - With Barcodes and Menu Types
 * This seed file creates:
 * - Restaurants with location data
 * - Foods with barcodes for scanning
 * - Separate menu types (delivery, dine-in, takeaway)
 * - Tables with QR codes for dine-in
 */
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Food = require('../models/Food');
const Table = require('../models/Table');
const { hashPassword } = require('./hash');

// Helper function to generate barcode
const generateBarcode = (prefix, index) => {
  return `${prefix}${String(index).padStart(8, '0')}`;
};

const seedDatabase = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Clear existing data
    await Promise.all([
      User.deleteMany({}),
      Food.deleteMany({}),
      Table.deleteMany({})
    ]);
    console.log('🗑️  Cleared existing data');

    const adminPassword = await hashPassword('admin123');
    const userPassword = await hashPassword('user123');
    const deliveryPassword = await hashPassword('delivery123');

    // Create Hotels (Restaurant Users) with location data
    const hotels = await User.create([
      {
        name: 'Pizza Palace Owner',
        email: 'pizza@foodiego.com',
        password: adminPassword,
        role: 'restaurant',
        hotelName: 'Pizza Palace',
        hotelAddress: 'Bole Road, Addis Ababa',
        hotelPhone: '+251911223344',
        hotelDescription: 'Best Italian pizzas in town with authentic recipes',
        hotelImage: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=600',
        hotelCategory: 'restaurant',
        hotelRating: 4.7,
        isOpen: true,
        deliveryFee: 50,
        minOrderAmount: 200,
        location: {
          latitude: 9.0192,
          longitude: 38.7525,
          address: 'Bole Road, Addis Ababa',
          city: 'Addis Ababa'
        }
      },
      {
        name: 'Burger Barn Owner',
        email: 'burger@foodiego.com',
        password: adminPassword,
        role: 'restaurant',
        hotelName: 'Burger Barn',
        hotelAddress: 'Kazanchis, Addis Ababa',
        hotelPhone: '+251922334455',
        hotelDescription: 'Juicy burgers made with premium beef',
        hotelImage: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?w=600',
        hotelCategory: 'fast_food',
        hotelRating: 4.5,
        isOpen: true,
        deliveryFee: 40,
        minOrderAmount: 150,
        location: {
          latitude: 9.0320,
          longitude: 38.7469,
          address: 'Kazanchis, Addis Ababa',
          city: 'Addis Ababa'
        }
      },
      {
        name: 'Habesha Kitchen Owner',
        email: 'habesha@foodiego.com',
        password: adminPassword,
        role: 'restaurant',
        hotelName: 'Habesha Kitchen',
        hotelAddress: 'Piassa, Addis Ababa',
        hotelPhone: '+251933445566',
        hotelDescription: 'Authentic Ethiopian cuisine with traditional recipes',
        hotelImage: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=600',
        hotelCategory: 'restaurant',
        hotelRating: 4.8,
        isOpen: true,
        deliveryFee: 45,
        minOrderAmount: 180,
        location: {
          latitude: 9.0330,
          longitude: 38.7400,
          address: 'Piassa, Addis Ababa',
          city: 'Addis Ababa'
        }
      },
      {
        name: 'Sweet Treats Owner',
        email: 'sweets@foodiego.com',
        password: adminPassword,
        role: 'restaurant',
        hotelName: 'Sweet Treats',
        hotelAddress: 'Sarbet, Addis Ababa',
        hotelPhone: '+251944556677',
        hotelDescription: 'Delicious desserts and pastries',
        hotelImage: 'https://images.unsplash.com/photo-1517433670267-30f41c09c0a0?w=600',
        hotelCategory: 'bakery',
        hotelRating: 4.6,
        isOpen: true,
        deliveryFee: 35,
        minOrderAmount: 100,
        location: {
          latitude: 9.0250,
          longitude: 38.7580,
          address: 'Sarbet, Addis Ababa',
          city: 'Addis Ababa'
        }
      },
    ]);
    console.log('🏨 Created hotel owners with locations');

    // Create regular users
    await User.create([
      {
        name: 'John Doe',
        email: 'user@foodiego.com',
        password: userPassword,
        role: 'user',
        address: 'Megenagna, Addis Ababa',
        phone: '+251911111111',
        location: {
          latitude: 9.0200,
          longitude: 38.7600,
          address: 'Megenagna, Addis Ababa',
          city: 'Addis Ababa'
        }
      },
      {
        name: 'Abebe Kebede',
        email: 'delivery@foodiego.com',
        password: deliveryPassword,
        role: 'delivery',
        phone: '+251922222222',
        address: 'Bole, Addis Ababa'
      }
    ]);
    console.log('👤 Created test users (customer & delivery)');

    // Create Foods with barcodes and menu types
    const pizzaPalace = hotels[0];
    const burgerBarn = hotels[1];
    const habeshaKitchen = hotels[2];
    const sweetTreats = hotels[3];

    const foods = [
      // Pizza Palace Foods - Available for both delivery and dine-in
      { 
        name: 'Margherita Pizza', 
        description: 'Classic tomato sauce, fresh mozzarella, basil', 
        price: 280, 
        dineInPrice: 250, // Cheaper for dine-in
        hotelId: pizzaPalace._id, 
        hotelName: 'Pizza Palace', 
        category: 'Pizza', 
        rating: 4.6, 
        preparationTime: 25, 
        calories: 850, 
        isVegetarian: true, 
        isFeatured: true, 
        image: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
        barcode: generateBarcode('PP', 1),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Tomato Sauce', 'Mozzarella', 'Basil', 'Olive Oil'],
        allergens: ['Dairy', 'Gluten']
      },
      { 
        name: 'Pepperoni Pizza', 
        description: 'Loaded with pepperoni, extra cheese', 
        price: 320, 
        dineInPrice: 290,
        hotelId: pizzaPalace._id, 
        hotelName: 'Pizza Palace', 
        category: 'Pizza', 
        rating: 4.7, 
        preparationTime: 25, 
        calories: 950, 
        isSpicy: true, 
        image: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400',
        barcode: generateBarcode('PP', 2),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Tomato Sauce', 'Mozzarella', 'Pepperoni'],
        allergens: ['Dairy', 'Gluten', 'Pork']
      },
      { 
        name: 'BBQ Chicken Pizza', 
        description: 'Grilled chicken, BBQ sauce, onions', 
        price: 350, 
        dineInPrice: 320,
        hotelId: pizzaPalace._id, 
        hotelName: 'Pizza Palace', 
        category: 'Pizza', 
        rating: 4.5, 
        preparationTime: 30, 
        calories: 920, 
        image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400',
        barcode: generateBarcode('PP', 3),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['BBQ Sauce', 'Chicken', 'Onions', 'Mozzarella'],
        allergens: ['Dairy', 'Gluten']
      },
      { 
        name: 'Vegetable Supreme', 
        description: 'Bell peppers, mushrooms, olives, onions', 
        price: 300, 
        dineInPrice: 270,
        hotelId: pizzaPalace._id, 
        hotelName: 'Pizza Palace', 
        category: 'Pizza', 
        rating: 4.4, 
        preparationTime: 25, 
        calories: 780, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
        barcode: generateBarcode('PP', 4),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Bell Peppers', 'Mushrooms', 'Olives', 'Onions', 'Mozzarella'],
        allergens: ['Dairy', 'Gluten']
      },
      { 
        name: 'Garlic Bread', 
        description: 'Toasted bread with garlic butter', 
        price: 80, 
        dineInPrice: 70,
        hotelId: pizzaPalace._id, 
        hotelName: 'Pizza Palace', 
        category: 'Sides', 
        rating: 4.3, 
        preparationTime: 10, 
        calories: 250, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1573140401552-388e3ead0b7c?w=400',
        barcode: generateBarcode('PP', 5),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        allergens: ['Dairy', 'Gluten']
      },
      
      // Burger Barn Foods
      { 
        name: 'Classic Burger', 
        description: 'Angus beef patty, lettuce, tomato, special sauce', 
        price: 180, 
        dineInPrice: 160,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Burger', 
        rating: 4.4, 
        preparationTime: 15, 
        calories: 650, 
        isFeatured: true, 
        image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400',
        barcode: generateBarcode('BB', 1),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Beef Patty', 'Lettuce', 'Tomato', 'Special Sauce', 'Bun'],
        allergens: ['Gluten', 'Eggs']
      },
      { 
        name: 'Cheese Burger Deluxe', 
        description: 'Double cheese, bacon, pickles', 
        price: 220, 
        dineInPrice: 200,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Burger', 
        rating: 4.6, 
        preparationTime: 18, 
        calories: 850, 
        image: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400',
        barcode: generateBarcode('BB', 2),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Beef Patty', 'Cheddar Cheese', 'Bacon', 'Pickles', 'Bun'],
        allergens: ['Gluten', 'Dairy', 'Pork']
      },
      { 
        name: 'Spicy Jalapeño Burger', 
        description: 'Pepper jack cheese, jalapeños, chipotle mayo', 
        price: 200, 
        dineInPrice: 180,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Burger', 
        rating: 4.3, 
        preparationTime: 18, 
        calories: 720, 
        isSpicy: true, 
        image: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400',
        barcode: generateBarcode('BB', 3),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Beef Patty', 'Pepper Jack', 'Jalapeños', 'Chipotle Mayo', 'Bun'],
        allergens: ['Gluten', 'Dairy', 'Eggs']
      },
      { 
        name: 'Crispy Chicken Burger', 
        description: 'Crispy fried chicken, coleslaw, mayo', 
        price: 190, 
        dineInPrice: 170,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Burger', 
        rating: 4.5, 
        preparationTime: 15, 
        calories: 700, 
        image: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400',
        barcode: generateBarcode('BB', 4),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Chicken', 'Coleslaw', 'Mayo', 'Bun'],
        allergens: ['Gluten', 'Eggs']
      },
      { 
        name: 'French Fries', 
        description: 'Crispy golden fries with ketchup', 
        price: 80, 
        dineInPrice: 70,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Sides', 
        rating: 4.2, 
        preparationTime: 10, 
        calories: 350, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
        barcode: generateBarcode('BB', 5),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Potatoes', 'Salt'],
        allergens: []
      },
      { 
        name: 'Onion Rings', 
        description: 'Crispy battered onion rings', 
        price: 90, 
        dineInPrice: 80,
        hotelId: burgerBarn._id, 
        hotelName: 'Burger Barn', 
        category: 'Sides', 
        rating: 4.3, 
        preparationTime: 12, 
        calories: 380, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1639024471283-03518883512d?w=400',
        barcode: generateBarcode('BB', 6),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Onions', 'Batter'],
        allergens: ['Gluten', 'Eggs']
      },
      
      // Habesha Kitchen Foods
      { 
        name: 'Doro Wot', 
        description: 'Spicy chicken stew with berbere, served with injera', 
        price: 350, 
        dineInPrice: 320,
        hotelId: habeshaKitchen._id, 
        hotelName: 'Habesha Kitchen', 
        category: 'Ethiopian', 
        rating: 4.9, 
        preparationTime: 35, 
        calories: 650, 
        isSpicy: true, 
        isFeatured: true, 
        image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
        barcode: generateBarcode('HK', 1),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Chicken', 'Berbere', 'Onions', 'Garlic', 'Injera'],
        allergens: []
      },
      { 
        name: 'Tibs', 
        description: 'Sautéed beef with onions, peppers, rosemary', 
        price: 320, 
        dineInPrice: 290,
        hotelId: habeshaKitchen._id, 
        hotelName: 'Habesha Kitchen', 
        category: 'Ethiopian', 
        rating: 4.7, 
        preparationTime: 25, 
        calories: 580, 
        image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
        barcode: generateBarcode('HK', 2),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Beef', 'Onions', 'Peppers', 'Rosemary'],
        allergens: []
      },
      { 
        name: 'Shiro', 
        description: 'Chickpea stew with berbere spices', 
        price: 200, 
        dineInPrice: 180,
        hotelId: habeshaKitchen._id, 
        hotelName: 'Habesha Kitchen', 
        category: 'Ethiopian', 
        rating: 4.6, 
        preparationTime: 20, 
        calories: 420, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
        barcode: generateBarcode('HK', 3),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Chickpeas', 'Berbere', 'Onions', 'Garlic'],
        allergens: []
      },
      { 
        name: 'Kitfo', 
        description: 'Ethiopian steak tartare with mitmita', 
        price: 380, 
        dineInPrice: 350,
        hotelId: habeshaKitchen._id, 
        hotelName: 'Habesha Kitchen', 
        category: 'Ethiopian', 
        rating: 4.8, 
        preparationTime: 15, 
        calories: 520, 
        isSpicy: true, 
        image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
        barcode: generateBarcode('HK', 4),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Beef', 'Mitmita', 'Butter', 'Cheese'],
        allergens: ['Dairy']
      },
      { 
        name: 'Beyaynetu', 
        description: 'Vegetarian platter with various dishes', 
        price: 280, 
        dineInPrice: 250,
        hotelId: habeshaKitchen._id, 
        hotelName: 'Habesha Kitchen', 
        category: 'Ethiopian', 
        rating: 4.7, 
        preparationTime: 25, 
        calories: 480, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400',
        barcode: generateBarcode('HK', 5),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Lentils', 'Cabbage', 'Beets', 'Potatoes', 'Injera'],
        allergens: []
      },
      
      // Sweet Treats Foods - Some items only for takeaway/delivery
      { 
        name: 'Chocolate Lava Cake', 
        description: 'Warm chocolate cake with molten center', 
        price: 150, 
        dineInPrice: 140,
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Dessert', 
        rating: 4.8, 
        preparationTime: 15, 
        calories: 520, 
        isVegetarian: true, 
        isFeatured: true, 
        image: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400',
        barcode: generateBarcode('ST', 1),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Chocolate', 'Eggs', 'Flour', 'Sugar', 'Butter'],
        allergens: ['Eggs', 'Dairy', 'Gluten']
      },
      { 
        name: 'New York Cheesecake', 
        description: 'Creamy cheesecake with berry compote', 
        price: 130, 
        dineInPrice: 120,
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Dessert', 
        rating: 4.6, 
        preparationTime: 10, 
        calories: 450, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1567327613485-fbc7bf196198?w=400',
        barcode: generateBarcode('ST', 2),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Cream Cheese', 'Sugar', 'Eggs', 'Graham Crackers'],
        allergens: ['Eggs', 'Dairy', 'Gluten']
      },
      { 
        name: 'Tiramisu', 
        description: 'Classic Italian coffee-flavored dessert', 
        price: 160, 
        dineInPrice: 150,
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Dessert', 
        rating: 4.7, 
        preparationTime: 10, 
        calories: 480, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400',
        barcode: generateBarcode('ST', 3),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Mascarpone', 'Coffee', 'Ladyfingers', 'Cocoa'],
        allergens: ['Eggs', 'Dairy', 'Gluten']
      },
      { 
        name: 'Fresh Fruit Smoothie', 
        description: 'Blend of seasonal fruits with yogurt', 
        price: 90, 
        dineInPrice: 80,
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Drinks', 
        rating: 4.5, 
        preparationTime: 5, 
        calories: 180, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400',
        barcode: generateBarcode('ST', 4),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Banana', 'Strawberry', 'Yogurt', 'Honey'],
        allergens: ['Dairy']
      },
      { 
        name: 'Iced Coffee', 
        description: 'Cold brew coffee with milk', 
        price: 70, 
        dineInPrice: 60,
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Drinks', 
        rating: 4.4, 
        preparationTime: 5, 
        calories: 120, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
        barcode: generateBarcode('ST', 5),
        menuTypes: ['delivery', 'dine_in', 'takeaway'],
        ingredients: ['Coffee', 'Milk', 'Ice'],
        allergens: ['Dairy']
      },
      { 
        name: 'Birthday Cake (Whole)', 
        description: 'Custom birthday cake - Order in advance', 
        price: 800, 
        hotelId: sweetTreats._id, 
        hotelName: 'Sweet Treats', 
        category: 'Dessert', 
        rating: 4.9, 
        preparationTime: 120, 
        calories: 3500, 
        isVegetarian: true, 
        image: 'https://images.unsplash.com/photo-1558636508-e0db3814bd1d?w=400',
        barcode: generateBarcode('ST', 6),
        menuTypes: ['delivery', 'takeaway'], // NOT available for dine-in
        ingredients: ['Flour', 'Sugar', 'Eggs', 'Butter', 'Frosting'],
        allergens: ['Eggs', 'Dairy', 'Gluten']
      },
    ];

    await Food.insertMany(foods);
    console.log('🍕 Created foods with barcodes and menu types');

    // Create Tables for restaurants (for dine-in QR scanning)
    const WEB_APP_URL = process.env.WEB_APP_URL || 'http://localhost:5173';
    const tables = [];
    
    // Pizza Palace Tables
    for (let i = 1; i <= 10; i++) {
      const tableNumber = `T${String(i).padStart(2, '0')}`;
      const qrCodeData = `${WEB_APP_URL}/dine-in-menu?restaurantId=${pizzaPalace._id}&tableId=${tableNumber}`;
      tables.push({
        restaurantId: pizzaPalace._id,
        tableNumber,
        qrCodeData,
        capacity: i <= 4 ? 2 : i <= 8 ? 4 : 6,
        location: i <= 5 ? 'Indoor' : 'Outdoor',
        isActive: true,
      });
    }

    // Burger Barn Tables
    for (let i = 1; i <= 8; i++) {
      const tableNumber = `T${String(i).padStart(2, '0')}`;
      const qrCodeData = `${WEB_APP_URL}/dine-in-menu?restaurantId=${burgerBarn._id}&tableId=${tableNumber}`;
      tables.push({
        restaurantId: burgerBarn._id,
        tableNumber,
        qrCodeData,
        capacity: i <= 4 ? 2 : 4,
        location: 'Indoor',
        isActive: true,
      });
    }

    // Habesha Kitchen Tables
    for (let i = 1; i <= 12; i++) {
      const tableNumber = `T${String(i).padStart(2, '0')}`;
      const qrCodeData = `${WEB_APP_URL}/dine-in-menu?restaurantId=${habeshaKitchen._id}&tableId=${tableNumber}`;
      tables.push({
        restaurantId: habeshaKitchen._id,
        tableNumber,
        qrCodeData,
        capacity: i <= 6 ? 4 : 6,
        location: i <= 8 ? 'Indoor' : 'Terrace',
        isActive: true,
      });
    }

    await Table.insertMany(tables);
    console.log('🪑 Created tables for dine-in');

    console.log('\n✅ Database seeded successfully with barcodes!\n');
    console.log('=== Test Accounts ===');
    console.log('Restaurant (Pizza Palace): pizza@foodiego.com / admin123');
    console.log('Restaurant (Burger Barn):  burger@foodiego.com / admin123');
    console.log('Restaurant (Habesha):      habesha@foodiego.com / admin123');
    console.log('Restaurant (Sweet Treats): sweets@foodiego.com / admin123');
    console.log('Customer:                  user@foodiego.com / user123');
    console.log('Delivery:                  delivery@foodiego.com / delivery123\n');
    
    console.log('=== Barcode Examples ===');
    console.log('Pizza Palace:    PP00000001 - PP00000005');
    console.log('Burger Barn:     BB00000001 - BB00000006');
    console.log('Habesha Kitchen: HK00000001 - HK00000005');
    console.log('Sweet Treats:    ST00000001 - ST00000006\n');
    
    console.log('=== Menu Types ===');
    console.log('✅ Most items: Available for delivery, dine-in, and takeaway');
    console.log('⚠️  Birthday Cake: Only delivery and takeaway (not dine-in)\n');
    
    console.log('=== Tables Created ===');
    console.log('Pizza Palace:    10 tables (T01-T10)');
    console.log('Burger Barn:     8 tables (T01-T08)');
    console.log('Habesha Kitchen: 12 tables (T01-T12)\n');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding error:', error);
    process.exit(1);
  }
};

seedDatabase();
