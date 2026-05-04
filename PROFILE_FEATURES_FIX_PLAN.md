# Profile Features Fix Plan

## Issues Identified

Based on the screenshots and description, the following features are not working:

### 1. **My Orders Tab Not Working** ❌
**Problem:** 
- Shows "No active order" even when user has placed orders
- The Orders tab calls `OrderProvider.fetchOrders()` which requires authentication
- For guest users (dine-in without login), this fails silently

**Root Cause:**
- `OrderRepository.getAllOrders()` uses authenticated endpoint `/api/orders`
- Guest users don't have JWT tokens
- Dine-in orders are placed without login

**Solution:**
```dart
// In OrdersPage, check if user is logged in
// If not logged in but has active dine-in session, show dine-in order
// Otherwise, prompt to login

Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  final dineInProvider = Provider.of<DineInProvider>(context);
  
  // Check if user is guest with active dine-in order
  if (!authProvider.isAuthenticated && dineInProvider.hasActiveOrder) {
    return DineInOrderStatusView(); // Show dine-in order status
  }
  
  // Check if user is logged in
  if (!authProvider.isAuthenticated) {
    return LoginPromptView(); // Prompt to login
  }
  
  // User is logged in, show order history
  return OrderHistoryView();
}
```

### 2. **Favorites Not Working** ❌
**Problem:**
- Clicking heart icon doesn't add items to favorites
- No visual feedback when adding to favorites

**Root Cause:**
- Favorites feature may not be implemented
- Or requires authentication but guest users can't use it

**Solution:**
- Implement favorites functionality with local storage for guests
- Sync with backend when user logs in
- Add visual feedback (animation, snackbar)

### 3. **Profile Sections Not Working** ❌
**Problems:**
- Guest mode not handled properly
- Language change not working
- Comments/Reviews not accessible

**Root Cause:**
- Profile page assumes user is always logged in
- No guest mode UI
- Features require authentication

**Solution:**
- Add guest mode detection
- Show "Login to access" for auth-required features
- Allow language change without login
- Store preferences locally for guests

## Implementation Plan

### Phase 1: Fix Orders Tab (HIGH PRIORITY)

#### Step 1: Update OrdersPage to handle guest users
```dart
// frontend/lib/presentation/pages/orders/orders_page.dart

@override
Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final dineInProvider = Provider.of<DineInProvider>(context, listen: false);
  
  // Guest user with active dine-in order
  if (!authProvider.isAuthenticated) {
    if (dineInProvider.tableId != null && dineInProvider.restaurantId != null) {
      return OrderStatusPage(
        tableId: dineInProvider.tableId!,
        restaurantId: dineInProvider.restaurantId!,
      );
    }
    
    // Guest user without active order - prompt to login
    return _buildLoginPrompt();
  }
  
  // Logged in user - show order history
  return _buildOrderHistory();
}
```

#### Step 2: Create login prompt widget
```dart
Widget _buildLoginPrompt() {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('Login to view order history'),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Login'),
          ),
        ],
      ),
    ),
  );
}
```

### Phase 2: Implement Favorites (MEDIUM PRIORITY)

#### Step 1: Create FavoritesProvider
```dart
// frontend/lib/state/favorites/favorites_provider.dart

class FavoritesProvider extends ChangeNotifier {
  final Set<String> _favoriteFoodIds = {};
  final SharedPreferences _prefs;
  
  Set<String> get favoriteFoodIds => _favoriteFoodIds;
  
  Future<void> loadFavorites() async {
    final stored = _prefs.getStringList('favorites') ?? [];
    _favoriteFoodIds.addAll(stored);
    notifyListeners();
  }
  
  Future<void> toggleFavorite(String foodId) async {
    if (_favoriteFoodIds.contains(foodId)) {
      _favoriteFoodIds.remove(foodId);
    } else {
      _favoriteFoodIds.add(foodId);
    }
    await _prefs.setStringList('favorites', _favoriteFoodIds.toList());
    notifyListeners();
  }
  
  bool isFavorite(String foodId) => _favoriteFoodIds.contains(foodId);
}
```

