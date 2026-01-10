import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/food/food_provider.dart';
import '../../../data/models/promotion.dart';
import '../checkout/checkout_page.dart';

class PromotionsPage extends StatefulWidget {
  const PromotionsPage({super.key});

  @override
  State<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends State<PromotionsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    await context.read<FoodProvider>().fetchPromotions();
    if (mounted) setState(() => _isLoading = false);
  }

  void _copyPromoCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Promo code "$code" copied!'),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Consumer<FoodProvider>(
                      builder: (context, provider, _) {
                        final promotions = provider.promotions;
                        if (promotions.isEmpty) {
                          return _buildEmptyState();
                        }
                        return RefreshIndicator(
                          onRefresh: _loadPromotions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: promotions.length,
                            itemBuilder: (context, index) =>
                                _buildPromoCard(promotions[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
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
                  '🎁 Promotions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Save more on your orders',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_offer_outlined,
                size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Promotions Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back later for exciting offers!',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Promotion promo) {
    final isExpired = promo.endDate.isBefore(DateTime.now());
    final daysLeft = promo.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Top colored banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isExpired
                  ? LinearGradient(
                      colors: [Colors.grey.shade400, Colors.grey.shade500])
                  : AppTheme.primaryGradient,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(promo.promoTypeIcon,
                      style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.discountText,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        promo.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Promo code with copy button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.confirmation_number_outlined,
                              color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            promo.code,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap:
                            isExpired ? null : () => _copyPromoCode(promo.code),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient:
                                isExpired ? null : AppTheme.primaryGradient,
                            color: isExpired ? Colors.grey.shade300 : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.copy,
                                  size: 16,
                                  color:
                                      isExpired ? Colors.grey : Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  color: isExpired ? Colors.grey : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Details row
                Row(
                  children: [
                    _buildDetailChip(
                      Icons.shopping_bag_outlined,
                      'Min: ETB ${promo.minOrderAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(width: 10),
                    if (promo.maxDiscount != null)
                      _buildDetailChip(
                        Icons.savings_outlined,
                        'Max: ETB ${promo.maxDiscount!.toStringAsFixed(0)}',
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withValues(alpha: 0.1)
                            : daysLeft <= 3
                                ? Colors.orange.withValues(alpha: 0.1)
                                : AppTheme.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: isExpired
                                ? Colors.red
                                : daysLeft <= 3
                                    ? Colors.orange
                                    : AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpired
                                ? 'Expired'
                                : daysLeft == 0
                                    ? 'Ends today'
                                    : '$daysLeft days left',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isExpired
                                  ? Colors.red
                                  : daysLeft <= 3
                                      ? Colors.orange
                                      : AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (promo.hotelName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Valid at: ${promo.hotelName}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                // Use Now button
                GestureDetector(
                  onTap: isExpired
                      ? null
                      : () {
                          _copyPromoCode(promo.code);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CheckoutPage()),
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isExpired ? null : AppTheme.primaryGradient,
                      color: isExpired ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isExpired
                              ? Icons.block
                              : Icons.shopping_cart_checkout,
                          color: isExpired ? Colors.grey : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isExpired ? 'Expired' : 'Use Now',
                          style: TextStyle(
                            color: isExpired ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
