# Professional Category Selector for Restaurant Admin

## ✅ New Feature Created

I've created a **professional category selector widget** that restaurants/hotels use worldwide for adding food items.

## 📁 File Created

`frontend/lib/presentation/widgets/category_selector.dart`

## 🎨 Features

### **Main Categories with Icons:**
1. 🥤 **Beverages** (Blue)
   - Tea
   - Coffee
   - Soft Drinks
   - Juice
   - Water
   - Energy Drinks
   - Smoothies
   - Milkshakes

2. 🍽️ **Food** (Red)
   - Main Course
   - Appetizers
   - Starters
   - Soups
   - Salads
   - Side Dishes

3. 🍔 **Fast Food** (Orange)
   - Burgers
   - Pizza
   - Sandwiches
   - Hot Dogs
   - Fries
   - Wraps

4. 🇪🇹 **Ethiopian** (Green)
   - Tibs
   - Kitfo
   - Doro Wot
   - Shiro
   - Fasting Food
   - Beyaynetu

5. 🍰 **Desserts** (Pink)
   - Cakes
   - Ice Cream
   - Pastries
   - Cookies
   - Pudding
   - Traditional Sweets

6. 🌅 **Breakfast** (Purple)
   - Eggs
   - Pancakes
   - Oatmeal
   - Toast
   - Cereal
   - Ful
   - Firfir

7. 🐟 **Seafood** (Cyan)
   - Fish
   - Shrimp
   - Crab
   - Lobster
   - Sushi
   - Grilled Seafood

8. 🥖 **Bakery** (Orange)
   - Bread
   - Croissants
   - Muffins
   - Donuts
   - Bagels
   - Dabo

9. 🌱 **Vegetarian** (Green)
   - Vegan Dishes
   - Salads
   - Veggie Burgers
   - Fasting Food
   - Tofu Dishes

10. 🍪 **Snacks** (Purple)
    - Chips
    - Nuts
    - Popcorn
    - Samosas
    - Spring Rolls
    - Kolo

### **Additional Features:**
- ✅ Color-coded categories
- ✅ Icon for each category
- ✅ Two-level selection (Main → Subcategory)
- ✅ Custom category option
- ✅ Visual feedback on selection
- ✅ Professional UI design

## 🔧 How to Use in manage_foods_page.dart

### Step 1: Add Import
```dart
import '../../widgets/category_selector.dart';
```

### Step 2: Replace Category Selection Code

**Find this code** (around line 350-380):
```dart
// Category selection with custom option
Row(
  children: [
    const Text('Category',
        style: TextStyle(fontWeight: FontWeight.w500)),
    const Spacer(),
    TextButton.icon(
      onPressed: () => setModalState(
          () => useCustomCategory = !useCustomCategory),
      icon: Icon(useCustomCategory ? Icons.list : Icons.add,
          size: 18),
      label: Text(useCustomCategory ? 'Use Preset' : 'Custom'),
    ),
  ],
),
const SizedBox(height: 8),
if (useCustomCategory)
  _buildTextField(customCategoryCtrl, 'Enter Custom Category',
      Icons.category)
else
  DropdownButtonFormField<String>(
    initialValue: category,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.category),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey.shade50,
    ),
    items: defaultCategories
        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
        .toList(),
    onChanged: (v) => setModalState(() => category = v!),
  ),
```

**Replace with:**
```dart
CategorySelector(
  initialCategory: category,
  onCategorySelected: (selectedCategory) {
    setModalState(() {
      category = selectedCategory;
    });
  },
),
```

### Step 3: Remove Old Variables

You can remove these variables from the `_showAddFoodDialog()` method:
```dart
final customCategoryCtrl = TextEditingController();  // Remove
bool useCustomCategory = false;  // Remove
final defaultCategories = [...];  // Remove
```

## 📱 User Experience

### For Admin Adding Food:

1. **Click "Add Food"** button
2. **Select Main Category** (e.g., "Beverages")
   - See colorful buttons with icons
3. **Select Subcategory** (e.g., "Tea", "Coffee", "Soft Drinks")
   - Chips appear below main category
4. **Or Use Custom** 
   - Toggle to "Custom" button
   - Enter any category name

### Visual Flow:
```
Main Categories (Grid with Icons)
    ↓
[🥤 Beverages] [🍽️ Food] [🍔 Fast Food] ...
    ↓ (Select Beverages)
    ↓
Subcategories (Chips)
    ↓
[Tea] [Coffee] [Soft Drinks] [Juice] [Water] ...
    ↓ (Select Tea)
    ↓
Category = "Tea" ✅
```

## 🎯 Benefits

1. **Faster Input** - Click instead of typing
2. **Consistency** - Standardized categories
3. **Professional** - Like major restaurant apps
4. **Flexible** - Can still use custom categories
5. **Visual** - Icons and colors for quick recognition
6. **Organized** - Two-level hierarchy (Main → Sub)

## 🚀 Deploy

After making the changes:

```bash
cd frontend
flutter build web
firebase deploy --only hosting
```

## 📸 What It Looks Like

```
┌─────────────────────────────────────┐
│  Category                  [Custom] │
├─────────────────────────────────────┤
│  Select Main Category               │
│                                     │
│  [🥤 Beverages] [🍽️ Food]          │
│  [🍔 Fast Food] [🇪🇹 Ethiopian]     │
│  [🍰 Desserts]  [🌅 Breakfast]      │
│  [🐟 Seafood]   [🥖 Bakery]         │
│  [🌱 Vegetarian] [🍪 Snacks]        │
│                                     │
│  Select Beverages Type              │
│                                     │
│  (Tea) (Coffee) (Soft Drinks)       │
│  (Juice) (Water) (Energy Drinks)    │
│  (Smoothies) (Milkshakes)           │
└─────────────────────────────────────┘
```

## 💡 Customization

To add more categories, edit `category_selector.dart`:

```dart
final Map<String, CategoryData> _categories = {
  'Your Category': CategoryData(
    icon: Icons.your_icon,
    color: const Color(0xFFYOURCOLOR),
    subcategories: [
      'Sub 1',
      'Sub 2',
      'Sub 3',
    ],
  ),
};
```

---

**Ready to use!** This is the same professional category selection system used by major restaurant chains worldwide. 🌟
