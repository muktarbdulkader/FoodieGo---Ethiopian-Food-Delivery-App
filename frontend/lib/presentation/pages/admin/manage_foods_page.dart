import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/food/food_provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/loading_widget.dart';

class ManageFoodsPage extends StatefulWidget {
  const ManageFoodsPage({super.key});

  @override
  State<ManageFoodsPage> createState() => _ManageFoodsPageState();
}

class _ManageFoodsPageState extends State<ManageFoodsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FoodProvider>().fetchFoods();
    });
  }

  void _showAddFoodDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final prepTimeCtrl = TextEditingController(text: '20');
    final caloriesCtrl = TextEditingController(text: '500');
    String category = 'Main Course';
    bool isVegetarian = false;
    bool isSpicy = false;
    bool isFeatured = false;

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
                      child: const Icon(Icons.restaurant_menu,
                          color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add New Food',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
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
                            prepTimeCtrl, 'Prep Time (min)', Icons.timer,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildTextField(imageCtrl, 'Image URL (optional)', Icons.image),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: [
                    'Main Course',
                    'Appetizer',
                    'Dessert',
                    'Drinks',
                    'Pizza',
                    'Burger',
                    'Sushi',
                    'Ethiopian',
                    'Fast Food',
                    'Salad',
                  ]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
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
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text('Please fill required fields'),
                            backgroundColor: AppTheme.errorColor),
                      );
                      return;
                    }

                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);
                    final foodProvider = context.read<FoodProvider>();

                    final success =
                        await context.read<AdminProvider>().createFood({
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'category': category,
                      'image': imageCtrl.text.isNotEmpty
                          ? imageCtrl.text
                          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                      'preparationTime': int.tryParse(prepTimeCtrl.text) ?? 20,
                      'calories': int.tryParse(caloriesCtrl.text) ?? 500,
                      'isVegetarian': isVegetarian,
                      'isSpicy': isSpicy,
                      'isFeatured': isFeatured,
                    });

                    if (success) {
                      navigator.pop();
                      foodProvider.fetchFoods();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                            content: Text('Food added successfully!'),
                            backgroundColor: AppTheme.successColor),
                      );
                    }
                  },
                  child: const Text('Add Food',
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              if (value == 'delete') {
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
