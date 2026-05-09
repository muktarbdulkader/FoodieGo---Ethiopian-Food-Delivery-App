import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../state/language/language_provider.dart';
import '../../../data/models/food.dart';
import '../../../state/food/food_provider.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/dine_in/dine_in_provider.dart';
import 'dine_in_cart_page.dart';
import 'dine_in_food_detail_page.dart';
import 'bill_page.dart';
import 'order_status_page.dart';

class DineInMenuPage extends StatefulWidget {
  final String restaurantId;
  final String tableId;

  const DineInMenuPage({
    super.key,
    required this.restaurantId,
    required this.tableId,
  });

  @override
  State<DineInMenuPage> createState() => _DineInMenuPageState();
}

class _DineInMenuPageState extends State<DineInMenuPage>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Items';
  int _currentNavIndex = 0;

  late AnimationController _headerAnimController;
  late AnimationController _bgAnimController;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _headerFade = CurvedAnimation(
        parent: _headerAnimController, curve: Curves.easeOut);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _headerAnimController, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().fetchFoodsByHotel(
            widget.restaurantId,
            menuType: 'dine_in',
          );
      final dineIn = context.read<DineInProvider>();
      if (!dineIn.isDineInMode &&
          widget.restaurantId.isNotEmpty &&
          widget.tableId.isNotEmpty) {
        dineIn
            .loadTableData(widget.restaurantId, widget.tableId)
            .catchError((_) {});
      }
      _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimController.dispose();
    _bgAnimController.dispose();
    super.dispose();
  }

  List<String> _getCategories(List<Food> foods, AppLocalizations loc) {
    final cats = foods.map((f) => f.category).toSet().toList()..sort();
    return [loc.allItems, ...cats];
  }

  List<Food> _getFilteredFoods(List<Food> foods) {
    final query = _searchController.text.toLowerCase();
    final loc = context.read<LanguageProvider>().loc;
    return foods.where((food) {
      final isDineInFood =
          food.menuTypes.isEmpty || food.menuTypes.contains('dine_in');
      final matchesSearch = query.isEmpty ||
          food.name.toLowerCase().contains(query) ||
          food.description.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == loc.allItems ||
              food.category == _selectedCategory;
      return isDineInFood &&
          matchesSearch &&
          matchesCategory &&
          food.isAvailable;
    }).toList();
  }

  void _addToCart(Food food) {
    context.read<CartProvider>().addToCart(food, isDineIn: true);
    final loc = context.read<LanguageProvider>().loc;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food.name} ${loc.addedToCart}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _goToCart() {
    final dineIn = context.read<DineInProvider>();
    if (!dineIn.isDineInMode &&
        widget.restaurantId.isNotEmpty &&
        widget.tableId.isNotEmpty) {
      dineIn
          .loadTableData(widget.restaurantId, widget.tableId)
          .catchError((_) {});
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DineInCartPage(
          restaurantId: widget.restaurantId,
          tableId: widget.tableId,
        ),
      ),
    );
  }

  void _goToOrders() {
    setState(() => _currentNavIndex = 2);
    final dineIn = context.read<DineInProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderStatusPage(
          tableId: widget.tableId,
          restaurantId: widget.restaurantId,
          guestSessionId: dineIn.guestSessionId,
        ),
      ),
    );
  }

  void _goToBill() {
    setState(() => _currentNavIndex = 3);
    final dineIn = context.read<DineInProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BillPage(
          tableId: widget.tableId,
          restaurantId: widget.restaurantId,
          guestSessionId: dineIn.guestSessionId,
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final langProvider = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.translate,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  context.read<LanguageProvider>().loc.selectLanguage,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...LanguageProvider.supportedLanguages.map((lang) {
              final isSelected = langProvider.languageCode == lang.code;
              return GestureDetector(
                onTap: () {
                  langProvider.setLanguage(lang.code);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.nativeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (lang.name != lang.nativeName)
                              Text(lang.name,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: AppTheme.primaryColor, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LanguageProvider>().loc;
    final foodProvider = context.watch<FoodProvider>();
    final cartProvider = context.watch<CartProvider>();
    final foods = foodProvider.foods;
    final categories = _getCategories(foods, loc);
    final filtered = _getFilteredFoods(foods);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(foods),
            Expanded(
              child: foodProvider.isLoading && foods.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : foodProvider.error != null && foods.isEmpty
                      ? _buildError(foodProvider.error!)
                      : CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildSearchBar(loc),
                                  const SizedBox(height: 4),
                                  _buildCategoryChips(categories),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            filtered.isEmpty
                                ? SliverFillRemaining(
                                    child: _buildEmpty(loc))
                                : SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 100),
                                    sliver: SliverList(
                                      delegate:
                                          SliverChildBuilderDelegate(
                                        (context, index) =>
                                            _buildFoodCard(
                                                filtered[index],
                                                cartProvider,
                                                loc),
                                        childCount: filtered.length,
                                      ),
                                    ),
                                  ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(cartProvider, loc),
    );
  }

  Widget _buildHeader(List<Food> foods) {
    final restaurantName =
        foods.isNotEmpty ? foods.first.hotelName : 'Welcome';
    final tableNumber =
        context.read<DineInProvider>().getTableNumber() ?? '';
    final langProvider = context.watch<LanguageProvider>();

    return SlideTransition(
      position: _headerSlide,
      child: FadeTransition(
        opacity: _headerFade,
        child: AnimatedBuilder(
          animation: _bgAnimController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                    0.0,
                    0.3 + (_bgAnimController.value * 0.4),
                    1.0
                  ],
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.9),
                    AppTheme.primaryColor,
                    const Color(0xFFE65100), // A deep warm orange/red
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative background elements
                  Positioned(
                    right: -20 + (_bgAnimController.value * 10),
                    top: -20 - (_bgAnimController.value * 5),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30 - (_bgAnimController.value * 10),
                    bottom: -10 + (_bgAnimController.value * 5),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // Main Content
                  child!,
                ],
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${langProvider.loc.welcomeBack} 👋',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    restaurantName.isNotEmpty
                        ? Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Container(
                            height: 26,
                            width: 160,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                    const SizedBox(height: 12),
                    if (tableNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.table_restaurant,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              'Table $tableNumber',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _showLanguagePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            langProvider.currentLanguage.flag,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            langProvider.currentLanguage.code.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.keyboard_arrow_down,
                              size: 16, color: AppTheme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: loc.searchMenuItems,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppTheme.primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<String> categories) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodCard(
      Food food, CartProvider cartProvider, AppLocalizations loc) {
    final cartQty = cartProvider.items
        .where((i) => i.foodId == food.id)
        .fold(0, (sum, i) => sum + i.quantity);
    final priceText = 'ETB ${food.getFinalDineInPrice().toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DineInFoodDetailPage(
            food: food,
            restaurantId: widget.restaurantId,
            tableId: widget.tableId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: food.image.isNotEmpty
                        ? Image.network(
                            food.image,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null
                                    ? child
                                    : _buildImagePlaceholder(),
                            errorBuilder: (_, __, ___) =>
                                _buildImagePlaceholder(),
                          )
                        : _buildImagePlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priceText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          food.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  cartQty == 0
                      ? _buildAddButton(food)
                      : _buildQtyControl(food, cartQty),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Icon(Icons.restaurant, size: 52, color: Colors.grey[300]),
      ),
    );
  }

  Widget _buildAddButton(Food food) {
    return GestureDetector(
      onTap: () => _addToCart(food),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildQtyControl(Food food, int qty) {
    final cart = context.read<CartProvider>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _qtyBtn(
          icon: Icons.remove,
          onTap: () => cart.updateQuantity(food.id, qty - 1),
          color: Colors.grey.shade200,
          iconColor: AppTheme.textPrimary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$qty',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        _qtyBtn(
          icon: Icons.add,
          onTap: () => _addToCart(food),
          color: AppTheme.primaryColor,
          iconColor: Colors.white,
        ),
      ],
    );
  }

  Widget _qtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }

  Widget _buildBottomNav(CartProvider cartProvider, AppLocalizations loc) {
    final cartCount = cartProvider.itemCount;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: loc.menu,
                index: 0,
                onTap: () => setState(() => _currentNavIndex = 0),
              ),
              _navItem(
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: loc.cart,
                index: 1,
                badge: cartCount > 0 ? cartCount : null,
                onTap: _goToCart,
              ),
              _navItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: loc.orders,
                index: 2,
                onTap: _goToOrders,
              ),
              _navItem(
                icon: Icons.receipt_outlined,
                activeIcon: Icons.receipt,
                label: loc.yourBill,
                index: 3,
                onTap: _goToBill,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int? badge,
    required VoidCallback onTap,
  }) {
    final isActive = _currentNavIndex == index;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 24,
                  color: isActive
                      ? AppTheme.primaryColor
                      : AppTheme.textLight,
                ),
                if (badge != null)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                          minWidth: 16, minHeight: 16),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? AppTheme.primaryColor
                    : AppTheme.textLight,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<FoodProvider>()
                  .fetchFoodsByHotel(widget.restaurantId,
                      menuType: 'dine_in'),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.noItemsFound,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.tryDifferentSearch,
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}