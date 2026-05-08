/// App Localizations - Multi-language support
/// Supports: English (en), Afaan Oromoo (om), Amharic (am)
library app_localizations;

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _translations = {
    'en': _englishTranslations,
    'om': _oromoTranslations,
    'am': _amharicTranslations,
  };

  String get(String key) {
    return _translations[languageCode]?[key] ??
        _translations['en']?[key] ??
        key;
  }

  // Common translations
  String get appName => get('app_name');
  String get welcomeBack => get('welcome_back');
  String get signIn => get('sign_in');
  String get signUp => get('sign_up');
  String get email => get('email');
  String get password => get('password');
  String get forgotPassword => get('forgot_password');
  String get dontHaveAccount => get('dont_have_account');
  String get alreadyHaveAccount => get('already_have_account');
  String get fullName => get('full_name');
  String get phone => get('phone');
  String get createAccount => get('create_account');
  String get logout => get('logout');
  String get profile => get('profile');
  String get settings => get('settings');
  String get language => get('language');
  String get home => get('home');
  String get orders => get('orders');
  String get cart => get('cart');
  String get favorites => get('favorites');
  String get addresses => get('addresses');
  String get notifications => get('notifications');
  String get helpSupport => get('help_support');
  String get contactUs => get('contact_us');
  String get myOrders => get('my_orders');
  String get myEvents => get('my_events');
  String get paymentMethods => get('payment_methods');
  String get accountSettings => get('account_settings');
  String get selectLanguage => get('select_language');
  String get continueText => get('continue');
  String get cancel => get('cancel');
  String get confirm => get('confirm');
  String get delete => get('delete');
  String get edit => get('edit');
  String get save => get('save');
  String get search => get('search');
  String get noResults => get('no_results');
  String get loading => get('loading');
  String get error => get('error');
  String get success => get('success');
  String get retry => get('retry');
  String get coupons => get('coupons');
  String get wallet => get('wallet');
  String get level => get('level');
  String get regular => get('regular');
  String get myAccount => get('my_account');
  String get more => get('more');

  // Login/Register page
  String get signInToContinue => get('sign_in_to_continue');
  String get deliciousFood => get('delicious_food');
  String get emailAddress => get('email_address');
  String get invalidEmail => get('invalid_email');
  String get required => get('required');
  String get phoneNumber => get('phone_number');
  String get address => get('address');
  String get registerSuccess => get('register_success');

  // Home page
  String get searchFood => get('search_food');
  String get popularFoods => get('popular_foods');
  String get allFoods => get('all_foods');
  String get categories => get('categories');
  String get seeAll => get('see_all');
  String get nearbyRestaurants => get('nearby_restaurants');
  String get deliverTo => get('deliver_to');
  String get currentLocation => get('current_location');

  // Food detail
  String get addToCart => get('add_to_cart');
  String get description => get('description');
  String get price => get('price');
  String get quantity => get('quantity');
  String get reviews => get('reviews');
  String get writeReview => get('write_review');
  String get rating => get('rating');
  String get minutes => get('minutes');
  String get views => get('views');
  String get likes => get('likes');

  // Cart page
  String get yourCart => get('your_cart');
  String get emptyCart => get('empty_cart');
  String get subtotal => get('subtotal');
  String get deliveryFee => get('delivery_fee');
  String get total => get('total');
  String get checkout => get('checkout');
  String get clearCart => get('clear_cart');
  String get removeItem => get('remove_item');

  // Orders page
  String get noOrders => get('no_orders');
  String get orderStatus => get('order_status');
  String get pending => get('pending');
  String get confirmed => get('confirmed');
  String get preparing => get('preparing');
  String get onTheWay => get('on_the_way');
  String get delivered => get('delivered');
  String get cancelled => get('cancelled');
  String get trackOrder => get('track_order');
  String get orderDetails => get('order_details');
  String get orderDate => get('order_date');
  String get orderTotal => get('order_total');

  // Checkout page
  String get deliveryAddress => get('delivery_address');
  String get paymentMethod => get('payment_method');
  String get cashOnDelivery => get('cash_on_delivery');
  String get placeOrder => get('place_order');
  String get orderPlaced => get('order_placed');
  String get orderConfirmed => get('order_confirmed');

  // Profile page
  String get editProfile => get('edit_profile');
  String get changePassword => get('change_password');
  String get deleteAccount => get('delete_account');
  String get currentPassword => get('current_password');
  String get newPassword => get('new_password');
  String get confirmPassword => get('confirm_password');
  String get saveChanges => get('save_changes');
  String get profileUpdated => get('profile_updated');
  String get passwordChanged => get('password_changed');

  // Wallet
  String get walletBalance => get('wallet_balance');
  String get topUp => get('top_up');
  String get transactions => get('transactions');
  String get noTransactions => get('no_transactions');
  
  // Checkout page - Extended
  String get completeYourOrder => get('complete_your_order');
  String get deliveryMethod => get('delivery_method');
  String get delivery => get('delivery');
  String get pickup => get('pickup');
  String get free => get('free');
  String get deliveryLocation => get('delivery_location');
  String get autoDetected => get('auto_detected');
  String get locationFound => get('location_found');
  String get locationNotAvailable => get('location_not_available');
  String get tapToEnable => get('tap_to_enable');
  String get gettingLocation => get('getting_location');
  String get deliveryInstructions => get('delivery_instructions');
  String get deliveryInstructionsHint => get('delivery_instructions_hint');
  String get completePayment => get('complete_payment');
  String get checkYourPhone => get('check_your_phone');
  String get paymentPromptSent => get('payment_prompt_sent');
  String get enterPinToAuthorize => get('enter_pin_to_authorize');
  String get paymentProcessedInstantly => get('payment_processed_instantly');
  String get iPaid => get('i_paid');
  String get arrivingSoon => get('arriving_soon');
  String get readyForPickup => get('ready_for_pickup');
  String get arrivingIn => get('arriving_in');
  String get readyIn => get('ready_in');
  String get promoCode => get('promo_code');
  String get enterPromoCode => get('enter_promo_code');
  String get apply => get('apply');
  String get youSave => get('you_save');
  String get addATip => get('add_a_tip');
  String get showAppreciation => get('show_appreciation');
  String get none => get('none');
  String get tax => get('tax');
  String get tip => get('tip');
  String get discount => get('discount');
  String get pleaseEnterPhone => get('please_enter_phone');
  String get pleaseEnableLocation => get('please_enable_location');
  String get telebirr => get('telebirr');
  String get mpesa => get('mpesa');
  String get cbeBirr => get('cbe_birr');
  String get cash => get('cash');
  String get card => get('card');
  String get payWith => get('pay_with');
  String get creditDebitCard => get('credit_debit_card');
  String get cashOnDeliveryDesc => get('cash_on_delivery_desc');
  String get visaMastercard => get('visa_mastercard');
  String get table => get('table');
  String get restaurantMenu => get('restaurant_menu');

  // Order Status Page
  String get callWaiter => get('call_waiter');
  String get placeNewOrder => get('place_new_order');
  String get noActiveOrder => get('no_active_order');
  String get placeOrderFirst => get('place_order_first');
  String get orderPlacedLabel => get('order_placed_label');
  String get accepted => get('accepted');
  String get ready => get('ready');
  String get served => get('served');
  String get orderCancelled => get('order_cancelled');
  String get contactWaiter => get('contact_waiter');
  String get callingWaiter => get('calling_waiter');
  String get waiterNotified => get('waiter_notified');
  String get failedCallWaiter => get('failed_call_waiter');

  // Bill Page
  String get yourBill => get('your_bill');
  String get noActiveOrderBill => get('no_active_order_bill');
  String get addItemsFirst => get('add_items_first');
  String get orderItems => get('order_items');
  String get paymentOptions => get('payment_options');
  String get requestBill => get('request_bill');
  String get waiterNotifiedBill => get('waiter_notified_bill');
  String get billPaid => get('bill_paid');
  String get thankYouDining => get('thank_you_dining');
  String get payCashWaiter => get('pay_cash_waiter');

  // Orders Page
  String get allOrders => get('all_orders');
  String get inProgress => get('in_progress');
  String get completedLabel => get('completed_label');
  String get noOrdersYet => get('no_orders_yet');
  String get startOrdering => get('start_ordering');
  String get browseMenu => get('browse_menu');
  String get orderNumber => get('order_number');
  String get items => get('items');
  String get viewDetails => get('view_details');
  String get track => get('track');

  // Home Page
  String get searchCuisines => get('search_cuisines');
  String get goodMorning => get('good_morning');
  String get goodAfternoon => get('good_afternoon');
  String get goodEvening => get('good_evening');
  String get whatToEat => get('what_to_eat');
  String get all => get('all');
  String get restaurants => get('restaurants');
  String get featured => get('featured');
  String get topRated => get('top_rated');
  String get openNow => get('open_now');

  // Dine-in Menu Page
  String get dineInMenu => get('dine_in_menu');
  String get searchMenuItems => get('search_menu_items');
  String get allItems => get('all_items');
  String get addedToCart => get('added_to_cart');
  String get noItemsFound => get('no_items_found');
  String get tryDifferentSearch => get('try_different_search');
  String get menu => get('menu');
  String get dineInSubtitle => get('dine_in_subtitle');

  // Food Detail Page
  String get addToOrder => get('add_to_order');
  String get specialInstructions => get('special_instructions');
  String get specialInstructionsHint => get('special_instructions_hint');
  String get doneness => get('doneness');
  String get removals => get('removals');
  String get premiumAddOns => get('premium_add_ons');
  String get signature => get('signature');
  String get chefsChoice => get('chefs_choice');
  String get vegetarian => get('vegetarian');
  String get spicy => get('spicy');
  String get prepTime => get('prep_time');
  String get calories => get('calories');
}

