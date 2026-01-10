import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/storage_utils.dart';
import 'forgot_password_page.dart';
import '../delivery/delivery_dashboard_page.dart';

class DeliveryLoginPage extends StatefulWidget {
  const DeliveryLoginPage({super.key});

  @override
  State<DeliveryLoginPage> createState() => _DeliveryLoginPageState();
}

class _DeliveryLoginPageState extends State<DeliveryLoginPage> {
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

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    authProvider.switchSessionType(SessionType.delivery);

    final success = await authProvider.login(email: email, password: password);

    if (success && mounted) {
      final user = authProvider.user;
      if (user?.role == 'delivery') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryDashboardPage()),
        );
      } else {
        await authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This account is not a delivery account.'),
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10B981), Color(0xFF34D399), Colors.white],
            stops: [0.0, 0.25, 0.5],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Delivery Badge
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
                        Icon(Icons.delivery_dining,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('DELIVERY PORTAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logo
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: const Icon(Icons.delivery_dining,
                        size: 40, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 12),
                  const Text('FoodieGo',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text('Delivery Partner',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 24),

                  // Login Card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.1),
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
                                  color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 8),
                              Text('Delivery Login',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Sign in to start delivering',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Color(0xFF10B981), size: 20),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF10B981), width: 2),
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
                                  color: Color(0xFF10B981), size: 20),
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
                                    color: Color(0xFF10B981), width: 2),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) => ElevatedButton(
                              onPressed: auth.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('Sign In',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ForgotPasswordPage()),
                              ),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(
                                      color: Color(0xFF10B981), fontSize: 12)),
                            ),
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
