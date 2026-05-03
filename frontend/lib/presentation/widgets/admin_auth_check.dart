import 'package:flutter/material.dart';
import '../../core/utils/storage_utils.dart';

/// Widget that checks if admin is authenticated before showing content
/// Automatically redirects to admin login if not authenticated
class AdminAuthCheck extends StatefulWidget {
  final Widget child;
  
  const AdminAuthCheck({super.key, required this.child});

  @override
  State<AdminAuthCheck> createState() => _AdminAuthCheckState();
}

class _AdminAuthCheckState extends State<AdminAuthCheck> {
  bool _isChecking = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    // Set admin session type
    StorageUtils.setSessionType(SessionType.admin);
    
    // Check if token exists
    final token = StorageUtils.getToken();
    
    if (token == null) {
      // No token - redirect to admin login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/admin-login');
        }
      });
      setState(() {
        _isChecking = false;
        _isAuthenticated = false;
      });
    } else {
      // Token exists - show content
      setState(() {
        _isChecking = false;
        _isAuthenticated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(
          child: Text('Redirecting to login...'),
        ),
      );
    }

    return widget.child;
  }
}
