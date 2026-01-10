import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/admin/admin_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_utils.dart';
import '../../widgets/loading_widget.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  @override
  void initState() {
    super.initState();
    // Ensure admin session type is set
    StorageUtils.setSessionType(SessionType.admin);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchUsers();
    });
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
              child: Consumer<AdminProvider>(
                builder: (context, admin, _) {
                  if (admin.isLoading) {
                    return const LoadingWidget(message: 'Loading users...');
                  }
                  if (admin.users.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }
                  return RefreshIndicator(
                    onRefresh: () => admin.fetchUsers(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: admin.users.length,
                      itemBuilder: (context, index) =>
                          _buildUserCard(admin.users[index], admin),
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Users',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('View and manage user accounts',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, AdminProvider admin) {
    final role = user['role'] ?? 'user';
    final isRestaurant = role == 'restaurant';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: isRestaurant
                ? const Color(0xFF6B35FF).withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Icon(
              isRestaurant ? Icons.restaurant : Icons.person,
              color: isRestaurant
                  ? const Color(0xFF6B35FF)
                  : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'] ?? 'Unknown',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user['email'] ?? '',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getRoleColor(role)),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
            onSelected: (value) => _handleUserAction(value, user, admin),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete User',
                    style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'restaurant':
        return const Color(0xFF6B35FF);
      case 'delivery':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _handleUserAction(
      String action, Map<String, dynamic> user, AdminProvider admin) async {
    final userId = user['_id'] ?? user['id'];

    if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete ${user['name']}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.errorColor)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await admin.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User deleted'),
                backgroundColor: AppTheme.successColor),
          );
        }
      }
    }
  }
}
