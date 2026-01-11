import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../delivery/delivery_dashboard_page.dart';
import 'delivery_login_page.dart';

class DeliveryRegisterPage extends StatefulWidget {
  const DeliveryRegisterPage({super.key});

  @override
  State<DeliveryRegisterPage> createState() => _DeliveryRegisterPageState();
}

class _DeliveryRegisterPageState extends State<DeliveryRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureAdminCode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    // Format phone number
    final phone = Validators.formatPhoneNumber(_phoneController.text.trim());

    final success = await authProvider.registerDelivery(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: phone,
      password: _passwordController.text,
      adminCode: _adminCodeController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DeliveryDashboardPage()),
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppTheme.errorColor,
        ),
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
                  const Text('Become a Delivery Partner',
                      style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 24),

                  // Register Card
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
                              Icon(Icons.person_add,
                                  color: Color(0xFF10B981), size: 20),
                              SizedBox(width: 8),
                              Text('Register as Delivery',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Join our delivery team',
                              style: TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 20),

                          // Name
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                                'Full Name', Icons.person_outline),
                            validator: (v) =>
                                v!.isEmpty ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 14),
                            decoration:
                                _inputDecoration('Email', Icons.email_outlined),
                            validator: (v) =>
                                !v!.contains('@') ? 'Invalid email' : null,
                          ),
                          const SizedBox(height: 12),

                          // Phone
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d\+\-\s]')),
                              LengthLimitingTextInputFormatter(15),
                            ],
                            decoration: _inputDecoration(
                                    'Phone Number', Icons.phone_outlined)
                                .copyWith(
                              hintText: '+251912345678',
                              helperText: 'Ethiopian format: +251 or 09...',
                              helperStyle: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 10),
                            ),
                            validator: Validators.validateRequiredPhone,
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                                    'Password', Icons.lock_outlined)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) =>
                                v!.length < 6 ? 'Min 6 characters' : null,
                          ),
                          const SizedBox(height: 12),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(fontSize: 14),
                            decoration: _inputDecoration(
                                    'Confirm Password', Icons.lock_outlined)
                                .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20),
                                onPressed: () => setState(() =>
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                            ),
                            validator: (v) => v != _passwordController.text
                                ? 'Passwords don\'t match'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Admin Code
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.key,
                                        color: Color(0xFF10B981), size: 16),
                                    SizedBox(width: 6),
                                    Text('Registration Code',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF10B981),
                                            fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                    'Contact admin to get your delivery partner code',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _adminCodeController,
                                  obscureText: _obscureAdminCode,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Enter code',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    filled: true,
                                    fillColor: Colors.white,
                                    prefixIcon: const Icon(
                                        Icons.vpn_key_outlined,
                                        color: Color(0xFF10B981),
                                        size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                          _obscureAdminCode
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20),
                                      onPressed: () => setState(() =>
                                          _obscureAdminCode =
                                              !_obscureAdminCode),
                                    ),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none),
                                  ),
                                  validator: (v) =>
                                      v!.isEmpty ? 'Code is required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register Button
                          Consumer<AuthProvider>(
                            builder: (context, auth, _) => ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
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
                                  : const Text('Register',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const DeliveryLoginPage()),
                                ),
                                child: const Text('Sign In',
                                    style: TextStyle(
                                        color: Color(0xFF10B981),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
      ),
    );
  }
}