// English Translations
const Map<String, String> _englishTranslations = {
  'app_name': 'FoodieGo',
  'welcome_back': 'Welcome Back!',
  'sign_in': 'Sign In',
  'sign_up': 'Sign Up',
  'email': 'Email',
  'password': 'Password',
  'forgot_password': 'Forgot Password?',
  'dont_have_account': "Don't have an account?",
  'already_have_account': 'Already have an account?',
  'full_name': 'Full Name',
  'phone': 'Phone Number',
  'create_account': 'Create Account',
  'logout': 'Logout',
  'profile': 'Profile',
  'settings': 'Settings',
  'language': 'Language',
  'home': 'Home',
  'orders': 'Orders',
  'cart': 'Cart',
  'favorites': 'Favorites',
  'addresses': 'Addresses',
  'notifications': 'Notifications',
  'help_support': 'Help & Support',
  'contact_us': 'Contact Us',
  'my_orders': 'My Orders',
  'my_events': 'My Events',
  'payment_methods': 'Payment Methods',
  'account_settings': 'Account Settings',
  'select_language': 'Select Language',
  'continue': 'Continue',
  'cancel': 'Cancel',
  'confirm': 'Confirm',
  'delete': 'Delete',
  'edit': 'Edit',
  'save': 'Save',
  'search': 'Search',
  'no_results': 'No results found',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'retry': 'Retry',
  'coupons': 'Coupons',
  'wallet': 'Wallet',
  'level': 'Level',
  'regular': 'Regular',
  'my_account': 'My Account',
  'more': 'More',
  // Login/Register
  'sign_in_to_continue': 'Sign in to continue',
  'delicious_food': 'Delicious food at your doorstep',
  'email_address': 'Email Address',
  'invalid_email': 'Invalid email',
  'required': 'Required',
  'phone_number': 'Phone Number',
  'address': 'Address',
  'register_success': 'Registration successful',
  // Home
  'search_food': 'Search for food...',
  'popular_foods': 'Popular Foods',
  'all_foods': 'All Foods',
  'categories': 'Categories',
  'see_all': 'See All',
  'nearby_restaurants': 'Nearby Restaurants',
  'deliver_to': 'Deliver to',
  'current_location': 'Current Location',
  // Food detail
  'add_to_cart': 'Add to Cart',
  'description': 'Description',
  'price': 'Price',
  'quantity': 'Quantity',
  'reviews': 'Reviews',
  'write_review': 'Write a Review',
  'rating': 'Rating',
  'minutes': 'Minutes',
  'views': 'Views',
  'likes': 'Likes',
  // Cart
  'your_cart': 'Your Cart',
  'empty_cart': 'Your cart is empty',
  'subtotal': 'Subtotal',
  'delivery_fee': 'Delivery Fee',
  'total': 'Total',
  'checkout': 'Checkout',
  'clear_cart': 'Clear Cart',
  'remove_item': 'Remove Item',
  // Orders
  'no_orders': 'No orders yet',
  'order_status': 'Order Status',
  'pending': 'Pending',
  'confirmed': 'Confirmed',
  'preparing': 'Preparing',
  'on_the_way': 'On the Way',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
  'track_order': 'Track Order',
  'order_details': 'Order Details',
  'order_date': 'Order Date',
  'order_total': 'Order Total',
  // Checkout
  'delivery_address': 'Delivery Address',
  'payment_method': 'Payment Method',
  'cash_on_delivery': 'Cash on Delivery',
  'place_order': 'Place Order',
  'order_placed': 'Order Placed!',
  'order_confirmed': 'Your order has been confirmed',
  // Profile
  'edit_profile': 'Edit Profile',
  'change_password': 'Change Password',
  'delete_account': 'Delete Account',
  'current_password': 'Current Password',
  'new_password': 'New Password',
  'confirm_password': 'Confirm Password',
  'save_changes': 'Save Changes',
  'profile_updated': 'Profile updated successfully',
  'password_changed': 'Password changed successfully',
  // Wallet
  'wallet_balance': 'Wallet Balance',
  'top_up': 'Top Up',
  'transactions': 'Transactions',
  'no_transactions': 'No transactions yet',
  // Checkout - Extended
  'complete_your_order': 'Complete your order',
  'delivery_method': 'Delivery Method',
  'delivery': 'Delivery',
  'pickup': 'Pickup',
  'free': 'Free',
  'delivery_location': 'Delivery Location',
  'auto_detected': 'Auto-detected from your device',
  'location_found': 'Location Found',
  'location_not_available': 'Location not available',
  'tap_to_enable': 'Tap to enable location',
  'getting_location': 'Getting your location...',
  'delivery_instructions': 'Delivery Instructions (Optional)',
  'delivery_instructions_hint': 'E.g., Ring doorbell, leave at door...',
  'complete_payment': 'Complete Payment',
  'check_your_phone': 'Check Your Phone',
  'payment_prompt_sent': 'Payment prompt sent to your phone',
  'enter_pin_to_authorize': 'Enter your PIN to authorize',
  'payment_processed_instantly': 'Payment will be processed instantly',
  'i_paid': 'I Paid',
  'arriving_soon': 'Arriving Soon',
  'ready_for_pickup': 'Ready for Pickup',
  'arriving_in': 'Arriving in',
  'ready_in': 'Ready in',
  'promo_code': 'Promo Code',
  'enter_promo_code': 'Enter promo code',
  'apply': 'Apply',
  'you_save': 'You save',
  'add_a_tip': 'Add a Tip',
  'show_appreciation': 'Show appreciation for your delivery driver 💝',
  'none': 'None',
  'tax': 'Tax',
  'tip': 'Tip',
  'discount': 'Discount',
  'please_enter_phone': 'Please enter your phone number',
  'please_enable_location': 'Please enable location to continue',
  'telebirr': 'Telebirr',
  'mpesa': 'M-Pesa',
  'cbe_birr': 'CBE Birr',
  'cash': 'Cash',
  'card': 'Card',
  'pay_with': 'Pay with',
  'credit_debit_card': 'Credit/Debit Card',
  'cash_on_delivery_desc': 'Pay when you receive',
  'visa_mastercard': 'Visa, Mastercard',
  'table': 'Table',
  'restaurant_menu': 'Restaurant Menu',
  // Order Status Page
  'call_waiter': 'Call Waiter',
  'place_new_order': 'Place New Order',
  'no_active_order': 'No active order',
  'place_order_first': 'Place an order to see status here',
  'order_placed_label': 'Order Placed',
  'accepted': 'Accepted',
  'ready': 'Ready',
  'served': 'Served',
  'order_cancelled': 'Order Cancelled',
  'contact_waiter': 'Please contact the waiter for assistance',
  'calling_waiter': 'Calling waiter...',
  'waiter_notified': 'Waiter has been notified!',
  'failed_call_waiter': 'Failed to call waiter',
  // Bill Page
  'your_bill': 'Your Bill',
  'no_active_order_bill': 'No active order',
  'add_items_first': 'Place an order first to see your bill',
  'order_items': 'Order Items',
  'payment_options': 'Payment Options',
  'request_bill': 'Request Bill',
  'waiter_notified_bill': 'Waiter Notified ✓',
  'bill_paid': 'Bill Paid',
  'thank_you_dining': 'Thank you for dining with us!',
  'pay_cash_waiter': 'Pay cash to the waiter',
  // Orders Page
  'all_orders': 'All Orders',
  'in_progress': 'In Progress',
  'completed_label': 'Completed',
  'no_orders_yet': 'No orders yet',
  'start_ordering': 'Start ordering delicious food!',
  'browse_menu': 'Browse Menu',
  'order_number': 'Order',
  'items': 'items',
  'view_details': 'View Details',
  'track': 'Track',
  // Home Page
  'search_cuisines': 'Search cuisines, restaurants...',
  'good_morning': 'Good Morning',
  'good_afternoon': 'Good Afternoon',
  'good_evening': 'Good Evening',
  'what_to_eat': 'What would you like to eat?',
  'all': 'All',
  'restaurants': 'Restaurants',
  'featured': 'Featured',
  'top_rated': 'Top Rated',
  'open_now': 'Open Now',
  // Dine-in Menu
  'dine_in_menu': 'Dine-in Menu',
  'search_menu_items': 'Search menu items...',
  'all_items': 'All Items',
  'added_to_cart': 'added to cart',
  'no_items_found': 'No items found',
  'try_different_search': 'Try a different search or category',
  'menu': 'Menu',
  'dine_in_subtitle': 'Dine-in Menu',
  // Food Detail
  'add_to_order': 'Add to Order',
  'special_instructions': 'Special Instructions',
  'special_instructions_hint': 'Any allergies or special requests?',
  'doneness': 'Doneness',
  'removals': 'Removals',
  'premium_add_ons': 'Premium Add-ons',
  'signature': 'SIGNATURE',
  'chefs_choice': "CHEF'S CHOICE",
  'vegetarian': 'Vegetarian',
  'spicy': 'Spicy',
  'prep_time': 'Prep Time',
  'calories': 'Calories',
};

