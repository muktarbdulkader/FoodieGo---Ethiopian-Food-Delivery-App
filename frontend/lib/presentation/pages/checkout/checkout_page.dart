import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/order/order_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../data/models/order.dart';
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

  // Auto-fetched location
  String? _currentAddress;
  String? _currentCity;
  double? _latitude;
  double? _longitude;

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
    // First check if user already has location saved
    final user = context.read<AuthProvider>().user;
    if (user?.location?.address != null) {
      setState(() {
        _currentAddress = user!.location!.address;
        _currentCity = user.location!.city;
        _latitude = user.location!.latitude;
        _longitude = user.location!.longitude;
      });
      return;
    }

    // Otherwise, auto-fetch location
    await _fetchCurrentLocation();
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
    if (_deliveryType == 'delivery' && _currentAddress == null) {
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
    final deliveryFee = _deliveryType == 'delivery' ? 50.0 : 0.0;
    final tax = subtotal * 0.15;
    final total = subtotal + deliveryFee + tax + _tip - _promoDiscount;

    final deliveryAddress = _deliveryType == 'delivery'
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
        : null;

    final payment = Payment(method: _selectedPayment, status: 'pending');
    final delivery = Delivery(
      type: _deliveryType,
      fee: deliveryFee,
      estimatedTime: _deliveryType == 'delivery' ? 30 : 15,
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

    setState(() => _isLoading = false);

    if (order != null && mounted) {
      context.read<OrderProvider>().fetchOrders();

      // Show notification
      NotificationService.showOrderNotification(
        title: 'Order Placed! 🎉',
        body: 'Your order #${order.orderNumber} has been placed successfully.',
        payload: order.id,
      );

      _showSuccessDialog(order);
    } else if (mounted && cart.error != null) {
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
  }

  void _showSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.accentGreen.withValues(alpha: 0.2),
                          AppTheme.accentGreen.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle,
                        color: AppTheme.accentGreen, size: 64),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🎉 Order Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _deliveryType == 'delivery'
                        ? Icons.delivery_dining
                        : Icons.store,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _deliveryType == 'delivery'
                        ? 'Arriving in 25-35 min'
                        : 'Ready in 10-15 min',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                    (route) => route.isFirst,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.buttonShadow,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Track Order',
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeliveryTypeSelector(),
                      const SizedBox(height: 20),
                      if (_deliveryType == 'delivery') ...[
                        _buildLocationCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildPaymentSection(),
                      const SizedBox(height: 20),
                      _buildPromoCodeSection(),
                      const SizedBox(height: 20),
                      _buildTipSection(),
                      const SizedBox(height: 20),
                      _buildOrderSummary(),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
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

  Widget _buildDeliveryTypeSelector() {
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
                  'delivery', 'Delivery', Icons.delivery_dining, 'ETB 50'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDeliveryOption(
                  'pickup', 'Pickup', Icons.storefront, 'Free'),
            ),
          ],
        ),
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

  Widget _buildLocationCard() {
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

  Widget _buildPaymentSection() {
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

  Widget _buildPromoCodeSection() {
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

  Widget _buildTipSection() {
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

  Widget _buildOrderSummary() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.totalPrice;
        final deliveryFee = _deliveryType == 'delivery' ? 50.0 : 0.0;
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

  Widget _buildBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final subtotal = cart.totalPrice;
        final deliveryFee = _deliveryType == 'delivery' ? 50.0 : 0.0;
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
