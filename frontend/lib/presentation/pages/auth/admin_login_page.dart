import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'admin_register_page.dart';
import '../admin/admin_dashboard_page.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      final user = authProvider.user;
      if (user?.role == 'admin' || user?.role == 'restaurant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        // Not a restaurant/admin account
        await authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This account is not a restaurant account. Please use the user login.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B35FF), Color(0xFF8B5CF6), Colors.white],
            stops: [0.0, 0.25, 0.5],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Admin Badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('ADMIN PORTAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Logo
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: Icon(Icons.restaurant_menu,
                        size: isSmallScreen ? 32 : 40,
                        color: const Color(0xFF6B35FF)),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text('FoodieGo',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text('Hotel Management',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Login Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF6B35FF).withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ]),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock,
                                  color: Color(0xFF6B35FF), size: 20),
                              SizedBox(width: 8),
                              Text('Admin Login',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Sign in to manage your restaurant',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Admin Email',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Color(0xFF6B35FF), size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF6B35FF), width: 2),
                              ),
                            ),
                            validator: (v) =>
                                !v!.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              prefixIcon: const Icon(Icons.lock_outlined,
                                  color: Color(0xFF6B35FF), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF6B35FF), width: 2),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) => ElevatedButton(
                              onPressed: auth.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B35FF),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In as Admin',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an admin account? ",
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminRegisterPage()),
                                ),
                                child: const Text('Register',
                                    style: TextStyle(
                                        color: Color(0xFF6B35FF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Link to user login
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/'),
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('Go to Customer Login'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
