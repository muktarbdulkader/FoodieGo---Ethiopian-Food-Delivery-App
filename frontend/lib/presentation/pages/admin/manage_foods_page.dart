import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../../state/food/food_provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/admin_auth_check.dart';
import '../../widgets/category_selector.dart';

class ManageFoodsPage extends StatefulWidget {
  const ManageFoodsPage({super.key});

  @override
  State<ManageFoodsPage> createState() => _ManageFoodsPageState();
}

class _ManageFoodsPageState extends State<ManageFoodsPage> {
  @override
  void initState() {
    super.initState();
    // Session type is set by AdminAuthCheck wrapper
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().fetchFoods();
    });
  }

  void _showAddFoodDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final deliveryPriceCtrl = TextEditingController();
    final dineInPriceCtrl = TextEditingController();
    final takeawayPriceCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final prepTimeCtrl = TextEditingController(text: '20');
    final caloriesCtrl = TextEditingController(text: '500');
    final discountCtrl = TextEditingController(text: '0');
    String category = 'Main Course';
    bool isVegetarian = false;
    bool isSpicy = false;
    bool isFeatured = false;
    bool isDelivery = true;
    bool isDineIn = false;
    bool isTakeaway = false;
    Uint8List? selectedImageBytes;
    String? base64Image;

    Future<void> pickImage(StateSetter setModalState) async {
      final picker = ImagePicker();
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          final bytes = await pickedFile.readAsBytes();
          setModalState(() {
            selectedImageBytes = bytes;
            base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
            imageCtrl.text = '';
          });
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.restaurant_menu,
                          color: AppTheme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Add New Food Item',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Image Section
                _buildSectionTitle('Food Image'),
                GestureDetector(
                  onTap: () => pickImage(setModalState),
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: selectedImageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(selectedImageBytes!,
                                    fit: BoxFit.cover),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() {
                                      selectedImageBytes = null;
                                      base64Image = null;
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined,
                                  size: 40, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('Tap to add food image',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Or use URL
                Row(
                  children: [
                    Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    Expanded(
                        child:
                            Divider(color: Colors.grey.shade300, thickness: 1)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildModernTextField(
                    imageCtrl, 'Image URL (optional)', Icons.link),
                const SizedBox(height: 20),

                // Basic Info Section
                _buildSectionTitle('Basic Information'),
                _buildModernTextField(nameCtrl, 'Food Name', Icons.fastfood),
                const SizedBox(height: 12),
                _buildModernTextField(
                    descCtrl, 'Description', Icons.description,
                    maxLines: 2),
                const SizedBox(height: 20),

                // Menu Types Section (moved before pricing)
                _buildSectionTitle('Available For'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildMenuTypeChip(
                      label: 'Delivery',
                      icon: Icons.delivery_dining,
                      color: const Color(0xFF3B82F6),
                      isSelected: isDelivery,
                      onSelected: (v) => setModalState(() => isDelivery = v),
                    ),
                    _buildMenuTypeChip(
                      label: 'Dine-In',
                      icon: Icons.restaurant,
                      color: const Color(0xFF8B5CF6),
                      isSelected: isDineIn,
                      onSelected: (v) => setModalState(() => isDineIn = v),
                    ),
                    _buildMenuTypeChip(
                      label: 'Takeaway',
                      icon: Icons.takeout_dining,
                      color: const Color(0xFF10B981),
                      isSelected: isTakeaway,
                      onSelected: (v) => setModalState(() => isTakeaway = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Pricing Section - Dynamic based on selected menu types
                if (isDelivery || isDineIn || isTakeaway) ...[
                  _buildSectionTitle('Pricing'),
                  const SizedBox(height: 12),

                  // Delivery Price
                  if (isDelivery) ...[
                    _buildPriceField(
                      controller: deliveryPriceCtrl,
                      label: 'Delivery Price (ETB)',
                      icon: Icons.delivery_dining,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Dine-In Price
                  if (isDineIn) ...[
                    _buildPriceField(
                      controller: dineInPriceCtrl,
                      label: 'Dine-In Price (ETB)',
                      icon: Icons.restaurant,
                      color: const Color(0xFF8B5CF6),
                      hint: 'Same as delivery if empty',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Takeaway Price
                  if (isTakeaway) ...[
                    _buildPriceField(
                      controller: takeawayPriceCtrl,
                      label: 'Takeaway Price (ETB)',
                      icon: Icons.takeout_dining,
                      color: const Color(0xFF10B981),
                      hint: 'Same as delivery if empty',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Discount (always visible when any menu type selected)
                  _buildPriceField(
                    controller: discountCtrl,
                    label: 'Discount %',
                    icon: Icons.local_offer_outlined,
                    color: const Color(0xFFEF4444),
                    isNumber: true,
                  ),
                  const SizedBox(height: 20),
                ],

                // Additional Details
                _buildSectionTitle('Additional Details'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildModernTextField(prepTimeCtrl,
                            'Prep Time (min)', Icons.timer_outlined,
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildModernTextField(caloriesCtrl, 'Calories',
                            Icons.local_fire_department_outlined,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Section
                CategorySelector(
                  initialCategory: category,
                  onCategorySelected: (selectedCategory) {
                    setModalState(() {
                      category = selectedCategory;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Tags
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildTagChip(
                      label: 'Vegetarian',
                      icon: Icons.eco,
                      isSelected: isVegetarian,
                      onSelected: (v) => setModalState(() => isVegetarian = v),
                      color: const Color(0xFF22C55E),
                    ),
                    _buildTagChip(
                      label: 'Spicy',
                      icon: Icons.whatshot,
                      isSelected: isSpicy,
                      onSelected: (v) => setModalState(() => isSpicy = v),
                      color: const Color(0xFFEF4444),
                    ),
                    _buildTagChip(
                      label: 'Featured',
                      icon: Icons.star,
                      isSelected: isFeatured,
                      onSelected: (v) => setModalState(() => isFeatured = v),
                      color: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Add Food Button
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, _) {
                    final isLoading = adminProvider.isLoading;
                    
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: isLoading ? null : () async {
                        // Validate at least one menu type is selected
                        if (!isDelivery && !isDineIn && !isTakeaway) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please select at least one menu type'),
                                backgroundColor: AppTheme.errorColor,
                                duration: Duration(seconds: 2)),
                          );
                          return;
                        }

                        // Validate required fields
                        if (nameCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter food name'),
                                backgroundColor: AppTheme.errorColor,
                                duration: Duration(seconds: 2)),
                          );
                          return;
                        }

                        // Check that at least one price is entered for selected menu types
                        if (isDelivery && deliveryPriceCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter delivery price'),
                                backgroundColor: AppTheme.errorColor,
                                duration: Duration(seconds: 2)),
                          );
                          return;
                        }

                        // Build menuTypes array
                        List<String> menuTypes = [];
                        if (isDelivery) menuTypes.add('delivery');
                        if (isDineIn) menuTypes.add('dine_in');
                        if (isTakeaway) menuTypes.add('takeaway');

                        final finalCategory = category;

                        // Determine image: base64 > URL > default
                        String imageValue;
                        if (base64Image != null) {
                          imageValue = base64Image!;
                        } else if (imageCtrl.text.isNotEmpty) {
                          imageValue = imageCtrl.text;
                        } else {
                          imageValue =
                              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400';
                        }

                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);
                        final foodProvider = context.read<FoodProvider>();

                        // Build food data with proper pricing
                        final foodData = {
                          'name': nameCtrl.text,
                          'description': descCtrl.text,
                          'price': double.tryParse(deliveryPriceCtrl.text) ?? 0,
                          'discount': int.tryParse(discountCtrl.text) ?? 0,
                          'category': finalCategory,
                          'image': imageValue,
                          'preparationTime': int.tryParse(prepTimeCtrl.text) ?? 20,
                          'calories': int.tryParse(caloriesCtrl.text) ?? 500,
                          'isVegetarian': isVegetarian,
                          'isSpicy': isSpicy,
                          'isFeatured': isFeatured,
                          'menuTypes': menuTypes,
                        };

                        // Add dineInPrice if provided
                        if (dineInPriceCtrl.text.isNotEmpty) {
                          final dineInPrice = double.tryParse(dineInPriceCtrl.text);
                          if (dineInPrice != null) {
                            foodData['dineInPrice'] = dineInPrice;
                          }
                        }

                        // Add takeawayPrice if provided
                        if (takeawayPriceCtrl.text.isNotEmpty) {
                          final takeawayPrice =
                              double.tryParse(takeawayPriceCtrl.text);
                          if (takeawayPrice != null) {
                            foodData['takeawayPrice'] = takeawayPrice;
                          }
                        }

                        try {
                          final success = await context
                              .read<AdminProvider>()
                              .createFood(foodData);

                          if (success) {
                            navigator.pop();
                            foodProvider.fetchFoods();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 12),
                                    Text('${nameCtrl.text} added!'),
                                  ],
                                ),
                                backgroundColor: AppTheme.successColor,
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Failed: ${context.read<AdminProvider>().error ?? "Unknown error"}'),
                                  backgroundColor: AppTheme.errorColor,
                                  duration: const Duration(seconds: 3)),
                            );
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: AppTheme.errorColor,
                                duration: const Duration(seconds: 3)),
                          );
                        }
                      },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Add Food',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditFoodDialog(food) {
    final nameCtrl = TextEditingController(text: food.name);
    final descCtrl = TextEditingController(text: food.description ?? '');
    final priceCtrl = TextEditingController(text: food.price.toString());
    final discountCtrl =
        TextEditingController(text: (food.discount ?? 0).toString());
    final prepTimeCtrl =
        TextEditingController(text: (food.preparationTime ?? 20).toString());
    bool isVegetarian = food.isVegetarian ?? false;
    bool isSpicy = food.isSpicy ?? false;
    bool isFeatured = food.isFeatured ?? false;
    bool isAvailable = food.isAvailable ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          const Icon(Icons.edit, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Edit ${food.name}',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(nameCtrl, 'Food Name', Icons.fastfood),
                const SizedBox(height: 12),
                _buildTextField(descCtrl, 'Description', Icons.description,
                    maxLines: 2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildTextField(
                            priceCtrl, 'Price (ETB)', Icons.attach_money,
                            isNumber: true)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField(
                            discountCtrl, 'Discount %', Icons.local_offer,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(prepTimeCtrl, 'Prep Time (min)', Icons.timer,
                    isNumber: true),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Available'),
                      selected: isAvailable,
                      onSelected: (v) => setModalState(() => isAvailable = v),
                      selectedColor:
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF10B981),
                    ),
                    FilterChip(
                      label: const Text('Vegetarian'),
                      selected: isVegetarian,
                      onSelected: (v) => setModalState(() => isVegetarian = v),
                      selectedColor:
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF10B981),
                    ),
                    FilterChip(
                      label: const Text('Spicy'),
                      selected: isSpicy,
                      onSelected: (v) => setModalState(() => isSpicy = v),
                      selectedColor:
                          const Color(0xFFEF4444).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFFEF4444),
                    ),
                    FilterChip(
                      label: const Text('Featured'),
                      selected: isFeatured,
                      onSelected: (v) => setModalState(() => isFeatured = v),
                      selectedColor:
                          const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFFF59E0B),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);
                    final foodProvider = context.read<FoodProvider>();

                    final success = await context
                        .read<AdminProvider>()
                        .updateFood(food.id, {
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'price': double.tryParse(priceCtrl.text) ?? food.price,
                      'discount': int.tryParse(discountCtrl.text) ?? 0,
                      'preparationTime': int.tryParse(prepTimeCtrl.text) ?? 20,
                      'isVegetarian': isVegetarian,
                      'isSpicy': isSpicy,
                      'isFeatured': isFeatured,
                      'isAvailable': isAvailable,
                    });

                    if (success) {
                      navigator.pop();
                      foodProvider.fetchFoods();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text('Food updated!'),
                            backgroundColor: AppTheme.successColor),
                      );
                    }
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  // New helper methods for improved Add Food dialog
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildModernTextField(
      TextEditingController controller, String label, IconData icon,
      {int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildMenuTypeChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: isSelected ? color : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? hint,
    bool isNumber = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        suffixIcon: label.contains('Discount')
            ? Container(
                margin: const EdgeInsets.only(right: 12),
                child: Chip(
                  label: const Text('%'),
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.1),
                  side: BorderSide.none,
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildTagChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return InkWell(
      onTap: () => onSelected(!isSelected),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade400,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminAuthCheck(
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user?.hotelName),
            Expanded(
              child: Consumer<FoodProvider>(
                builder: (context, foodProvider, _) {
                  if (foodProvider.isLoading) return const LoadingWidget();

                  final foods = foodProvider.foods;
                  if (foods.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No food items yet',
                              style: TextStyle(
                                  fontSize: 18, color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          const Text('Add your first menu item',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: foods.length,
                    itemBuilder: (context, index) =>
                        _buildFoodTile(foods[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Food', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildHeader(String? hotelName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.arrow_back_ios_new, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Manage Foods',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    if (hotelName != null)
                      Text(hotelName,
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTile(food) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)
          ]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Image.network(
              food.image,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                child:
                    const Icon(Icons.restaurant, color: AppTheme.primaryColor),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(food.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (food.discount != null && food.discount > 0)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('-${food.discount}%',
                              style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (food.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Featured',
                              style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(food.category,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                          '${AppConstants.currency}${food.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: food.isAvailable
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          food.isAvailable ? 'Available' : 'Unavailable',
                          style: TextStyle(
                            color: food.isAvailable
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onSelected: (value) async {
              if (value == 'edit') {
                _showEditFoodDialog(food);
              } else if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Delete Food?'),
                    content:
                        Text('Are you sure you want to delete ${food.name}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete',
                              style: TextStyle(color: AppTheme.errorColor))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await context.read<AdminProvider>().deleteFood(food.id);
                  if (mounted) {
                    context.read<FoodProvider>().fetchFoods();
                  }
                }
              } else if (value == 'toggle') {
                // Toggle availability
                await context.read<AdminProvider>().updateFood(food.id, {
                  'isAvailable': !food.isAvailable,
                });
                if (mounted) {
                  context.read<FoodProvider>().fetchFoods();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 20),
                    SizedBox(width: 8),
                    Text('Toggle Availability'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Delete',
                        style: TextStyle(color: AppTheme.errorColor)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
