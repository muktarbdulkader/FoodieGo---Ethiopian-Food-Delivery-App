import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/location_utils.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/order/order_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../state/language/language_provider.dart';
import '../../../state/dine_in/dine_in_provider.dart';
import '../../../data/models/order.dart';
import '../../../data/models/user.dart';
import '../../../data/services/api_service.dart';
import '../orders/orders_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage>
    with TickerProviderStateMixin {
  final _instructionsController = TextEditingController();
  final _phoneController = TextEditingController();
  final _promoController = TextEditingController();

  String _selectedPayment = 'cash';
  String _deliveryType = 'delivery';
  double _tip = 0;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  // Promo code state
  bool _isApplyingPromo = false;
  String? _appliedPromoCode;
  double _promoDiscount = 0;
  String? _promoDescription;
  
  // Restaurant promotions
  bool _hasPromotions = false;
  bool _isLoadingPromotions = true;
  String? _restaurantId;

  // Auto-fetched location
  String? _currentAddress;
  String? _currentCity;
  double? _latitude;
  double? _longitude;

  // Distance and delivery fee calculation
  double? _distanceKm;
  double _calculatedDeliveryFee = 20.0; // Default base fee
  int? _estimatedDeliveryTime;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Payment methods with Ethiopian options
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'telebirr',
      'name': 'Telebirr',
      'icon': Icons.phone_android,
      'color': const Color(0xFF00A651),
      'description': 'Pay with Telebirr',
      'logo': '🟢',
    },
    {
      'id': 'mpesa',
      'name': 'M-Pesa',
      'icon': Icons.phone_iphone,
      'color': const Color(0xFFE60000),
      'description': 'Pay with M-Pesa',
      'logo': '🔴',
    },
    {
      'id': 'cbe_birr',
      'name': 'CBE Birr',
      'icon': Icons.account_balance,
      'color': const Color(0xFF1E3A8A),
      'description': 'Commercial Bank of Ethiopia',
      'logo': '🔵',
    },
    {
      'id': 'cash',
      'name': 'Cash on Delivery',
      'icon': Icons.payments_outlined,
      'color': const Color(0xFF059669),
      'description': 'Pay when you receive',
      'logo': '💵',
    },
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'color': const Color(0xFF7C3AED),
      'description': 'Visa, Mastercard',
      'logo': '💳',
    },
  ];

  final List<double> _tipOptions = [0, 10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();

    // Auto-load location on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserLocation();
      _checkRestaurantPromotions();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _instructionsController.dispose();
    _phoneController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    // Check if this is a dine-in order - skip location for dine-in
    final dineInProvider = context.read<DineInProvider>();
    if (dineInProvider.isDineInMode) {
      // For dine-in, we don't need location - customer is at the restaurant
      setState(() {
        _currentAddress = 'Dine-In at Restaurant';
        _calculatedDeliveryFee = 0; // No delivery fee for dine-in
      });
      return;
    }
    
    // First check if user already has location saved
    final user = context.read<AuthProvider>().user;
    if (user?.location?.address != null) {
      setState(() {
        _currentAddress = user!.location!.address;
        _currentCity = user.location!.city;
        _latitude = user.location!.latitude;
        _longitude = user.location!.longitude;
      });
      
      // Calculate distance after loading user location
      await _fetchRestaurantDataAndCalculateDistance();
      return;
    }

    // Otherwise, auto-fetch location
    await _fetchCurrentLocation();
  }

  /// Fetch restaurant data and calculate distance
  Future<void> _fetchRestaurantDataAndCalculateDistance() async {
    try {
      final cart = context.read<CartProvider>();
      if (cart.items.isEmpty) return;

      final restaurantId = cart.items.first.hotelId;
      
      // Fetch restaurant user data to get location
      final response = await ApiService.get('/admin/users/$restaurantId');
      final restaurantData = User.fromJson(response['data']);
      
      if (mounted) {
        // Calculate distance if both locations are available
        if (_latitude != null && 
            _longitude != null && 
            restaurantData.location?.latitude != null && 
            restaurantData.location?.longitude != null) {
          
          final distance = LocationUtils.calculateDistance(
            lat1: _latitude!,
            lon1: _longitude!,
            lat2: restaurantData.location!.latitude!,
            lon2: restaurantData.location!.longitude!,
          );

          final deliveryFee = LocationUtils.calculateDeliveryFee(distance);
          final estimatedTime = LocationUtils.estimateDeliveryTimeMinutes(distance);

          if (mounted) {
            setState(() {
              _distanceKm = distance;
              _calculatedDeliveryFee = deliveryFee;
              _estimatedDeliveryTime = estimatedTime;
            });
          }
        }
      }
    } catch (e) {
      // Silently fail - use default delivery fee
      debugPrint('Error fetching restaurant data: $e');
    }
  }

  Future<void> _checkRestaurantPromotions() async {
    setState(() => _isLoadingPromotions = true);

    try {
      final cart = context.read<CartProvider>();
      
      // Get restaurant ID from first cart item
      if (cart.items.isEmpty) {
        setState(() {
          _hasPromotions = false;
          _isLoadingPromotions = false;
        });
        return;
      }

      _restaurantId = cart.items.first.hotelId;

      // Fetch active promotions for this restaurant
      final response = await ApiService.get(
        '/promotions/restaurant/$_restaurantId/active'
      );

      if (mounted) {
        setState(() {
          _hasPromotions = response['success'] == true && 
                          (response['data'] as List?)?.isNotEmpty == true;
          _isLoadingPromotions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPromotions = false;
          _isLoadingPromotions = false;
        });
      }
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final location = await LocationService.getFullLocation();
      if (location != null && mounted) {
        setState(() {
          _currentAddress = location['address'];
          _currentCity = location['city'];
          _latitude = location['latitude'];
          _longitude = location['longitude'];
          _isLoadingLocation = false;
        });

        // Also update user profile with new location
        context.read<AuthProvider>().updateLocation(
              latitude: location['latitude'],
              longitude: location['longitude'],
              address: location['address'],
              city: location['city'],
            );

        // Calculate distance after fetching location
        await _fetchRestaurantDataAndCalculateDistance();
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  bool _needsPhoneNumber() {
    return ['telebirr', 'mpesa', 'cbe_birr'].contains(_selectedPayment);
  }

  Future<void> _placeOrder() async {
    // Check if this is a dine-in order
    final dineInProvider = context.read<DineInProvider>();
    final isDineIn = dineInProvider.isDineInMode;
    
    // Skip location check for dine-in orders
    if (!isDineIn && _deliveryType == 'delivery' && _currentAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enable location to continue'),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (_needsPhoneNumber() && _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.phone, color: Colors.white),
              SizedBox(width: 12),
              Text('Please enter your phone number'),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final cart = context.read<CartProvider>();
    final subtotal = cart.totalPrice;
    final deliveryFee = isDineIn ? 0.0 : (_deliveryType == 'delivery' ? _calculatedDeliveryFee : 0.0);
    final tax = subtotal * 0.15;
    final total = subtotal + deliveryFee + tax + _tip - _promoDiscount;

    // For dine-in, use table information instead of delivery address
    final deliveryAddress = isDineIn 
        ? DeliveryAddress(
            label: 'Dine-In',
            fullAddress: 'Table ${dineInProvider.getTableNumber() ?? 'Unknown'}${dineInProvider.getTableLocation() != null ? ' - ${dineInProvider.getTableLocation()}' : ''}',
            street: 'Dine-In Order',
            city: 'Restaurant',
            zipCode: '',
            instructions: _instructionsController.text.isNotEmpty 
                ? 'Table ${dineInProvider.getTableNumber()}: ${_instructionsController.text}'
                : 'Table ${dineInProvider.getTableNumber()}',
            latitude: null,
            longitude: null,
          )
        : (_deliveryType == 'delivery'
            ? DeliveryAddress(
                label: 'Current Location',
                fullAddress: _currentAddress ?? '',
                street: '',
                city: _currentCity ?? '',
                zipCode: '',
                instructions: _instructionsController.text,
                latitude: _latitude,
                longitude: _longitude,
              )
            : null);

    final payment = Payment(method: _selectedPayment, status: 'pending');
    final delivery = Delivery(
      type: isDineIn ? 'dine_in' : _deliveryType,
      fee: deliveryFee,
      estimatedTime: isDineIn ? 15 : (_estimatedDeliveryTime ?? (_deliveryType == 'delivery' ? 30 : 15)),
      distance: isDineIn ? 0 : _distanceKm,
    );

    final order = await cart.placeOrderWithDetails(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      tax: tax,
      tip: _tip,
      totalPrice: total,
      deliveryAddress: deliveryAddress,
      payment: payment,
      delivery: delivery,
    );

    if (order == null) {
      setState(() => _isLoading = false);
      if (mounted && cart.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cart.error!),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      return;
    }

    // Handle payment based on method
    if (_selectedPayment == 'telebirr' || _selectedPayment == 'mpesa' || _selectedPayment == 'cbe_birr') {
      // Initiate mobile payment
      await _initiateMobilePayment(order, total);
    } else {
      // Cash or Card - show success immediately
      setState(() => _isLoading = false);
      
      if (mounted) {
        context.read<OrderProvider>().fetchOrders();

        // Show notification
        NotificationService.showOrderNotification(
          title: isDineIn ? 'Order Sent to Kitchen! 🍽️' : 'Order Placed! 🎉',
          body: isDineIn 
              ? 'Your order for Table ${dineInProvider.getTableNumber()} has been sent to the kitchen.'
              : 'Your order #${order.orderNumber} has been placed successfully.',
          payload: order.id,
        );

        _showSuccessDialog(order);
      }
    }
  }

  Future<void> _initiateMobilePayment(Order order, double total) async {
    try {
      final response = await ApiService.post('/payments/telebirr/initiate', {
        'orderId': order.id,
        'amount': total,
        'phoneNumber': _phoneController.text,
        'paymentMethod': _selectedPayment,
      });

      setState(() => _isLoading = false);

      if (response['success'] == true && mounted) {
        final paymentUrl = response['data']?['toPayUrl'];
        
        if (paymentUrl != null) {
          // Show payment dialog with instructions
          _showPaymentDialog(order, paymentUrl);
        } else {
          // Mock mode or no URL - show success
          context.read<OrderProvider>().fetchOrders();
          NotificationService.showOrderNotification(
            title: 'Order Placed! 🎉',
            body: 'Your order #${order.orderNumber} has been placed successfully.',
            payload: order.id,
          );
          _showSuccessDialog(order);
        }
      } else {
        throw Exception(response['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showPaymentDialog(Order order, String paymentUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Payment',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return ScaleTransition(
          scale: curvedAnimation,
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated phone icon with pulse effect
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00A651),
                                      const Color(0xFF00D563),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00A651)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeInOut,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: const Icon(
                                        Icons.phone_android_rounded,
                                        color: Colors.white,
                                        size: 56,
                                      ),
                                    );
                                  },
                                  onEnd: () {
                                    // Repeat animation
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        
                        // Animated title
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Text(
                                'Complete Payment',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00A651)
                                          .withValues(alpha: 0.15),
                                      const Color(0xFF00D563)
                                          .withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFF00A651)
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF00A651),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedPayment.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFF00A651),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Order number badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Order #${order.orderNumber}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Animated info card
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFF0F9FF),
                                  const Color(0xFFE0F2FE),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF0EA5E9)
                                    .withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0EA5E9)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.phone_iphone_rounded,
                                        color: Color(0xFF0EA5E9),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Check Your Phone',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF0EA5E9),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _phoneController.text,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    children: [
                                      _buildInstructionStep(
                                        '1',
                                        'Payment prompt sent to your phone',
                                        Icons.notifications_active_rounded,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInstructionStep(
                                        '2',
                                        'Enter your PIN to authorize',
                                        Icons.lock_rounded,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInstructionStep(
                                        '3',
                                        'Payment will be processed instantly',
                                        Icons.flash_on_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Action buttons with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00A651),
                                        Color(0xFF00D563),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00A651)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context
                                          .read<OrderProvider>()
                                          .fetchOrders();
                                      _showSuccessDialog(order);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'I Paid',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructionStep(String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00A651), Color(0xFF00D563)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
        ),
        Icon(icon, size: 18, color: const Color(0xFF00A651)),
      ],
    );
  }

  void _showSuccessDialog(Order order) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Success',
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          ),
          child: FadeTransition(
            opacity: animation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated success icon with confetti effect
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: (1 - value) * 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.accentGreen,
                                      AppTheme.accentGreen.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentGreen
                                          .withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                  size: 72,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),
                      
                      // Animated title with emoji
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: const Column(
                          children: [
                            Text(
                              '🎉',
                              style: TextStyle(fontSize: 48),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Order Confirmed!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your order has been placed successfully',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Order number badge with gradient
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor.withValues(alpha: 0.15),
                              AppTheme.accentOrange.withValues(alpha: 0.15),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Order #${order.orderNumber}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Delivery info card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFF7ED),
                              const Color(0xFFFFEDD5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.accentOrange.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.accentOrange,
                                    AppTheme.accentOrange
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentOrange
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _deliveryType == 'delivery'
                                    ? Icons.delivery_dining_rounded
                                    : Icons.store_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _deliveryType == 'delivery'
                                        ? 'Arriving Soon'
                                        : 'Ready for Pickup',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 16,
                                        color: AppTheme.accentOrange,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _deliveryType == 'delivery'
                                            ? '25-35 minutes'
                                            : '10-15 minutes',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Track order button with gradient
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const OrdersPage()),
                            (route) => route.isFirst,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_rounded,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Track Order',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(loc),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryTypeSelector(loc),
                      const SizedBox(height: 20),
                      if (_deliveryType == 'delivery') ...[
                        _buildLocationCard(loc),
                        const SizedBox(height: 20),
                      ],
                      _buildPaymentSection(loc),
                      const SizedBox(height: 20),
                      // Only show promo code section if restaurant has promotions
                      if (_hasPromotions && !_isLoadingPromotions) ...[
                        _buildPromoCodeSection(loc),
                        const SizedBox(height: 20),
                      ],
                      _buildTipSection(loc),
                      const SizedBox(height: 20),
                      _buildOrderSummary(loc),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(loc),
    );
  }

  Widget _buildHeader(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Complete your order',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTypeSelector(AppLocalizations loc) {
    // Calculate delivery fee text
    final deliveryFeeText = _distanceKm != null
        ? 'ETB ${_calculatedDeliveryFee.toStringAsFixed(0)}'
        : 'ETB 20+';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.local_shipping, color: AppTheme.primaryColor, size: 22),
            SizedBox(width: 8),
            Text('Delivery Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildDeliveryOption(
                  'delivery', 'Delivery', Icons.delivery_dining, deliveryFeeText),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDeliveryOption(
                  'pickup', 'Pickup', Icons.storefront, 'Free'),
            ),
          ],
        ),
        // Show distance info if available
        if (_deliveryType == 'delivery' && _distanceKm != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: Color(0xFF0EA5E9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Distance: ${LocationUtils.formatDistance(_distanceKm!)} • Est. ${_estimatedDeliveryTime != null ? LocationUtils.formatDeliveryTime(_estimatedDeliveryTime!) : "30 min"}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeliveryOption(
      String type, String label, IconData icon, String price) {
    final isSelected = _deliveryType == type;
    return GestureDetector(
      onTap: () => setState(() => _deliveryType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                price,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentGreen,
                      AppTheme.accentGreen.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Auto-detected from your device',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Location display
          if (_isLoadingLocation)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Getting your location...',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          else if (_currentAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Location Found',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _fetchCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.refresh,
                              size: 18, color: AppTheme.accentGreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.place, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentAddress!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentCity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_city,
                            size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          _currentCity!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _fetchCurrentLocation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.location_off,
                          color: AppTheme.errorColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location not available',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.errorColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to enable location',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: AppTheme.errorColor),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Delivery instructions
          TextFormField(
            controller: _instructionsController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Delivery Instructions (Optional)',
              hintText: 'E.g., Ring doorbell, leave at door...',
              prefixIcon: const Icon(Icons.note_outlined,
                  color: AppTheme.primaryColor, size: 20),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryColor, size: 22),
              SizedBox(width: 8),
              Text('Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          // Mobile Money
          _buildPaymentCategory(
              '📱 Mobile Money', ['telebirr', 'mpesa', 'cbe_birr']),
          const SizedBox(height: 12),
          // Other
          _buildPaymentCategory('💳 Other Options', ['cash', 'card']),
          // Phone number for mobile payments
          if (_needsPhoneNumber()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _paymentMethods
                    .firstWhere((m) => m['id'] == _selectedPayment)['color']
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _paymentMethods
                      .firstWhere((m) => m['id'] == _selectedPayment)['color']
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone,
                          color: _paymentMethods.firstWhere(
                              (m) => m['id'] == _selectedPayment)['color'],
                          size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Enter Phone Number',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _paymentMethods.firstWhere(
                              (m) => m['id'] == _selectedPayment)['color'],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+251 9XX XXX XXX',
                      prefixIcon: const Icon(Icons.phone_android),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _paymentMethods.firstWhere(
                              (m) => m['id'] == _selectedPayment)['color'],
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentCategory(String title, List<String> methodIds) {
    final methods =
        _paymentMethods.where((m) => methodIds.contains(m['id'])).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        ...methods.map((method) => _buildPaymentOption(method)),
      ],
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedPayment == method['id'];
    final Color methodColor = method['color'];

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? methodColor.withValues(alpha: 0.08)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? methodColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? methodColor.withValues(alpha: 0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method['icon'],
                  color: isSelected ? methodColor : AppTheme.textSecondary,
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(method['logo'],
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        method['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              isSelected ? methodColor : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    method['description'],
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected ? methodColor : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? methodColor : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : const SizedBox(width: 12, height: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a promo code')),
      );
      return;
    }
    setState(() => _isApplyingPromo = true);
    try {
      final cart = context.read<CartProvider>();
      final response = await ApiService.post('/promotions/validate', {
        'code': code,
        'orderAmount': cart.totalPrice,
        'restaurantId': _restaurantId, // Include restaurant ID
      });
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _appliedPromoCode = code.toUpperCase();
          _promoDiscount = (response['data']['discount'] ?? 0).toDouble();
          _promoDescription = response['data']['description'];
          _isApplyingPromo = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                      'Promo applied! You save ETB ${_promoDiscount.toStringAsFixed(0)}'),
                ],
              ),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isApplyingPromo = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _promoDiscount = 0;
      _promoDescription = null;
      _promoController.clear();
    });
  }

  Widget _buildPromoCodeSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_offer, color: AppTheme.primaryColor, size: 22),
              SizedBox(width: 8),
              Text('Promo Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (_appliedPromoCode != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        borderRadius: BorderRadius.circular(12)),
                    child:
                        const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_appliedPromoCode!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.accentGreen)),
                        if (_promoDescription != null)
                          Text(_promoDescription!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        Text(
                            'You save ETB ${_promoDiscount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accentGreen,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: _removePromoCode,
                      icon: const Icon(Icons.close, color: Colors.grey)),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      prefixIcon: const Icon(Icons.confirmation_number_outlined,
                          color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppTheme.primaryColor, width: 2)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isApplyingPromo ? null : _applyPromoCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14)),
                    child: _isApplyingPromo
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Apply',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTipSection(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite, color: Color(0xFFEC4899), size: 22),
              SizedBox(width: 8),
              Text('Add a Tip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Show appreciation for your delivery driver 💝',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: _tipOptions.map((amount) {
              final isSelected = _tip == amount;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tip = amount),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)])
                          : null,
                      color: isSelected ? null : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFFEC4899)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        amount == 0 ? 'None' : '${amount.toInt()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color:
                              isSelected ? Colors.white : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(AppLocalizations loc) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.totalPrice;
        final deliveryFee = _deliveryType == 'delivery' ? _calculatedDeliveryFee : 0.0;
        final tax = subtotal * 0.15;
        final total = subtotal + deliveryFee + tax + _tip;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long,
                      color: AppTheme.primaryColor, size: 22),
                  SizedBox(width: 8),
                  Text('Order Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_bag,
                          color: AppTheme.primaryColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${cart.itemCount} items',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text('From your cart',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Subtotal', subtotal),
              // Show delivery fee with distance info
              if (_deliveryType == 'delivery') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Delivery Fee',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700)),
                        if (_distanceKm != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              LocationUtils.formatDistance(_distanceKm!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0EA5E9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('${AppConstants.currency}${deliveryFee.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800)),
                  ],
                ),
                const SizedBox(height: 10),
                // Show estimated delivery time
                if (_estimatedDeliveryTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Text(
                          'Est. ${LocationUtils.formatDeliveryTime(_estimatedDeliveryTime!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
              ] else
                _buildSummaryRow('Delivery Fee', deliveryFee),
              _buildSummaryRow('VAT (15%)', tax),
              if (_tip > 0) _buildSummaryRow('Tip', _tip),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${AppConstants.currency}${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            '${AppConstants.currency}${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations loc) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.totalPrice;
        final deliveryFee = _deliveryType == 'delivery' ? _calculatedDeliveryFee : 0.0;
        final tax = subtotal * 0.15;
        final total = subtotal + deliveryFee + tax + _tip;

        final selectedMethod =
            _paymentMethods.firstWhere((m) => m['id'] == _selectedPayment);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12)),
                      Text(
                        '${AppConstants.currency}${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _isLoading ? null : _placeOrder,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _isLoading
                            ? null
                            : LinearGradient(
                                colors: [
                                  selectedMethod['color'],
                                  (selectedMethod['color'] as Color)
                                      .withValues(alpha: 0.8),
                                ],
                              ),
                        color: _isLoading ? Colors.grey.shade300 : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isLoading
                            ? null
                            : [
                                BoxShadow(
                                  color: (selectedMethod['color'] as Color)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(selectedMethod['icon'],
                                    size: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedPayment == 'cash'
                                      ? 'Place Order'
                                      : 'Pay Now',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
