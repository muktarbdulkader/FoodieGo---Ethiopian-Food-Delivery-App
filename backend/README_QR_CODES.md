# 🍽️ QR Code Dine-In System - Quick Reference

## 🎯 What is This?

A system where customers scan QR codes on restaurant tables to order food directly through the app.

---

## 🚀 Quick Start (3 Steps)

### 1. Open Web Generator
```bash
# Open this file in your browser:
backend/generate-qr.html
```

### 2. Fill Form & Generate
- Enter your Restaurant ID
- Enter number of tables (e.g., 10)
- Click "Generate QR Codes"

### 3. Print & Place
- Download QR codes
- Print on cardstock
- Laminate and place on tables

**Done!** 🎉

---

## 📋 How It Works

### Restaurant Side:
1. Create tables in system
2. Generate QR codes
3. Print and place on tables
4. Receive orders with table numbers

### Customer Side:
1. Scan QR code at table
2. Browse menu in app
3. Order food
4. Track order status

---

## 🛠️ Files Created

| File | Purpose |
|------|---------|
| `generate-qr.html` | Web-based QR generator (easiest) |
| `src/utils/generate-qr-codes.js` | Command-line QR generator |
| `QR_CODE_SETUP_GUIDE.md` | Detailed setup instructions |
| `QUICK_START_QR.md` | Quick start guide |
| `HOW_QR_SYSTEM_WORKS.md` | Complete system explanation |

---

## 📡 API Endpoints

### Create Tables
```bash
POST /api/tables/bulk
Authorization: Bearer <restaurant-token>
Body: { "count": 10, "prefix": "T", "capacity": 4 }
```

### Get Tables
```bash
GET /api/tables
Authorization: Bearer <restaurant-token>
```

### Get Table by QR (Customer)
```bash
GET /api/tables/qr?restaurantId=XXX&tableId=YYY
Authorization: Bearer <customer-token>
```

### Place Dine-In Order
```bash
POST /api/orders
Authorization: Bearer <customer-token>
Body: {
  "type": "dine_in",
  "tableId": "XXX",
  "restaurantId": "YYY",
  "items": [...]
}
```

---

## 🔗 QR Code Format

Each QR code contains:
```
foodiego://menu?restaurantId=<ID>&tableId=<ID>
```

When scanned:
1. App opens
2. Loads restaurant menu
3. Shows table number
4. Customer can order

---

## 📱 Customer Flow

```
Scan QR → App Opens → Menu Loads → Add to Cart → Place Order → Track Status
```

---

## 🏪 Restaurant Flow

```
Create Tables → Generate QR → Print → Place on Tables → Receive Orders
```

---

## 💡 Tips

✅ Test all QR codes before launch
✅ Laminate for durability
✅ Size: 10cm x 10cm recommended
✅ Add "Scan to Order" text
✅ Train staff on system

---

## 📚 Need More Help?

- **Quick Start**: `QUICK_START_QR.md`
- **Detailed Guide**: `QR_CODE_SETUP_GUIDE.md`
- **How It Works**: `HOW_QR_SYSTEM_WORKS.md`
- **Full Implementation**: `../DINE_IN_IMPLEMENTATION_GUIDE.md`

---

## 🎨 Example QR Code Design

```
┌─────────────────────┐
│  Pizza Palace       │
│                     │
│  Scan to Order      │
│                     │
│  [QR CODE HERE]     │
│                     │
│  Table: T01         │
│  Seats: 4           │
└─────────────────────┘
```

---

**Ready to launch your dine-in ordering system!** 🚀