#### Step 2: Update food cards to use favorites
```dart
// In food card widget
Consumer<FavoritesProvider>(
  builder: (context, favProvider, _) {
    final isFavorite = favProvider.isFavorite(food.id);
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.grey,
      ),
      onPressed: () {
        favProvider.toggleFavorite(food.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Removed from favorites' : 'Added to favorites'
            ),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  },
)
```

### Phase 3: Fix Profile Page (MEDIUM PRIORITY)

#### Step 1: Add guest mode detection
```dart
// frontend/lib/presentation/pages/profile/profile_page.dart

Widget build(BuildContext context) {
  final authProvider = Provider.of<AuthProvider>(context);
  
  if (!authProvider.isAuthenticated) {
    return _buildGuestProfile();
  }
  
  return _buildAuthenticatedProfile();
}
```

#### Step 2: Create guest profile view
```dart
Widget _buildGuestProfile() {
  return Scaffold(
    body: Column(
      children: [
        // Guest avatar
        CircleAvatar(
          radius: 50,
          child: Icon(Icons.person, size: 50),
        ),
        SizedBox(height: 16),
        Text('Guest User', style: TextStyle(fontSize: 20)),
        SizedBox(height: 32),
        
        // Available features for guests
        ListTile(
          leading: Icon(Icons.language),
          title: Text('Language'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/language'),
        ),
        ListTile(
          leading: Icon(Icons.help),
          title: Text('Help & Support'),
          trailing: Icon(Icons.chevron_right),
          onTap: () => Navigator.pushNamed(context, '/support'),
        ),
        
        Spacer(),
        
        // Login button
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('Login to access all features'),
          ),
        ),
      ],
    ),
  );
}
```

### Phase 4: Language Change (LOW PRIORITY)

#### Step 1: Ensure language selection works for guests
```dart
// frontend/lib/presentation/pages/language/language_selection_page.dart

// Language selection should work without authentication
// Store selected language in SharedPreferences
Future<void> _changeLanguage(String languageCode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('language', languageCode);
  
  // Update app locale
  // Restart app or update locale provider
}
```

## Files to Modify

1. **frontend/lib/presentation/pages/orders/orders_page.dart**
   - Add guest user detection
   - Show dine-in order status for guests with active orders
   - Show login prompt for guests without orders

2. **frontend/lib/state/favorites/favorites_provider.dart** (NEW)
   - Create favorites provider
   - Implement local storage
   - Add toggle favorite method

3. **frontend/lib/presentation/pages/profile/profile_page.dart**
   - Add guest mode detection
   - Create guest profile view
   - Separate auth-required features

4. **frontend/lib/presentation/widgets/food_card.dart**
   - Add favorite button
   - Connect to FavoritesProvider
   - Add visual feedback

5. **frontend/lib/main.dart**
   - Add FavoritesProvider to MultiProvider

## Testing Checklist

- [ ] Guest user can see active dine-in order in Orders tab
- [ ] Guest user sees login prompt when no active order
- [ ] Logged-in user sees order history
- [ ] Favorite button works and shows visual feedback
- [ ] Favorites persist after app restart
- [ ] Guest profile shows limited features
- [ ] Language change works for guests
- [ ] Login button navigates to login page

## Priority

1. **HIGH**: Fix Orders tab for guest users
2. **MEDIUM**: Implement favorites functionality
3. **MEDIUM**: Fix profile page guest mode
4. **LOW**: Ensure language change works

## Estimated Time

- Phase 1 (Orders): 2-3 hours
- Phase 2 (Favorites): 3-4 hours
- Phase 3 (Profile): 2-3 hours
- Phase 4 (Language): 1 hour

**Total**: 8-11 hours
