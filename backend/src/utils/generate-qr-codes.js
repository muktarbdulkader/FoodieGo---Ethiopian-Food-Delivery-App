/**
 * QR Code Generator for Restaurant Tables
 * 
 * This script generates QR codes for all tables in a restaurant
 * Usage: node src/utils/generate-qr-codes.js <restaurantId>
 */

const QRCode = require('qrcode');
const fs = require('fs').promises;
const path = require('path');
const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Table = require('../models/Table');
const User = require('../models/User');

// Connect to database
const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected to MongoDB');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    process.exit(1);
  }
};

// Generate QR code as PNG
const generateQRCode = async (data, filename) => {
  try {
    await QRCode.toFile(filename, data, {
      width: 500,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF'
      }
    });
    return true;
  } catch (error) {
    console.error(`Error generating QR code for ${filename}:`, error);
    return false;
  }
};

// Generate HTML page with all QR codes for printing
const generatePrintableHTML = (tables, restaurantName) => {
  const qrCodeRows = tables.map(table => `
    <div class="qr-card">
      <div class="restaurant-name">${restaurantName}</div>
      <div class="scan-text">Scan to Order</div>
      <img src="qr-codes/table-${table.tableNumber}.png" alt="QR Code for ${table.tableNumber}">
      <div class="table-number">Table: ${table.tableNumber}</div>
      <div class="capacity">Capacity: ${table.capacity} people</div>
    </div>
  `).join('\n');

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${restaurantName} - Table QR Codes</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Arial', sans-serif;
      padding: 20px;
      background: #f5f5f5;
    }
    
    .header {
      text-align: center;
      margin-bottom: 30px;
      padding: 20px;
      background: white;
      border-radius: 10px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    
    .header h1 {
      color: #FF6B35;
      margin-bottom: 10px;
    }
    
    .header p {
      color: #666;
    }
    
    .qr-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
      gap: 20px;
      margin-bottom: 30px;
    }
    
    .qr-card {
      background: white;
      border-radius: 15px;
      padding: 30px;
      text-align: center;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
      border: 2px solid #FF6B35;
      page-break-inside: avoid;
    }
    
    .restaurant-name {
      font-size: 18px;
      font-weight: bold;
      color: #FF6B35;
      margin-bottom: 10px;
    }
    
    .scan-text {
      font-size: 16px;
      color: #666;
      margin-bottom: 20px;
    }
    
    .qr-card img {
      width: 200px;
      height: 200px;
      margin: 0 auto 20px;
      display: block;
    }
    
    .table-number {
      font-size: 24px;
      font-weight: bold;
      color: #333;
      margin-bottom: 5px;
    }
    
    .capacity {
      font-size: 14px;
      color: #999;
    }
    
    @media print {
      body {
        background: white;
        padding: 0;
      }
      
      .header {
        box-shadow: none;
        border-bottom: 2px solid #FF6B35;
        border-radius: 0;
      }
      
      .qr-grid {
        grid-template-columns: repeat(2, 1fr);
      }
      
      .qr-card {
        box-shadow: none;
        border: 2px solid #FF6B35;
      }
    }
    
    .print-button {
      position: fixed;
      bottom: 30px;
      right: 30px;
      background: #FF6B35;
      color: white;
      border: none;
      padding: 15px 30px;
      border-radius: 50px;
      font-size: 16px;
      font-weight: bold;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(255, 107, 53, 0.4);
      transition: all 0.3s;
    }
    
    .print-button:hover {
      background: #E55A2B;
      transform: translateY(-2px);
      box-shadow: 0 6px 20px rgba(255, 107, 53, 0.5);
    }
    
    @media print {
      .print-button {
        display: none;
      }
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>${restaurantName}</h1>
    <p>Table QR Codes for Dine-In Ordering</p>
    <p style="margin-top: 10px; font-size: 14px;">Generated on ${new Date().toLocaleDateString()}</p>
  </div>
  
  <div class="qr-grid">
    ${qrCodeRows}
  </div>
  
  <button class="print-button" onclick="window.print()">🖨️ Print QR Codes</button>
</body>
</html>
  `;
};

// Main function
const generateQRCodes = async (restaurantId) => {
  try {
    console.log('🚀 Starting QR Code Generation...\n');

    // Validate restaurant ID
    if (!restaurantId) {
      console.error('❌ Please provide a restaurant ID');
      console.log('Usage: node src/utils/generate-qr-codes.js <restaurantId>');
      process.exit(1);
    }

    // Connect to database
    await connectDB();

    // Find restaurant
    const restaurant = await User.findById(restaurantId);
    if (!restaurant || restaurant.role !== 'restaurant') {
      console.error('❌ Restaurant not found');
      process.exit(1);
    }

    console.log(`📍 Restaurant: ${restaurant.hotelName || restaurant.name}`);

    // Find all tables for this restaurant
    const tables = await Table.find({ restaurantId }).sort({ tableNumber: 1 });
    
    if (tables.length === 0) {
      console.error('❌ No tables found for this restaurant');
      console.log('💡 Create tables first using: POST /api/tables/bulk');
      process.exit(1);
    }

    console.log(`📊 Found ${tables.length} tables\n`);

    // Create output directory
    const outputDir = path.join(__dirname, '../../qr-codes');
    await fs.mkdir(outputDir, { recursive: true });

    // Generate QR codes
    console.log('🎨 Generating QR codes...');
    let successCount = 0;

    for (const table of tables) {
      const filename = path.join(outputDir, `table-${table.tableNumber}.png`);
      const success = await generateQRCode(table.qrCodeData, filename);
      
      if (success) {
        successCount++;
        console.log(`  ✅ ${table.tableNumber}: ${filename}`);
      } else {
        console.log(`  ❌ ${table.tableNumber}: Failed`);
      }
    }

    // Generate printable HTML
    console.log('\n📄 Generating printable HTML...');
    const html = generatePrintableHTML(tables, restaurant.hotelName || restaurant.name);
    const htmlPath = path.join(outputDir, 'print-qr-codes.html');
    await fs.writeFile(htmlPath, html);
    console.log(`  ✅ ${htmlPath}`);

    // Generate summary
    console.log('\n' + '='.repeat(50));
    console.log('✨ QR Code Generation Complete!');
    console.log('='.repeat(50));
    console.log(`📊 Total Tables: ${tables.length}`);
    console.log(`✅ Successfully Generated: ${successCount}`);
    console.log(`❌ Failed: ${tables.length - successCount}`);
    console.log(`📁 Output Directory: ${outputDir}`);
    console.log('\n📋 Next Steps:');
    console.log('  1. Open: ' + htmlPath);
    console.log('  2. Click "Print QR Codes" button');
    console.log('  3. Print or save as PDF');
    console.log('  4. Cut and laminate');
    console.log('  5. Place on tables');
    console.log('\n💡 Tip: You can also use individual PNG files for custom designs');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    await mongoose.connection.close();
    console.log('\n👋 Database connection closed');
  }
};

// Run if called directly
if (require.main === module) {
  const restaurantId = process.argv[2];
  generateQRCodes(restaurantId);
}

module.exports = { generateQRCodes };