// Afaan Oromoo Translations
const Map<String, String> _oromoTranslations = {
  'app_name': 'FoodieGo',
  'welcome_back': 'Baga Nagaan Dhufte!',
  'sign_in': 'Seeni',
  'sign_up': "Galmaa'i",
  'email': 'Imeelii',
  'password': 'Jecha Iccitii',
  'forgot_password': 'Jecha Iccitii Dagatte?',
  'dont_have_account': "Herrega hin qabduu?",
  'already_have_account': 'Duraan herrega qabdaa?',
  'full_name': 'Maqaa Guutuu',
  'phone': 'Lakkoofsa Bilbilaa',
  'create_account': 'Herrega Banachuu',
  'logout': "Ba'i",
  'profile': 'Eenyummaa',
  'settings': "Qindaa'ina",
  'language': 'Afaan',
  'home': 'Mana',
  'orders': 'Ajajawwan',
  'cart': 'Gaarii',
  'favorites': 'Jaallatamoo',
  'addresses': 'Teessoo',
  'notifications': 'Beeksisa',
  'help_support': 'Gargaarsa',
  'contact_us': 'Nu Quunnamaa',
  'my_orders': 'Ajaja Koo',
  'my_events': 'Sagantaa Koo',
  'payment_methods': 'Mala Kaffaltii',
  'account_settings': "Qindaa'ina Herregaa",
  'select_language': 'Afaan Filadhu',
  'continue': "Itti Fufi",
  'cancel': 'Haqi',
  'confirm': "Mirkaneessi",
  'delete': 'Haqi',
  'edit': 'Gulaali',
  'save': "Olkaa'i",
  'search': 'Barbaadi',
  'no_results': "Bu'aan hin argamne",
  'loading': "Soqaa jira...",
  'error': 'Dogoggora',
  'success': "Milkaa'e",
  'retry': "Irra deebi'i",
  'coupons': 'Kuupoonii',
  'wallet': 'Waleetii',
  'level': 'Sadarkaa',
  'regular': 'Idilee',
  'my_account': 'Herrega Koo',
  'more': 'Dabalata',
  // Login/Register
  'sign_in_to_continue': 'Itti fufuuf seeni',
  'delicious_food': 'Nyaata midhagaa balbala kee irratti',
  'email_address': 'Teessoo Imeelii',
  'invalid_email': 'Imeelii sirrii miti',
  'required': 'Barbaachisaa',
  'phone_number': 'Lakkoofsa Bilbilaa',
  'address': 'Teessoo',
  'register_success': "Galmaa'uun milkaa'e",
  // Home
  'search_food': 'Nyaata barbaadi...',
  'popular_foods': 'Nyaata Beekamaa',
  'all_foods': 'Nyaata Hunda',
  'categories': 'Ramaddii',
  'see_all': 'Hunda Ilaali',
  'nearby_restaurants': "Mana Nyaataa Dhiyoo",
  'deliver_to': 'Geessuu',
  'current_location': "Bakka Ammaa",
  // Food detail
  'add_to_cart': 'Gaaritti Dabali',
  'description': 'Ibsa',
  'price': 'Gatii',
  'quantity': 'Baayina',
  'reviews': 'Yaadawwan',
  'write_review': 'Yaada Barreessi',
  'rating': 'Sadarkaa',
  'minutes': 'Daqiiqaa',
  'views': "Ilaalcha",
  'likes': 'Jaalala',
  // Cart
  'your_cart': 'Gaarii Kee',
  'empty_cart': 'Gaariin kee duwwaa dha',
  'subtotal': 'Ida\'amaa',
  'delivery_fee': 'Kaffaltii Geejjibaa',
  'total': 'Waliigala',
  'checkout': 'Kaffali',
  'clear_cart': 'Gaarii Haqi',
  'remove_item': 'Wanta Haqi',
  // Orders
  'no_orders': 'Ajajni hin jiru',
  'order_status': 'Haala Ajajaa',
  'pending': "Eegaa jira",
  'confirmed': "Mirkanaa'e",
  'preparing': 'Qophaa\'aa jira',
  'on_the_way': 'Karaa irra jira',
  'delivered': "Geeffame",
  'cancelled': 'Haqame',
  'track_order': 'Ajaja Hordofi',
  'order_details': 'Ibsa Ajajaa',
  'order_date': 'Guyyaa Ajajaa',
  'order_total': 'Waliigala Ajajaa',
  // Checkout
  'delivery_address': 'Teessoo Geejjibaa',
  'payment_method': 'Mala Kaffaltii',
  'cash_on_delivery': 'Qarshii Yeroo Geeffamu',
  'place_order': 'Ajaja Galchi',
  'order_placed': 'Ajajni Galche!',
  'order_confirmed': "Ajajni kee mirkanaa'e",
  // Profile
  'edit_profile': 'Eenyummaa Gulaali',
  'change_password': 'Jecha Iccitii Jijjiiri',
  'delete_account': 'Herrega Haqi',
  'current_password': "Jecha Iccitii Ammaa",
  'new_password': 'Jecha Iccitii Haaraa',
  'confirm_password': 'Jecha Iccitii Mirkaneessi',
  'save_changes': "Jijjiirama Olkaa'i",
  'profile_updated': "Eenyummaan milkaa'ee haaromfame",
  'password_changed': "Jecha iccitii milkaa'ee jijjiirame",
  // Wallet
  'wallet_balance': 'Balansi Waleetii',
  'top_up': 'Guuti',
  'transactions': 'Dabarsiiwwan',
  'no_transactions': 'Dabarsiin hin jiru',
  // Checkout - Extended
  'complete_your_order': 'Ajaja kee xumuri',
  'delivery_method': 'Mala Geejjibaa',
  'delivery': 'Geejjiba',
  'pickup': 'Fudhachuu',
  'free': 'Bilisaa',
  'delivery_location': 'Bakka Geejjibaa',
  'auto_detected': 'Meeshaa kee irraa ofumaan argame',
  'location_found': 'Bakki Argame',
  'location_not_available': 'Bakki hin argamne',
  'tap_to_enable': 'Bakka dandeessiisuuf tuqi',
  'getting_location': 'Bakka kee argachaa jira...',
  'delivery_instructions': 'Qajeelfama Geejjibaa (Filannoo)',
  'delivery_instructions_hint': 'Fakkeenyaaf, Bilbila rukuti, balbala irratti dhiisi...',
  'complete_payment': 'Kaffaltii Xumuri',
  'check_your_phone': 'Bilbila Kee Ilaali',
  'payment_prompt_sent': 'Gaaffiin kaffaltii bilbila keetti ergame',
  'enter_pin_to_authorize': 'Hayyamuuf PIN kee galchi',
  'payment_processed_instantly': 'Kaffaltiin battalumatti raawwatama',
  'i_paid': 'Kaffalee Jira',
  'arriving_soon': 'Dhiyootti Dhufaa Jira',
  'ready_for_pickup': 'Fudhatamuu Qophaa\'e',
  'arriving_in': 'Keessatti dhufaa jira',
  'ready_in': 'Keessatti qophaa\'a',
  'promo_code': 'Koodii Piromooshinii',
  'enter_promo_code': 'Koodii piromooshinii galchi',
  'apply': 'Fayyadami',
  'you_save': 'Qusatte',
  'add_a_tip': 'Tip Dabali',
  'show_appreciation': 'Konkolaataa geejjibaa keetiif galata agarsiisi 💝',
  'none': 'Homaa',
  'tax': 'Gibira',
  'tip': 'Tip',
  'discount': 'Hir\'ina',
  'please_enter_phone': 'Maaloo lakkoofsa bilbilaa kee galchi',
  'please_enable_location': 'Itti fufuuf bakka dandeessisi',
  'telebirr': 'Telebirr',
  'mpesa': 'M-Pesa',
  'cbe_birr': 'CBE Birr',
  'cash': 'Qarshii',
  'card': 'Kaardii',
  'pay_with': 'Kanaan kaffali',
  'credit_debit_card': 'Kaardii Liqii/Deebii',
  'cash_on_delivery_desc': 'Yeroo fudhattuu kaffali',
  'visa_mastercard': 'Visa, Mastercard',
  'table': 'Minjaala',
  'restaurant_menu': 'Tarree Nyaataa',
  // Order Status Page
  'call_waiter': 'Tajaajilaa Waamuu',
  'place_new_order': 'Ajaja Haaraa Galchi',
  'no_active_order': 'Ajajni hin jiru',
  'place_order_first': 'Haala ilaaluuf ajaja galchi',
  'order_placed_label': 'Ajajni Galche',
  'accepted': "Fudhatame",
  'ready': "Qophaa'e",
  'served': 'Tajaajilame',
  'order_cancelled': 'Ajajni Haqame',
  'contact_waiter': 'Gargaarsa argachuuf tajaajilaa quunnamaa',
  'calling_waiter': 'Tajaajilaa waammaa jira...',
  'waiter_notified': 'Tajaajilaan beeksifame!',
  'failed_call_waiter': 'Tajaajilaa waamuun hin milkaa\'in',
  // Bill Page
  'your_bill': 'Herrega Kee',
  'no_active_order_bill': 'Ajajni hin jiru',
  'add_items_first': 'Herrega ilaaluuf dursa ajaja galchi',
  'order_items': 'Wantawwan Ajajame',
  'payment_options': 'Filannoo Kaffaltii',
  'request_bill': 'Herrega Gaafadhu',
  'waiter_notified_bill': 'Tajaajilaan Beeksifame ✓',
  'bill_paid': 'Herregni Kaffalame',
  'thank_you_dining': 'Nyaata keetiif galatoomi!',
  'pay_cash_waiter': 'Tajaajilaa biratti qarshiin kaffali',
  // Orders Page
  'all_orders': 'Ajajawwan Hunda',
  'in_progress': 'Adeemaa Jira',
  'completed_label': "Xumurrame",
  'no_orders_yet': 'Ajajni hin jiru',
  'start_ordering': 'Nyaata mi\'aawaa ajajuu jalqabi!',
  'browse_menu': 'Tarree Ilaali',
  'order_number': 'Ajaja',
  'items': 'wantawwan',
  'view_details': 'Ibsa Ilaali',
  'track': 'Hordofi',
  // Home Page
  'search_cuisines': 'Nyaata, mana nyaataa barbaadi...',
  'good_morning': 'Akkam bulte',
  'good_afternoon': 'Akkam ooltee',
  'good_evening': 'Akkam ooltee',
  'what_to_eat': 'Maal nyaachuu barbaadda?',
  'all': 'Hunda',
  'restaurants': 'Mana Nyaataa',
  'featured': 'Filatamoo',
  'top_rated': 'Sadarkaa Ol\'aanaa',
  'open_now': 'Amma Banaa',
  // Dine-in Menu
  'dine_in_menu': 'Tarree Nyaataa',
  'search_menu_items': 'Nyaata barbaadi...',
  'all_items': 'Hunda',
  'added_to_cart': 'gaaritti dabalame',
  'no_items_found': 'Wanti hin argamne',
  'try_different_search': 'Barbaadii ykn ramaddii biraa yaalii',
  'menu': 'Tarree',
  'dine_in_subtitle': 'Tarree Nyaataa',
  // Food Detail
  'add_to_order': 'Ajajaatti Dabali',
  'special_instructions': 'Qajeelfama Addaa',
  'special_instructions_hint': 'Allergii ykn gaaffii addaa qabdaa?',
  'doneness': 'Bilchaatina',
  'removals': 'Haaquuwwan',
  'premium_add_ons': 'Dabalata Addaa',
  'signature': 'MALLATTOO',
  'chefs_choice': 'FILANNO ASOOSAA',
  'vegetarian': 'Kuduraa',
  'spicy': 'Daadhii',
  'prep_time': 'Yeroo Qophii',
  'calories': 'Kaloorii',
};

