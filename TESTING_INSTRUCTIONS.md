# Testing Instructions for Dine-In QR Code Scanning

## The Problem You're Experiencing

When you scan a QR code or open the app, you're seeing:
- 401 Unauthorized errors for `/api/admin/dashboard` and `/api/events/hotel-bookings`
- The app is trying to load the admin dashboard instead of the dine-in menu
- Deep link shows as `http://localhost:60621/` instead of the actual menu URL

## Root Cause

You're testing on **localhost** (`http://localhost:60621/`), but your QR codes point to the **production Firebase URL** (`https://foodiego-99b1e.web.app/dine-in-menu?restaurantId=xxx&tableId=xxx`).

Deep links only work properly when:
1. The URL in the QR code matches the domain where the app is hosted
2. The app is deployed to that domain (not running on localhost)

## Solution: Test on Production

### Option 1: Test with Production Deployment (Recommended)

1. **Deploy your latest changes to Firebase**:
   ```bash
   cd frontend
   flutter build web
   firebase deploy --only hosting
   ```

2. **Open the production URL** in your browser or mobile device:
   ```
   https://foodiego-99b1e.web.app
   ```

3. **Scan a QR code** or manually navigate to a table URL:
   ```
   https://foodiego-99b1e.web.app/dine-in-menu?restaurantId=YOUR_RESTAURANT_ID&tableId=T01
   ```

4. **Expected behavior**:
   - App opens directly to the dine-in menu
   - Foods are loaded and displayed
   - No 401 errors
   - Prices show correctly with ETB currency

### Option 2: Test Locally with Manual Navigation

If you want to test on localhost, you need to manually navigate to the dine-in menu URL:

1. **Start your development server**:
   ```bash
   cd frontend
   flutter run -d chrome
   ```

2. **Manually navigate to the dine-in menu** in the browser address bar:
   ```
   http://localhost:XXXX/dine-in-menu?restaurantId=YOUR_RESTAURANT_ID&tableId=T01
   ```
   Replace `XXXX` with your actual port number and `YOUR_RESTAURANT_ID` with a real restaurant ID from your database.

3. **This will bypass the deep link issue** and directly load the dine-in menu page.

### Option 3: Build and Test APK

For the most accurate testing (especially for deep links), build and install the APK:

1. **Build the APK**:
   ```bash
   cd frontend
   flutter build apk --release
   ```

2. **Install on your Android device**:
   ```bash
   flutter install
   ```

3. **Scan a QR code** with your device camera or a QR scanner app
   - The QR code should open your app directly to the dine-in menu
   - Deep links will work correctly in the APK

## How to Get Your Restaurant ID

You need a valid restaurant ID from your database. You can get it by:

1. **Check your backend logs** when an admin logs in
2. **Query MongoDB directly**:
   ```javascript
   db.users.find({ role: 'restaurant' }, { _id: 1, hotelName: 1 })
   ```
3. **Use the admin dashboard** - the restaurant ID is the user's `_id`

## Verifying the Fix

Once you're testing on production or with the correct URL, you should see:

✅ **No 401 errors** - The dine-in menu doesn't require authentication  
✅ **Foods load correctly** - Filtered by `menuType: 'dine_in'`  
✅ **Prices display** - Shows "ETB XX.XX" format  
✅ **Categories work** - Can filter by food category  
✅ **Add to cart works** - Can add items to cart  

## Common Issues

### Issue: "No menu items available"

**Cause**: No foods have `'dine_in'` in their `menuTypes` array

**Solution**: Add foods with dine-in menu type:
1. Log in as admin
2. Go to "Manage Foods"
3. Add a new food
4. Check the "Dine-In" checkbox under "Available For"
5. Save

### Issue: Still getting 401 errors on production

**Cause**: The app is trying to load admin dashboard instead of dine-in menu

**Solution**: 
1. Clear browser cache and cookies
2. Make sure you're using the full URL with query parameters:
   ```
   https://foodiego-99b1e.web.app/dine-in-menu?restaurantId=XXX&tableId=T01
   ```
3. Check that the QR code contains the correct URL

### Issue: Deep links not working in APK

**Cause**: AndroidManifest.xml might not have the correct domain

**Solution**: Verify `AndroidManifest.xml` has:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="https"
        android:host="foodiego-99b1e.web.app" />
</intent-filter>
```

## Next Steps

1. Deploy to Firebase: `flutter build web && firebase deploy --only hosting`
2. Test on production: `https://foodiego-99b1e.web.app/dine-in-menu?restaurantId=XXX&tableId=T01`
3. If it works, build and test the APK
4. Scan QR codes with your mobile device

## Need Help?

If you're still experiencing issues after following these steps:
1. Check the browser console for errors
2. Verify your restaurant ID is correct
3. Ensure foods have `'dine_in'` in their `menuTypes` array
4. Check that the backend is running at `https://foodiego-tqz4.onrender.com`
