import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Professional category selector with icons and subcategories
/// Used by restaurants/hotels for adding food items
class CategorySelector extends StatefulWidget {
  final String? initialCategory;
  final Function(String) onCategorySelected;

  const CategorySelector({
    super.key,
    this.initialCategory,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  String? _selectedMainCategory;
  String? _selectedSubCategory;
  final TextEditingController _customCategoryCtrl = TextEditingController();
  bool _showCustomInput = false;

  // Professional restaurant categories with icons and subcategories
  final Map<String, CategoryData> _categories = {
    'Beverages': CategoryData(
      icon: Icons.local_drink,
      color: const Color(0xFF3B82F6),
      subcategories: [
        'Tea',
        'Coffee',
        'Soft Drinks',
        'Juice',
        'Water',
        'Energy Drinks',
        'Smoothies',
        'Milkshakes',
      ],
    ),
    'Food': CategoryData(
      icon: Icons.restaurant_menu,
      color: const Color(0xFFEF4444),
      subcategories: [
        'Main Course',
        'Appetizers',
        'Starters',
        'Soups',
        'Salads',
        'Side Dishes',
      ],
    ),
    'Fast Food': CategoryData(
      icon: Icons.fastfood,
      color: const Color(0xFFF59E0B),
      subcategories: [
        'Burgers',
        'Pizza',
        'Sandwiches',
        'Hot Dogs',
        'Fries',
        'Wraps',
      ],
    ),
    'Ethiopian': CategoryData(
      icon: Icons.restaurant,
      color: const Color(0xFF10B981),
      subcategories: [
        'Tibs',
        'Kitfo',
        'Doro Wot',
        'Shiro',
        'Fasting Food',
        'Beyaynetu',
      ],
    ),
    'Desserts': CategoryData(
      icon: Icons.cake,
      color: const Color(0xFFEC4899),
      subcategories: [
        'Cakes',
        'Ice Cream',
        'Pastries',
        'Cookies',
        'Pudding',
        'Traditional Sweets',
      ],
    ),
    'Breakfast': CategoryData(
      icon: Icons.free_breakfast,
      color: const Color(0xFF8B5CF6),
      subcategories: [
        'Eggs',
        'Pancakes',
        'Oatmeal',
        'Toast',
        'Cereal',
        'Ful',
        'Firfir',
      ],
    ),
    'Seafood': CategoryData(
      icon: Icons.set_meal,
      color: const Color(0xFF06B6D4),
      subcategories: [
        'Fish',
        'Shrimp',
        'Crab',
        'Lobster',
        'Sushi',
        'Grilled Seafood',
      ],
    ),
    'Bakery': CategoryData(
      icon: Icons.bakery_dining,
      color: const Color(0xFFF97316),
      subcategories: [
        'Bread',
        'Croissants',
        'Muffins',
        'Donuts',
        'Bagels',
        'Dabo',
      ],
    ),
    'Vegetarian': CategoryData(
      icon: Icons.eco,
      color: const Color(0xFF22C55E),
      subcategories: [
        'Vegan Dishes',
        'Salads',
        'Veggie Burgers',
        'Fasting Food',
        'Tofu Dishes',
      ],
    ),
    'Snacks': CategoryData(
      icon: Icons.cookie,
      color: const Color(0xFFA855F7),
      subcategories: [
        'Chips',
        'Nuts',
        'Popcorn',
        'Samosas',
        'Spring Rolls',
        'Kolo',
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _initializeFromCategory(widget.initialCategory!);
    }
  }

  void _initializeFromCategory(String category) {
    // Check if it's a subcategory
    for (var entry in _categories.entries) {
      if (entry.value.subcategories.contains(category)) {
        setState(() {
          _selectedMainCategory = entry.key;
          _selectedSubCategory = category;
        });
        return;
      }
    }
    // Check if it's a main category
    if (_categories.containsKey(category)) {
      setState(() {
        _selectedMainCategory = category;
      });
    } else {
      // Custom category
      setState(() {
        _showCustomInput = true;
        _customCategoryCtrl.text = category;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCustomInput = !_showCustomInput;
                  if (_showCustomInput) {
                    _selectedMainCategory = null;
                    _selectedSubCategory = null;
                  } else {
                    _customCategoryCtrl.clear();
                  }
                });
              },
              icon: Icon(
                _showCustomInput ? Icons.grid_view : Icons.edit,
                size: 18,
              ),
              label: Text(_showCustomInput ? 'Use Presets' : 'Custom'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_showCustomInput)
          _buildCustomInput()
        else
          _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildCustomInput() {
    return TextField(
      controller: _customCategoryCtrl,
      decoration: InputDecoration(
        labelText: 'Enter Custom Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        widget.onCategorySelected(value);
      },
    );
  }

  Widget _buildCategoryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Categories
        const Text(
          'Select Main Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.entries.map((entry) {
            final isSelected = _selectedMainCategory == entry.key;
            return _buildCategoryButton(
              label: entry.key,
              icon: entry.value.icon,
              color: entry.value.color,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedMainCategory = entry.key;
                  _selectedSubCategory = null;
                });
                // If no subcategories, use main category
                if (entry.value.subcategories.isEmpty) {
                  widget.onCategorySelected(entry.key);
                }
              },
            );
          }).toList(),
        ),
        
        // Subcategories
        if (_selectedMainCategory != null &&
            _categories[_selectedMainCategory]!.subcategories.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Select $_selectedMainCategory Type',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories[_selectedMainCategory]!
                .subcategories
                .map((sub) {
              final isSelected = _selectedSubCategory == sub;
              return _buildSubCategoryChip(
                label: sub,
                color: _categories[_selectedMainCategory]!.color,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedSubCategory = sub;
                  });
                  widget.onCategorySelected(sub);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip({
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customCategoryCtrl.dispose();
    super.dispose();
  }
}

class CategoryData {
  final IconData icon;
  final Color color;
  final List<String> subcategories;

  CategoryData({
    required this.icon,
    required this.color,
    required this.subcategories,
  });
}
