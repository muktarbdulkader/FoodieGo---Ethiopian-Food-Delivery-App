import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/cart/cart_provider.dart';
import '../../../state/dine_in/dine_in_provider.dart';
import '../../../state/language/language_provider.dart';
import '../../../data/models/cart_item.dart';
import 'order_status_page.dart';

class DineInCartPage extends StatefulWidget {
  final String restaurantId;
  final String tableId;

  const DineInCartPage({
    super.key,
    required this.restaurantId,
    required this.tableId,
  });

  @override
  State<DineInCartPage> createState() => _DineInCartPageState();
}

class _DineInCartPageState extends State<DineInCartPage> {
  bool _isPlacingOrder = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    setState(() => _isPlacingOrder = true);

    try {
      final dineIn = context.read<DineInProvider>();
      final subtotal = cart.totalPrice;
      final tax = subtotal * 0.0; // no tax for dine-in
      final total = subtotal + tax;

      final order = await cart.placeOrderDineIn(
        restaurantId: widget.restaurantId,
        tableId: widget.tableId,
        subtotal: subtotal,
        tax: tax,
        totalPrice: total,
        guestSessionId: dineIn.guestSessionId,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      if (order != null) {
        // Navigate to order status page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderStatusPage(
              tableId: widget.tableId,
              restaurantId: widget.restaurantId,
              guestSessionId: dineIn.guestSessionId,
            ),
          ),
        );
      } else {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to place order. Please try again.'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final dineIn = context.watch<DineInProvider>();
    final loc = context.watch<LanguageProvider>().loc;
    final tableNumber = dineIn.getTableNumber() ?? '';

    return Scaffold(
      backgroundColor: AppTheme.premiumDark,
      appBar: AppBar(
        backgroundColor: AppTheme.premiumDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.premiumGold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.yourCart,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (tableNumber.isNotEmpty)
              Text(
                '${loc.table} $tableNumber',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
          ],
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text(loc.clearCart),
                    content: const Text('Remove all items from cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(loc.cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clearCart();
                          Navigator.pop(context);
                        },
                        child: Text(loc.clearCart,
                            style: const TextStyle(color: AppTheme.errorColor)),
                      ),
                    ],
                  ),
                );
              },
              child: Text(loc.clearCart,
                  style: const TextStyle(
                      color: AppTheme.errorColor, fontSize: 13)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(loc)
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Cart items
                      ...cart.items.map((item) => _buildCartItem(item, cart)),

                      const SizedBox(height: 16),

                      // Notes field
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.premiumDarkGrey,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.specialInstructions,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: loc.specialInstructionsHint,
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 13),
                                filled: true,
                                fillColor: AppTheme.premiumDark,
                                contentPadding: const EdgeInsets.all(12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: AppTheme.premiumGold, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Order summary
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.premiumDarkGrey,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _summaryRow(loc.subtotal,
                                'ETB ${cart.totalPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            _summaryRow(loc.deliveryFee, loc.free,
                                valueColor: Colors.green),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(height: 1),
                            ),
                            _summaryRow(
                              loc.total,
                              'ETB ${cart.totalPrice.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: AppTheme.premiumDarkGrey,
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
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isPlacingOrder ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.premiumGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isPlacingOrder
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                loc.placeOrder,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ETB ${cart.totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.premiumDarkGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.image.isNotEmpty
                ? Image.network(
                    item.image,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(width: 12),

          // Name + price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'ETB ${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Qty control
          Row(
            children: [
              _qtyBtn(
                icon: Icons.remove,
                onTap: () => cart.updateQuantity(item.foodId, item.quantity - 1),
                color: AppTheme.premiumDark,
                iconColor: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              _qtyBtn(
                icon: Icons.add,
                onTap: () => cart.updateQuantity(item.foodId, item.quantity + 1),
                color: AppTheme.premiumGold,
                iconColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: iconColor),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isBold ? Colors.white : Colors.grey[400],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ??
                (isBold ? AppTheme.premiumGold : Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCart(dynamic loc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            loc.emptyCart,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items from the menu',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Back to Menu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.premiumGold,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[100],
      child: Icon(Icons.restaurant, color: Colors.grey[300], size: 28),
    );
  }
}
