/**
 * Database Seeder - Hotels with Foods
 */
require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Food = require('../models/Food');
const { hashPassword } = require('./hash');

const seedDatabase = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    await Promise.all([User.deleteMany({}), Food.deleteMany({})]);
    console.log('Cleared existing data');

    const adminPassword = await hashPassword('admin123');
    const userPassword = await hashPassword('user123');

    // Create Hotels (Admin Users)
    const hotels = await User.create([
      {
        name: 'Pizza Palace Admin',
        email: 'pizza@foodiego.com',
        password: adminPassword,
        role: 'admin',
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
      },
      {
        name: 'Burger Barn Admin',
        email: 'burger@foodiego.com',
        password: adminPassword,
        role: 'admin',
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
      },
      {
        name: 'Habesha Kitchen Admin',
        email: 'habesha@foodiego.com',
        password: adminPassword,
        role: 'admin',
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
      },
      {
        name: 'Sweet Treats Admin',
        email: 'sweets@foodiego.com',
        password: adminPassword,
        role: 'admin',
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
      },
    ]);
    console.log('Created hotel admins');

    // Create regular user
    await User.create({
      name: 'John Doe',
      email: 'user@foodiego.com',
      password: userPassword,
      role: 'user',
      address: 'Megenagna, Addis Ababa',
    });
    console.log('Created test user');

    // Create Foods for each hotel
    const pizzaPalace = hotels[0];
    const burgerBarn = hotels[1];
    const habeshaKitchen = hotels[2];
    const sweetTreats = hotels[3];

    const foods = [
      // Pizza Palace Foods
      { name: 'Margherita Pizza', description: 'Classic tomato sauce, fresh mozzarella, basil', price: 280, hotelId: pizzaPalace._id, hotelName: 'Pizza Palace', category: 'Pizza', rating: 4.6, preparationTime: 25, calories: 850, isVegetarian: true, isFeatured: true, image: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400' },
      { name: 'Pepperoni Pizza', description: 'Loaded with pepperoni, extra cheese', price: 320, hotelId: pizzaPalace._id, hotelName: 'Pizza Palace', category: 'Pizza', rating: 4.7, preparationTime: 25, calories: 950, isSpicy: true, image: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400' },
      { name: 'BBQ Chicken Pizza', description: 'Grilled chicken, BBQ sauce, onions', price: 350, hotelId: pizzaPalace._id, hotelName: 'Pizza Palace', category: 'Pizza', rating: 4.5, preparationTime: 30, calories: 920, image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400' },
      { name: 'Vegetable Supreme', description: 'Bell peppers, mushrooms, olives, onions', price: 300, hotelId: pizzaPalace._id, hotelName: 'Pizza Palace', category: 'Pizza', rating: 4.4, preparationTime: 25, calories: 780, isVegetarian: true, image: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400' },
      
      // Burger Barn Foods
      { name: 'Classic Burger', description: 'Angus beef patty, lettuce, tomato, special sauce', price: 180, hotelId: burgerBarn._id, hotelName: 'Burger Barn', category: 'Burger', rating: 4.4, preparationTime: 15, calories: 650, isFeatured: true, image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400' },
      { name: 'Cheese Burger Deluxe', description: 'Double cheese, bacon, pickles', price: 220, hotelId: burgerBarn._id, hotelName: 'Burger Barn', category: 'Burger', rating: 4.6, preparationTime: 18, calories: 850, image: 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400' },
      { name: 'Spicy Jalapeño Burger', description: 'Pepper jack cheese, jalapeños, chipotle mayo', price: 200, hotelId: burgerBarn._id, hotelName: 'Burger Barn', category: 'Burger', rating: 4.3, preparationTime: 18, calories: 720, isSpicy: true, image: 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=400' },
      { name: 'Crispy Chicken Burger', description: 'Crispy fried chicken, coleslaw, mayo', price: 190, hotelId: burgerBarn._id, hotelName: 'Burger Barn', category: 'Burger', rating: 4.5, preparationTime: 15, calories: 700, image: 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=400' },
      { name: 'French Fries', description: 'Crispy golden fries with ketchup', price: 80, hotelId: burgerBarn._id, hotelName: 'Burger Barn', category: 'Sides', rating: 4.2, preparationTime: 10, calories: 350, isVegetarian: true, image: 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400' },
      
      // Habesha Kitchen Foods
      { name: 'Doro Wot', description: 'Spicy chicken stew with berbere, served with injera', price: 350, hotelId: habeshaKitchen._id, hotelName: 'Habesha Kitchen', category: 'Ethiopian', rating: 4.9, preparationTime: 35, calories: 650, isSpicy: true, isFeatured: true, image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400' },
      { name: 'Tibs', description: 'Sautéed beef with onions, peppers, rosemary', price: 320, hotelId: habeshaKitchen._id, hotelName: 'Habesha Kitchen', category: 'Ethiopian', rating: 4.7, preparationTime: 25, calories: 580, image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400' },
      { name: 'Shiro', description: 'Chickpea stew with berbere spices', price: 200, hotelId: habeshaKitchen._id, hotelName: 'Habesha Kitchen', category: 'Ethiopian', rating: 4.6, preparationTime: 20, calories: 420, isVegetarian: true, image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400' },
      { name: 'Kitfo', description: 'Ethiopian steak tartare with mitmita', price: 380, hotelId: habeshaKitchen._id, hotelName: 'Habesha Kitchen', category: 'Ethiopian', rating: 4.8, preparationTime: 15, calories: 520, isSpicy: true, image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400' },
      { name: 'Beyaynetu', description: 'Vegetarian platter with various dishes', price: 280, hotelId: habeshaKitchen._id, hotelName: 'Habesha Kitchen', category: 'Ethiopian', rating: 4.7, preparationTime: 25, calories: 480, isVegetarian: true, image: 'https://images.unsplash.com/photo-1567521464027-f127ff144326?w=400' },
      
      // Sweet Treats Foods
      { name: 'Chocolate Lava Cake', description: 'Warm chocolate cake with molten center', price: 150, hotelId: sweetTreats._id, hotelName: 'Sweet Treats', category: 'Dessert', rating: 4.8, preparationTime: 15, calories: 520, isVegetarian: true, isFeatured: true, image: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400' },
      { name: 'New York Cheesecake', description: 'Creamy cheesecake with berry compote', price: 130, hotelId: sweetTreats._id, hotelName: 'Sweet Treats', category: 'Dessert', rating: 4.6, preparationTime: 10, calories: 450, isVegetarian: true, image: 'https://images.unsplash.com/photo-1567327613485-fbc7bf196198?w=400' },
      { name: 'Tiramisu', description: 'Classic Italian coffee-flavored dessert', price: 160, hotelId: sweetTreats._id, hotelName: 'Sweet Treats', category: 'Dessert', rating: 4.7, preparationTime: 10, calories: 480, isVegetarian: true, image: 'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400' },
      { name: 'Fresh Fruit Smoothie', description: 'Blend of seasonal fruits with yogurt', price: 90, hotelId: sweetTreats._id, hotelName: 'Sweet Treats', category: 'Drinks', rating: 4.5, preparationTime: 5, calories: 180, isVegetarian: true, image: 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400' },
      { name: 'Iced Coffee', description: 'Cold brew coffee with milk', price: 70, hotelId: sweetTreats._id, hotelName: 'Sweet Treats', category: 'Drinks', rating: 4.4, preparationTime: 5, calories: 120, isVegetarian: true, image: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400' },
    ];

    await Food.insertMany(foods);
    console.log('Created foods for all hotels');

    console.log('\n✅ Database seeded successfully!\n');
    console.log('=== Test Accounts ===');
    console.log('Admin (Pizza Palace): pizza@foodiego.com / admin123');
    console.log('Admin (Burger Barn):  burger@foodiego.com / admin123');
    console.log('Admin (Habesha):      habesha@foodiego.com / admin123');
    console.log('Admin (Sweet Treats): sweets@foodiego.com / admin123');
    console.log('User:                 user@foodiego.com / user123\n');
    
    process.exit(0);
  } catch (error) {
    console.error('Seeding error:', error);
    process.exit(1);
  }
};

seedDatabase();
