import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
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

      final response = await ApiService.get('${ApiConstants.baseUrl}/super-admin/restaurants$query');
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
        '${ApiConstants.baseUrl}/super-admin/restaurants/${restaurant['_id']}',
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
      await ApiService.delete('${ApiConstants.baseUrl}/super-admin/restaurants/${restaurant['_id']}');
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
}
