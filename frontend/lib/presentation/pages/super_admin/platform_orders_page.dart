import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class PlatformOrdersPage extends StatefulWidget {
  const PlatformOrdersPage({super.key});

  @override
  State<PlatformOrdersPage> createState() => _PlatformOrdersPageState();
}

class _PlatformOrdersPageState extends State<PlatformOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String? _error;
  String _statusFilter = '';
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final query = StringBuffer('?limit=30');
      if (_statusFilter.isNotEmpty) query.write('&status=$_statusFilter');

      final response = await ApiService.get('${ApiConstants.baseUrl}/super-admin/orders$query');
      if (mounted) {
        setState(() {
          _orders = response['data'] ?? [];
          _total = response['count'] ?? 0;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.green;
      case 'delivered':
      case 'completed': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Platform Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text('$_total orders', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const Spacer(),
                DropdownButton<String>(
                  value: _statusFilter.isEmpty ? 'all' : _statusFilter,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
                    DropdownMenuItem(value: 'ready', child: Text('Ready')),
                    DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v == 'all' ? '' : (v ?? ''));
                    _load();
                  },
                ),
              ],
            ),
          ),
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
                    : _orders.isEmpty
                        ? const Center(child: Text('No orders found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _orders.length,
                              itemBuilder: (_, i) => _buildOrderCard(_orders[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'pending';
    final color = _statusColor(status);
    final user = order['user'] as Map<String, dynamic>?;
    final items = (order['items'] as List?) ?? [];
    final total = ((order['totalPrice'] ?? 0.0) as num).toStringAsFixed(2);
    final hotelName = items.isNotEmpty ? (items.first['hotelName'] ?? 'Unknown') : 'Unknown';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order['orderNumber'] ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.restaurant, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(hotelName, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(width: 16),
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user?['name'] ?? 'Guest', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${items.length} items', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                const Spacer(),
                Text(
                  'ETB $total',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
