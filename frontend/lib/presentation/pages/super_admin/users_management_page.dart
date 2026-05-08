import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();
  String _roleFilter = '';
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
      final query = StringBuffer('?limit=50');
      if (_searchController.text.isNotEmpty) query.write('&search=${_searchController.text}');
      if (_roleFilter.isNotEmpty) query.write('&role=$_roleFilter');

      final response = await ApiService.get('/super-admin/users$query');
      if (mounted) {
        setState(() {
          _users = response['data'] ?? [];
          _total = response['count'] ?? 0;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final newStatus = !(user['isActive'] ?? true);
    try {
      await ApiService.put(
        '/super-admin/users/${user['_id']}',
        {'isActive': newStatus},
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user['name']}"? This cannot be undone.'),
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
      await ApiService.delete('/super-admin/users/${user['_id']}');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'restaurant': return Colors.orange;
      case 'delivery': return Colors.purple;
      case 'super_admin': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'restaurant': return Icons.restaurant;
      case 'delivery': return Icons.delivery_dining;
      case 'super_admin': return Icons.admin_panel_settings;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeliverySheet,
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Driver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Users', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
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
                    Text('$_total users', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _roleFilter.isEmpty ? 'all' : _roleFilter,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Roles')),
                        DropdownMenuItem(value: 'user', child: Text('Customers')),
                        DropdownMenuItem(value: 'restaurant', child: Text('Restaurants')),
                        DropdownMenuItem(value: 'delivery', child: Text('Drivers')),
                      ],
                      onChanged: (v) {
                        setState(() => _roleFilter = v == 'all' ? '' : (v ?? ''));
                        _load();
                      },
                    ),
                  ],
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
                    : _users.isEmpty
                        ? const Center(child: Text('No users found'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _users.length,
                              itemBuilder: (_, i) => _buildUserCard(_users[i]),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role'] ?? 'user';
    final isActive = user['isActive'] ?? true;
    final color = _roleColor(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(_roleIcon(role), color: color, size: 20),
        ),
        title: Text(user['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '', style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(role, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(fontSize: 10, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            if (action == 'toggle') _toggleActive(user);
            if (action == 'delete') _deleteUser(user);
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
            if (role != 'super_admin')
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
        isThreeLine: true,
      ),
    );
  }

  void _showAddDeliverySheet() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
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
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.delivery_dining, color: Color(0xFF4ECDC4), size: 24),
                      SizedBox(width: 10),
                      Text('Add Delivery Driver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _field(nameCtrl, 'Full Name', Icons.person, required: true),
                  const SizedBox(height: 12),
                  _field(emailCtrl, 'Email', Icons.email, keyboardType: TextInputType.emailAddress, required: true),
                  const SizedBox(height: 12),
                  _field(passwordCtrl, 'Password', Icons.lock, obscure: true, required: true),
                  const SizedBox(height: 12),
                  _field(phoneCtrl, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
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
                            'role': 'delivery',
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _load();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Delivery driver created successfully'), backgroundColor: Colors.green),
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
                        backgroundColor: const Color(0xFF4ECDC4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Driver Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool obscure = false,
    bool required = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
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
