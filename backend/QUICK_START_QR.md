# Quick Start: Generate QR Codes for Your Restaurant

## Method 1: Web-Based Generator (Easiest) ⭐

1. **Open the HTML file**
   ```bash
   # Just open this file in your browser:
   backend/generate-qr.html
   ```

2. **Fill in the form:**
   - Restaurant ID: Get this from your database or API
   - Restaurant Name: Your restaurant name
   - Number of Tables: How many tables you have
   - Table Prefix: Usually "T" for Table
   - Capacity: Default seats per table

3. **Click "Generate QR Codes"**
   - QR codes will appear on the page
   - Download individual QR codes
   - Or click "Print All" to print them all

4. **Done!** 🎉

---

## Method 2: Command Line (For Existing Tables)

If you already created tables in the database:

1. **Install dependencies**
   ```bash
   cd backend
   npm install
   ```

2. **Get your restaurant ID**
   ```bash
   # Login to get your restaurant ID
   # Or check MongoDB directly
   ```

3. **Generate QR codes**
   ```bash
   npm run generate-qr <YOUR_RESTAURANT_ID>
   ```

4. **Find your QR codes**
   ```
   backend/qr-codes/
   ├── table-T01.png
   ├── table-T02.png
   ├── table-T03.png
   └── print-qr-codes.html  ← Open this to print all
   ```

---

## Method 3: API + Web Generator

1. **Create tables via API**
   ```bash
   # Login as restaurant
   curl -X POST http://localhost:5000/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "your-restaurant@example.com",
       "password": "your-password"
     }'
   
   # Save the token from response
   
   # Create 10 tables
   curl -X POST http://localhost:5000/api/tables/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "count": 10,
       "prefix": "T",
       "capacity": 4,
       "location": "Main hall"
     }'
   ```

2. **Get your tables**
   ```bash
   curl -X GET http://localhost:5000/api/tables \
     -H "Authorization: Bearer YOUR_TOKEN"
   ```

3. **Use the web generator**
   - Open `backend/generate-qr.html`
   - Enter your restaurant ID
   - Generate QR codes

---

## What Customers See

When a customer scans the QR code:

1. **App Opens** (or prompts to install)
2. **Restaurant Menu Loads** automatically
3. **Table Number Shows** at the top
4. **Customer Can:**
   - Browse menu
   - Add items to cart
   - Place order
   - Call waiter
   - View order status

---

## Printing Tips

### Option 1: Individual Cards
- Print each QR code on cardstock
- Laminate for durability
- Size: 10cm x 10cm (4" x 4")

### Option 2: Table Tents
- Fold cardstock in half
- QR code on both sides
- Add restaurant logo and instructions

### Option 3: Stickers
- Print on sticker paper
- Stick directly on tables
- Easy to replace

### Recommended Design:
```
┌─────────────────────┐
│  [Restaurant Logo]  │
│                     │
│   Scan to Order     │
│                     │
│   [QR CODE HERE]    │
│                     │
│   Table: T01        │
│   Capacity: 4       │
└─────────────────────┘
```

---

## Testing

1. **Generate a test QR code**
2. **Scan with your phone**
3. **Verify:**
   - App opens correctly
   - Restaurant loads
   - Table number is correct
   - Menu is accessible

---

## Troubleshooting

### QR Code doesn't scan
- Ensure good lighting
- Clean the surface
- Try different angles
- Check if QR code is damaged

### Wrong restaurant loads
- Verify restaurant ID is correct
- Check if table exists in database
- Regenerate QR code

### App doesn't open
- Check deep link configuration
- Verify app is installed
- Test with different QR scanner

---

## Next Steps

1. ✅ Generate QR codes
2. ✅ Print and laminate
3. ✅ Place on tables
4. ✅ Test with staff
5. ✅ Train staff on system
6. ✅ Launch to customers!

---

## Support

Need help? Check:
- `QR_CODE_SETUP_GUIDE.md` - Detailed guide
- `DINE_IN_IMPLEMENTATION_GUIDE.md` - Full system docs
- API documentation for table endpoints

---

## Example: Complete Flow

```bash
# 1. Install dependencies
cd backend
npm install

# 2. Create tables
curl -X POST http://localhost:5000/api/tables/bulk \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"count": 20, "prefix": "T", "capacity": 4}'

# 3. Generate QR codes
npm run generate-qr YOUR_RESTAURANT_ID

# 4. Open the HTML file
open qr-codes/print-qr-codes.html

# 5. Print!
```

That's it! Your dine-in ordering system is ready! 🎉
