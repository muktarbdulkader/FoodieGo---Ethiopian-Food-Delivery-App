import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/promotion.dart';
import '../../../data/services/api_service.dart';

class ManagePromotionsPage extends StatefulWidget {
  const ManagePromotionsPage({super.key});

  @override
  State<ManagePromotionsPage> createState() => _ManagePromotionsPageState();
}

class _ManagePromotionsPageState extends State<ManagePromotionsPage> {
  List<Promotion> _promotions = [];
  bool _isLoading = true;

  // Promo type options
  static const List<Map<String, String>> _promoTypes = [
    {'value': 'food_discount', 'label': '🍔 Food Discount'},
    {'value': 'delivery_free', 'label': '🚚 Free Delivery'},
    {'value': 'event_discount', 'label': '🎉 Event Discount'},
    {'value': 'new_user', 'label': '🆕 New User'},
    {'value': 'special_offer', 'label': '⭐ Special Offer'},
  ];

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    try {
      // Load hotel-specific promotions
      final response = await ApiService.get('/promotions/hotel');
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _promotions = data.map((json) => Promotion.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditDialog([Promotion? promo]) {
    final isEdit = promo != null;
    final codeController = TextEditingController(text: promo?.code ?? '');
    final descController =
        TextEditingController(text: promo?.description ?? '');
    final valueController =
        TextEditingController(text: promo?.discountValue.toString() ?? '10');
    final minOrderController =
        TextEditingController(text: promo?.minOrderAmount.toString() ?? '0');
    String discountType = promo?.discountType ?? 'percentage';
    String promoType = promo?.promoType ?? 'food_discount';
    DateTime startDate = promo?.startDate ?? DateTime.now();
    DateTime endDate =
        promo?.endDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = promo?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Promotion' : 'Add Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Promo Code',
                    hintText: 'e.g., SAVE20',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'e.g., 20% off on all orders',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                // Promo Type Selector
                DropdownButtonFormField<String>(
                  value: promoType,
                  decoration:
                      const InputDecoration(labelText: 'Promotion Purpose'),
                  items: _promoTypes
                      .map((type) => DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => promoType = v!),
                ),
                const SizedBox(height: 12),
                // Discount Type - Full width
                DropdownButtonFormField<String>(
                  value: discountType,
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(
                        value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (v) => setDialogState(() => discountType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: discountType == 'percentage'
                        ? 'Discount %'
                        : 'Amount (ETB)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(
                    labelText: 'Min Order Amount (ETB)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null)
                            setDialogState(() => startDate = date);
                        },
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Start Date'),
                          child: Text(
                              '${startDate.day}/${startDate.month}/${startDate.year}'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null)
                            setDialogState(() => endDate = date);
                        },
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'End Date'),
                          child: Text(
                              '${endDate.day}/${endDate.month}/${endDate.year}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _savePromotion(
                ctx,
                isEdit,
                promo?.id,
                codeController.text,
                descController.text,
                discountType,
                promoType,
                double.tryParse(valueController.text) ?? 10,
                double.tryParse(minOrderController.text) ?? 0,
                startDate,
                endDate,
                isActive,
              ),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              child: Text(isEdit ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePromotion(
    BuildContext ctx,
    bool isEdit,
    String? promoId,
    String code,
    String description,
    String discountType,
    String promoType,
    double discountValue,
    double minOrderAmount,
    DateTime startDate,
    DateTime endDate,
    bool isActive,
  ) async {
    if (code.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final data = {
      'code': code.toUpperCase(),
      'description': description,
      'discountType': discountType,
      'promoType': promoType,
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };

    try {
      if (isEdit && promoId != null) {
        await ApiService.put('/promotions/$promoId', data);
      } else {
        await ApiService.post('/promotions', data);
      }
      if (mounted) {
        Navigator.pop(ctx);
        _loadPromotions();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Promotion updated!' : 'Promotion created!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deletePromotion(Promotion promo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Delete promo code "${promo.code}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.delete('/promotions/${promo.id}');
        _loadPromotions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Promotion deleted'),
                backgroundColor: Color(0xFF10B981)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Manage Promotions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Promo'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _promotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No promotions yet',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Tap + to create your first promo code',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPromotions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) =>
                        _buildPromoCard(_promotions[index]),
                  ),
                ),
    );
  }

  Widget _buildPromoCard(Promotion promo) {
    final isExpired = promo.endDate.isBefore(DateTime.now());
    final isActive = promo.isActive && !isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [AppTheme.primaryColor, const Color(0xFF8B5CF6)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promo.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo.discountText,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      Text(
                        promo.promoTypeLabel,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF10B981) : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isExpired ? 'Expired' : (isActive ? 'Active' : 'Inactive'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today,
                        '${promo.startDate.day}/${promo.startDate.month} - ${promo.endDate.day}/${promo.endDate.month}'),
                    const SizedBox(width: 8),
                    if (promo.minOrderAmount > 0)
                      _buildInfoChip(Icons.shopping_bag,
                          'Min: ETB ${promo.minOrderAmount.toInt()}'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAddEditDialog(promo),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => _deletePromotion(promo),
                      icon:
                          const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
