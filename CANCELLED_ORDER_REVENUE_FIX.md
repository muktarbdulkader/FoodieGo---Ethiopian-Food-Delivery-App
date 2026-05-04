# Cancelled Order Revenue Fix

## Issue
Cancelled orders were being counted in revenue calculations and statistics, inflating the reported revenue and order counts.

## Root Cause
Several aggregation queries in `backend/src/controllers/admin.controller.js` were missing the filter to exclude cancelled orders:
1. `topFoods` aggregation - included cancelled orders in top selling foods
2. `userStats` aggregation - included cancelled orders in user statistics
3. `totalOrders` count - included cancelled orders in total order count

## Fix Applied

### 1. Top Foods Aggregation (Line 85)
**Before:**
```javascript
const topFoods = await Order.aggregate([
  { $unwind: '$items' },
  { $match: { /* hotel filter */ } },
  // ... rest of aggregation
]);
```

**After:**
```javascript
const topFoods = await Order.aggregate([
  { $match: { status: { $ne: 'cancelled' } } },  // ✅ Added filter
  { $unwind: '$items' },
  { $match: { /* hotel filter */ } },
  // ... rest of aggregation
]);
```

### 2. User Stats Aggregation (Line 153)
**Before:**
```javascript
const userStats = await Order.aggregate([
  { $match: hotelFilter },
  { $group: { _id: '$user', orderCount: { $sum: 1 }, totalSpent: { $sum: '$totalPrice' } } }
]);
```

**After:**
```javascript
const userStats = await Order.aggregate([
  { $match: { ...hotelFilter, status: { $ne: 'cancelled' } } },  // ✅ Added filter
  { $group: { _id: '$user', orderCount: { $sum: 1 }, totalSpent: { $sum: '$totalPrice' } } }
]);
```

### 3. Total Orders Count (Line 28)
**Before:**
```javascript
const [totalFoods, totalOrders, pendingOrders, totalReviews] = await Promise.all([
  Food.countDocuments({ hotelId }),
  Order.countDocuments(hotelFilter),  // ❌ Included cancelled orders
  Order.countDocuments({ ...hotelFilter, status: 'pending' }),
  Review.countDocuments({ hotel: hotelId })
]);
```

**After:**
```javascript
const [totalFoods, totalOrders, pendingOrders, totalReviews] = await Promise.all([
  Food.countDocuments({ hotelId }),
  Order.countDocuments({ ...hotelFilter, status: { $ne: 'cancelled' } }),  // ✅ Excludes cancelled
  Order.countDocuments({ ...hotelFilter, status: 'pending' }),
  Review.countDocuments({ hotel: hotelId })
]);
```

## Already Correct
The following aggregations were already correctly excluding cancelled orders:
- ✅ `revenueStats` - Total revenue calculation (Line 35)
- ✅ `todayStats` - Today's revenue and orders (Line 58)
- ✅ `dailyRevenue` - Daily revenue chart data (Line 436)

## Impact
After this fix:
- **Revenue calculations** will only include completed/active orders
- **Order counts** will exclude cancelled orders
- **Top selling foods** will only show items from non-cancelled orders
- **User statistics** (order count, total spent) will exclude cancelled orders

## Testing
To verify the fix:
1. Create a test order and cancel it
2. Check the admin dashboard statistics
3. Verify that:
   - Total revenue does NOT include the cancelled order amount
   - Total orders count does NOT include the cancelled order
   - Top foods do NOT include items from cancelled orders
   - User stats do NOT include the cancelled order

## Files Modified
- `backend/src/controllers/admin.controller.js`

## Related
This fix is part of the real-time order system implementation and ensures accurate business metrics.
