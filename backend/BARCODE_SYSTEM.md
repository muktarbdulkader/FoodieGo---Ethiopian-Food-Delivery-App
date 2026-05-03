# 🔖 Barcode & Menu Type System

## Overview
This system allows restaurants to:
1. **Scan barcodes** to identify food items quickly
2. **Separate menus** for delivery, dine-in, and takeaway
3. **Track customers** who scan QR codes at tables
4. **Different pricing** for dine-in vs delivery

## 🎯 Features

### 1. Barcode System
Each food item has a unique barcode for easy scanning:
- **Format**: `PREFIX + 8-digit number`
- **Examples**:
  - Pizza Palace: `PP00000001`, `PP00000002`, etc.
  - Burger Barn: `BB00000001`, `BB00000002`, etc.
  - Habesha Kitchen: `HK00000001`, `HK00000002`, etc.
  - Sweet Treats: `ST00000001`, `ST00000002`, etc.

### 2. Menu Types
Foods can be available for different service types:
- **`delivery`**: Available for home delivery
- **`dine_in`**: Available when eating at the restaurant
- **`takeaway`**: Available for pickup

### 3. Customer Tracking (Dine-In)
When a customer scans a table QR code:
1. QR code contains: `restaurantId` and `tableId`
2. System creates a table session with:
   - Customer ID
   - Table number
   - Start time
   - Order IDs
3. Restaurant can see which customer is at which table

### 4. Dual Pricing
- **Delivery Price**: Regular price (includes packaging, delivery costs)
- **Dine-In Price**: Usually 10-15% cheaper (no packaging/delivery)

## 📦 Database Setup

### Run the Enhanced Seed File
```bash
cd backend
npm run seed:barcodes
```

This creates:
- ✅ 4 restaurants with location data
- ✅ 25+ food items with barcodes
- ✅ Menu types for each food
- ✅ 30 tables across restaurants
- ✅ Test users (customer & delivery)

## 🔍 API Endpoints

### Get Foods by Menu Type
```javascript
GET /api/foods?menuType=dine_in
GET /api/foods?menuType=delivery
GET /api/foods?menuType=takeaway
```

### Get Food by Barcode
```javascript
GET /api/foods/barcode/:barcode
// Example: GET /api/foods/barcode/PP00000001
```

### Get Foods for Restaurant (Filtered by Menu Type)
```javascript
GET /api/foods/hotel/:hotelId?menuType=dine_in
```

## 🏪 Restaurant Flow

### Dine-In Order Flow
1. **Customer scans table QR code**
   ```
   QR Data: http://yourapp.com/dine-in-menu?restaurantId=xxx&tableId=yyy
   ```

2. **App opens dine-in menu**
   - Shows only items with `menuTypes: ['dine_in']`
   - Uses `dineInPrice` instead of regular `price`
   - Customer ID is tracked in table session

3. **Customer places order**
   - Order type: `dine_in`
   - Linked to table and customer
   - No delivery fee

4. **Restaurant sees**
   - Which table ordered
   - Customer name/phone
   - Order details

### Delivery Order Flow
1. **Customer browses app**
   - Shows items with `menuTypes: ['delivery']`
   - Uses regular `price`

2. **Customer places order**
   - Order type: `delivery`
   - Includes delivery address
   - Delivery fee calculated by distance

## 📱 Frontend Implementation

### Scan Barcode (for restaurant staff)
```dart
// Scan barcode to quickly add item
final barcode = await scanBarcode(); // e.g., "PP00000001"
final food = await foodRepository.getFoodByBarcode(barcode);
// Add to order
```

### Filter by Menu Type
```dart
// Dine-in menu
final dineInFoods = await foodRepository.getFoodsByHotel(
  hotelId: restaurantId,
  menuType: 'dine_in'
);

// Delivery menu
final deliveryFoods = await foodRepository.getFoodsByHotel(
  hotelId: restaurantId,
  menuType: 'delivery'
);
```

### Show Correct Price
```dart
Widget buildFoodPrice(Food food, String orderType) {
  final price = orderType == 'dine_in' && food.dineInPrice != null
      ? food.dineInPrice
      : food.price;
  
  return Text('ETB $price');
}
```

## 🎨 UI Recommendations

### Dine-In Menu
- Show table number at top
- Display "Dine-In Price" badge
- Hide delivery-related info
- Show "Call Waiter" button

### Delivery Menu
- Show delivery fee
- Display estimated delivery time
- Show distance from restaurant
- Include delivery address input

### Restaurant Dashboard
- **Table View**: See all tables with current customers
- **Barcode Scanner**: Quick item lookup
- **Menu Management**: Toggle menu types per item

## 🔐 Security

### Customer Identification
When scanning table QR:
```javascript
// QR code is signed/encrypted
const qrData = {
  restaurantId: "xxx",
  tableId: "yyy",
  timestamp: Date.now(),
  signature: "..." // Prevents tampering
};
```

### Table Session
```javascript
{
  tableId: "T01",
  customerId: "user123",
  customerName: "John Doe",
  customerPhone: "+251911111111",
  startTime: "2024-01-15T10:30:00Z",
  orderIds: ["order1", "order2"],
  isOccupied: true
}
```

## 📊 Example Data

### Food with Barcode
```javascript
{
  name: "Margherita Pizza",
  price: 280,           // Delivery price
  dineInPrice: 250,     // Dine-in price (cheaper)
  barcode: "PP00000001",
  menuTypes: ["delivery", "dine_in", "takeaway"],
  hotelId: "...",
  hotelName: "Pizza Palace"
}
```

### Dine-In Order
```javascript
{
  type: "dine_in",
  tableId: "T05",
  restaurantId: "...",
  customerId: "user123",
  items: [...],
  totalPrice: 500,  // Uses dineInPrice
  deliveryFee: 0,   // No delivery for dine-in
  status: "confirmed"
}
```

## 🚀 Quick Start

1. **Seed database with barcodes**:
   ```bash
   npm run seed:barcodes
   ```

2. **Generate table QR codes**:
   ```bash
   npm run generate-qr
   ```

3. **Test barcode lookup**:
   ```bash
   curl http://localhost:5001/api/foods/barcode/PP00000001
   ```

4. **Test menu filtering**:
   ```bash
   curl http://localhost:5001/api/foods?menuType=dine_in
   ```

## 📝 Notes

- Barcodes are unique across all restaurants
- Menu types are arrays (food can be in multiple menus)
- Dine-in price is optional (falls back to regular price)
- Table sessions auto-close when order is completed
- Customer tracking respects privacy (only basic info)

## 🎯 Benefits

1. **Faster Service**: Scan barcode instead of searching
2. **Better Pricing**: Different prices for different service types
3. **Customer Tracking**: Know who's at which table
4. **Inventory Management**: Track popular items by barcode
5. **Flexible Menus**: Same item available in multiple service types