// Amharic Translations
const Map<String, String> _amharicTranslations = {
  'app_name': 'FoodieGo',
  'welcome_back': 'እንኳን ደህና መጡ!',
  'sign_in': 'ግባ',
  'sign_up': 'ተመዝገብ',
  'email': 'ኢሜይል',
  'password': 'የይለፍ ቃል',
  'forgot_password': 'የይለፍ ቃል ረሳህ?',
  'dont_have_account': 'መለያ የለህም?',
  'already_have_account': 'አስቀድመህ መለያ አለህ?',
  'full_name': 'ሙሉ ስም',
  'phone': 'ስልክ ቁጥር',
  'create_account': 'መለያ ፍጠር',
  'logout': 'ውጣ',
  'profile': 'መገለጫ',
  'settings': 'ቅንብሮች',
  'language': 'ቋንቋ',
  'home': 'መነሻ',
  'orders': 'ትዕዛዞች',
  'cart': 'ጋሪ',
  'favorites': 'ተወዳጆች',
  'addresses': 'አድራሻዎች',
  'notifications': 'ማሳወቂያዎች',
  'help_support': 'እገዛ እና ድጋፍ',
  'contact_us': 'አግኙን',
  'my_orders': 'ትዕዛዞቼ',
  'my_events': 'ዝግጅቶቼ',
  'payment_methods': 'የክፍያ ዘዴዎች',
  'account_settings': 'የመለያ ቅንብሮች',
  'select_language': 'ቋንቋ ይምረጡ',
  'continue': 'ቀጥል',
  'cancel': 'ሰርዝ',
  'confirm': 'አረጋግጥ',
  'delete': 'ሰርዝ',
  'edit': 'አርትዕ',
  'save': 'አስቀምጥ',
  'search': 'ፈልግ',
  'no_results': 'ምንም ውጤት አልተገኘም',
  'loading': 'በመጫን ላይ...',
  'error': 'ስህተት',
  'success': 'ተሳክቷል',
  'retry': 'እንደገና ሞክር',
  'coupons': 'ኩፖኖች',
  'wallet': 'ቦርሳ',
  'level': 'ደረጃ',
  'regular': 'መደበኛ',
  'my_account': 'መለያዬ',
  'more': 'ተጨማሪ',
  // Login/Register
  'sign_in_to_continue': 'ለመቀጠል ግባ',
  'delicious_food': 'ጣፋጭ ምግብ በደጃፍህ',
  'email_address': 'የኢሜይል አድራሻ',
  'invalid_email': 'ልክ ያልሆነ ኢሜይል',
  'required': 'ያስፈልጋል',
  'phone_number': 'ስልክ ቁጥር',
  'address': 'አድራሻ',
  'register_success': 'ምዝገባ ተሳክቷል',
  // Home
  'search_food': 'ምግብ ፈልግ...',
  'popular_foods': 'ታዋቂ ምግቦች',
  'all_foods': 'ሁሉም ምግቦች',
  'categories': 'ምድቦች',
  'see_all': 'ሁሉንም ይመልከቱ',
  'nearby_restaurants': 'በአቅራቢያ ያሉ ሬስቶራንቶች',
  'deliver_to': 'ማድረሻ',
  'current_location': 'የአሁኑ ቦታ',
  // Food detail
  'add_to_cart': 'ወደ ጋሪ ጨምር',
  'description': 'መግለጫ',
  'price': 'ዋጋ',
  'quantity': 'ብዛት',
  'reviews': 'ግምገማዎች',
  'write_review': 'ግምገማ ጻፍ',
  'rating': 'ደረጃ',
  'minutes': 'ደቂቃዎች',
  'views': 'እይታዎች',
  'likes': 'ወደዶች',
  // Cart
  'your_cart': 'ጋሪህ',
  'empty_cart': 'ጋሪህ ባዶ ነው',
  'subtotal': 'ንዑስ ድምር',
  'delivery_fee': 'የማድረሻ ክፍያ',
  'total': 'ጠቅላላ',
  'checkout': 'ክፈል',
  'clear_cart': 'ጋሪ አጽዳ',
  'remove_item': 'ዕቃ አስወግድ',
  // Orders
  'no_orders': 'ገና ትዕዛዝ የለም',
  'order_status': 'የትዕዛዝ ሁኔታ',
  'pending': 'በመጠባበቅ ላይ',
  'confirmed': 'ተረጋግጧል',
  'preparing': 'በመዘጋጀት ላይ',
  'on_the_way': 'በመንገድ ላይ',
  'delivered': 'ደርሷል',
  'cancelled': 'ተሰርዟል',
  'track_order': 'ትዕዛዝ ተከታተል',
  'order_details': 'የትዕዛዝ ዝርዝሮች',
  'order_date': 'የትዕዛዝ ቀን',
  'order_total': 'የትዕዛዝ ጠቅላላ',
  // Checkout
  'delivery_address': 'የማድረሻ አድራሻ',
  'payment_method': 'የክፍያ ዘዴ',
  'cash_on_delivery': 'በማድረስ ጊዜ ጥሬ ገንዘብ',
  'place_order': 'ትዕዛዝ አስገባ',
  'order_placed': 'ትዕዛዝ ገብቷል!',
  'order_confirmed': 'ትዕዛዝህ ተረጋግጧል',
  // Profile
  'edit_profile': 'መገለጫ አርትዕ',
  'change_password': 'የይለፍ ቃል ቀይር',
  'delete_account': 'መለያ ሰርዝ',
  'current_password': 'የአሁኑ የይለፍ ቃል',
  'new_password': 'አዲስ የይለፍ ቃል',
  'confirm_password': 'የይለፍ ቃል አረጋግጥ',
  'save_changes': 'ለውጦችን አስቀምጥ',
  'profile_updated': 'መገለጫ በተሳካ ሁኔታ ተዘምኗል',
  'password_changed': 'የይለፍ ቃል በተሳካ ሁኔታ ተቀይሯል',
  // Wallet
  'wallet_balance': 'የቦርሳ ቀሪ ሂሳብ',
  'top_up': 'ሙላ',
  'transactions': 'ግብይቶች',
  'no_transactions': 'ገና ግብይት የለም',
  // Checkout - Extended
  'complete_your_order': 'ትዕዛዝህን አጠናቅቅ',
  'delivery_method': 'የማድረሻ ዘዴ',
  'delivery': 'ማድረሻ',
  'pickup': 'መውሰጃ',
  'free': 'ነጻ',
  'delivery_location': 'የማድረሻ ቦታ',
  'auto_detected': 'ከመሣሪያህ በራስ-ሰር ተገኝቷል',
  'location_found': 'ቦታ ተገኝቷል',
  'location_not_available': 'ቦታ አይገኝም',
  'tap_to_enable': 'ቦታን ለማንቃት ንካ',
  'getting_location': 'ቦታህን በማግኘት ላይ...',
  'delivery_instructions': 'የማድረሻ መመሪያዎች (አማራጭ)',
  'delivery_instructions_hint': 'ለምሳሌ፣ ደወል ደውል፣ በበሩ ላይ ተው...',
  'complete_payment': 'ክፍያ አጠናቅቅ',
  'check_your_phone': 'ስልክህን ፈትሽ',
  'payment_prompt_sent': 'የክፍያ ጥያቄ ወደ ስልክህ ተልኳል',
  'enter_pin_to_authorize': 'ለማረጋገጥ ፒን አስገባ',
  'payment_processed_instantly': 'ክፍያ ወዲያውኑ ይሰራል',
  'i_paid': 'ከፍያለሁ',
  'arriving_soon': 'በቅርቡ በመድረስ ላይ',
  'ready_for_pickup': 'ለመውሰጃ ዝግጁ',
  'arriving_in': 'በ',
  'ready_in': 'በ ዝግጁ',
  'promo_code': 'የማስተዋወቂያ ኮድ',
  'enter_promo_code': 'የማስተዋወቂያ ኮድ አስገባ',
  'apply': 'ተግብር',
  'you_save': 'ቆጥበሃል',
  'add_a_tip': 'ጉርሻ ጨምር',
  'show_appreciation': 'ለአድራሻ ሹፌርህ አድናቆት አሳይ 💝',
  'none': 'ምንም',
  'tax': 'ግብር',
  'tip': 'ጉርሻ',
  'discount': 'ቅናሽ',
  'please_enter_phone': 'እባክህ ስልክ ቁጥርህን አስገባ',
  'please_enable_location': 'ለመቀጠል እባክህ ቦታን አንቃ',
  'telebirr': 'ቴሌብር',
  'mpesa': 'ኤም-ፔሳ',
  'cbe_birr': 'ሲቢኢ ብር',
  'cash': 'ጥሬ ገንዘብ',
  'card': 'ካርድ',
  'pay_with': 'በ ክፈል',
  'credit_debit_card': 'የክሬዲት/ዴቢት ካርድ',
  'cash_on_delivery_desc': 'ሲደርስህ ክፈል',
  'visa_mastercard': 'ቪዛ፣ ማስተርካርድ',
  'table': 'ጠረጴዛ',
  'restaurant_menu': 'የምግብ ቤት ምናሌ',
  // Order Status Page
  'call_waiter': 'አስተናጋጅ ጥራ',
  'place_new_order': 'አዲስ ትዕዛዝ አስገባ',
  'no_active_order': 'ንቁ ትዕዛዝ የለም',
  'place_order_first': 'ሁኔታ ለማየት ትዕዛዝ አስገባ',
  'order_placed_label': 'ትዕዛዝ ገብቷል',
  'accepted': 'ተቀብሏል',
  'ready': 'ዝግጁ',
  'served': 'ቀርቧል',
  'order_cancelled': 'ትዕዛዝ ተሰርዟል',
  'contact_waiter': 'ለእርዳታ አስተናጋጁን ያነጋግሩ',
  'calling_waiter': 'አስተናጋጅ በመጥራት ላይ...',
  'waiter_notified': 'አስተናጋጁ ተነግሯቸዋል!',
  'failed_call_waiter': 'አስተናጋጅ መጥራት አልተሳካም',
  // Bill Page
  'your_bill': 'ሂሳብህ',
  'no_active_order_bill': 'ንቁ ትዕዛዝ የለም',
  'add_items_first': 'ሂሳብ ለማየት መጀመሪያ ትዕዛዝ አስገባ',
  'order_items': 'የትዕዛዝ ዕቃዎች',
  'payment_options': 'የክፍያ አማራጮች',
  'request_bill': 'ሂሳብ ጠይቅ',
  'waiter_notified_bill': 'አስተናጋጅ ተነግሯቸዋል ✓',
  'bill_paid': 'ሂሳብ ተከፍሏል',
  'thank_you_dining': 'ስለ ምግብ ቤታችን ጎብኝዎት እናመሰግናለን!',
  'pay_cash_waiter': 'ለአስተናጋጁ ጥሬ ገንዘብ ክፈል',
  // Orders Page
  'all_orders': 'ሁሉም ትዕዛዞች',
  'in_progress': 'በሂደት ላይ',
  'completed_label': 'ተጠናቋል',
  'no_orders_yet': 'ገና ትዕዛዝ የለም',
  'start_ordering': 'ጣፋጭ ምግብ ማዘዝ ጀምር!',
  'browse_menu': 'ምናሌ ይመልከቱ',
  'order_number': 'ትዕዛዝ',
  'items': 'ዕቃዎች',
  'view_details': 'ዝርዝሮች ይመልከቱ',
  'track': 'ተከታተል',
  // Home Page
  'search_cuisines': 'ምግቦችን፣ ሬስቶራንቶችን ፈልግ...',
  'good_morning': 'እንደምን አደሩ',
  'good_afternoon': 'እንደምን ዋሉ',
  'good_evening': 'እንደምን ዋሉ',
  'what_to_eat': 'ምን መብላት ይፈልጋሉ?',
  'all': 'ሁሉም',
  'restaurants': 'ሬስቶራንቶች',
  'featured': 'ተለይቶ የቀረበ',
  'top_rated': 'ከፍተኛ ደረጃ',
  'open_now': 'አሁን ክፍት',
  // Dine-in Menu
  'dine_in_menu': 'የምግብ ቤት ምናሌ',
  'search_menu_items': 'ምናሌ ዕቃዎችን ፈልግ...',
  'all_items': 'ሁሉም',
  'added_to_cart': 'ወደ ጋሪ ተጨምሯል',
  'no_items_found': 'ምንም ዕቃ አልተገኘም',
  'try_different_search': 'ሌላ ፍለጋ ወይም ምድብ ሞክር',
  'menu': 'ምናሌ',
  'dine_in_subtitle': 'የምግብ ቤት ምናሌ',
  // Food Detail
  'add_to_order': 'ወደ ትዕዛዝ ጨምር',
  'special_instructions': 'ልዩ መመሪያዎች',
  'special_instructions_hint': 'አለርጂ ወይም ልዩ ጥያቄ አለህ?',
  'doneness': 'የብስለት ደረጃ',
  'removals': 'ማስወገጃዎች',
  'premium_add_ons': 'ተጨማሪ ዕቃዎች',
  'signature': 'ፊርማ',
  'chefs_choice': 'የሼፍ ምርጫ',
  'vegetarian': '채식주의자',
  'spicy': 'ቅመም',
  'prep_time': 'የዝግጅት ጊዜ',
  'calories': 'ካሎሪ',
};
