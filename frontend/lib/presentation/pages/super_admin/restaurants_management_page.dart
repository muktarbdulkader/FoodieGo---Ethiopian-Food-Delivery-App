import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class RestaurantsManagementPage extends StatefulWidget {
  const RestaurantsManagementPage({super.key});

  @override
  State<RestaurantsManagementPage> createState() => _RestaurantsManagementPageState();
}

class _RestaurantsManagementPageState extends State<RestaurantsManagementPage> {
  List<dynamic> _restaurants = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _statusFilter = 'all';
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final query = StringBuffer('?page=$_page&limit=20');
      if (_searchController.text.isNotEmpty) query.write('&search=${_searchController.text}');
      if (_statusFilter != 'all') query.write('&status=$_statusFilter');

      final response = await ApiService.get('/super-admin/restaurants$query');
      if (mounted) {
        setState(() {
          _restaurants = response['data'] ?? [];
          _total = response['count'] ?? 0;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> restaurant) async {
    final newStatus = !(restaurant['isActive'] ?? true);
    try {
      await ApiService.put(
        '/super-admin/restaurants/${restaurant['_id']}',
        {'isActive': newStatus},
      );
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${restaurant['hotelName']} ${newStatus ? 'activated' : 'deactivated'}'),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteRestaurant(Map<String, dynamic> restaurant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Restaurant'),
        content: Text('Delete "${restaurant['hotelName']}" and all its data? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.delete('/super-admin/restaurants/${restaurant['_id']}');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurant deleted'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRestaurantSheet,
        backgroundColor: const Color(0xFFFF6B35),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Restaurant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Restaurants', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          // Search & filter bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () { _searchController.clear(); _load(); },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _load(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('$_total restaurants', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'active', label: Text('Active')),
                        ButtonSegment(value: 'inactive', label: Text('Inactive')),
                      ],
                      selected: {_statusFilter},
                      onSelectionChanged: (s) { setState(() => _statusFilter = s.first); _load(); },
                      style: ButtonStyle(
                        textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!),
                          ElevatedButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ))
                    : _restaurants.isEmpty
                        ? const Center(child: Text('No restaurants found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _restaurants.length,
                              itemBuilder: (_, i) => _buildRestaurantCard(_restaurants[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> r) {
    final isActive = r['isActive'] ?? true;
    final isVerified = r['isVerified'] ?? false;
    final revenue = ((r['revenue'] ?? 0.0) as num).toStringAsFixed(0);
    final orderCount = r['orderCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    r['hotelImage'] ?? 'https://via.placeholder.com/50',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['hotelName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(r['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Row(
                        children: [
                          _buildBadge(isActive ? 'Active' : 'Inactive', isActive ? Colors.green : Colors.red),
                          const SizedBox(width: 6),
                          if (isVerified) _buildBadge('Verified', Colors.blue),
                          const SizedBox(width: 6),
                          _buildBadge(r['hotelCategory'] ?? 'restaurant', Colors.purple),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'toggle') _toggleActive(r);
                    if (action == 'delete') _deleteRestaurant(r);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(isActive ? Icons.block : Icons.check_circle, color: isActive ? Colors.orange : Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Deactivate' : 'Activate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildStat(Icons.receipt_long, '$orderCount orders', Colors.teal),
                const SizedBox(width: 16),
                _buildStat(Icons.attach_money, 'ETB $revenue', Colors.green),
                const SizedBox(width: 16),
                _buildStat(Icons.star, '${r['hotelRating'] ?? 4.5}', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  void _showAddRestaurantSheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final hotelNameCtrl = TextEditingController();
    final hotelAddressCtrl = TextEditingController();
    final hotelDescCtrl = TextEditingController();
    String category = 'restaurant';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.restaurant, color: Color(0xFFFF6B35), size: 24),
                      SizedBox(width: 10),
                      Text('Add Restaurant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Account Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _sheetField(nameCtrl, 'Owner Name', Icons.person, required: true),
                  const SizedBox(height: 12),
                  _sheetField(emailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress, required: true),
                  const SizedBox(height: 12),
                  _sheetField(passwordCtrl, 'Password', Icons.lock, obscure: true, required: true),
                  const SizedBox(height: 12),
                  _sheetField(phoneCtrl, 'Phone', Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  const Text('Restaurant Info', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _sheetField(hotelNameCtrl, 'Restaurant Name', Icons.store, required: true),
                  const SizedBox(height: 12),
                  _sheetField(hotelAddressCtrl, 'Address', Icons.location_on),
                  const SizedBox(height: 12),
                  _sheetField(hotelDescCtrl, 'Description', Icons.description, maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'restaurant', child: Text('Restaurant')),
                      DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
                      DropdownMenuItem(value: 'fast_food', child: Text('Fast Food')),
                      DropdownMenuItem(value: 'fine_dining', child: Text('Fine Dining')),
                      DropdownMenuItem(value: 'bakery', child: Text('Bakery')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setSheetState(() => category = v ?? 'restaurant'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setSheetState(() => isLoading = true);
                        try {
                          await ApiService.post('/super-admin/users', {
                            'name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'password': passwordCtrl.text,
                            'phone': phoneCtrl.text.trim(),
                            'role': 'restaurant',
                            'hotelName': hotelNameCtrl.text.trim(),
                            'hotelAddress': hotelAddressCtrl.text.trim(),
                            'hotelDescription': hotelDescCtrl.text.trim(),
                            'hotelCategory': category,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Restaurant created successfully'), backgroundColor: Colors.green),
                            );
                          }
                        } catch (e) {
                          setSheetState(() => isLoading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Restaurant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      validator: required ? (v) => v?.trim().isEmpty == true ? '$label is required' : null : null,
    );
  }
}
