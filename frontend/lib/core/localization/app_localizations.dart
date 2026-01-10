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
};
