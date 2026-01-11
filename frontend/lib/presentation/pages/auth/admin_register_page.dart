import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../admin/admin_dashboard_page.dart';
import '../delivery/delivery_dashboard_page.dart';

class AdminRegisterPage extends StatefulWidget {
  const AdminRegisterPage({super.key});

  @override
  State<AdminRegisterPage> createState() => _AdminRegisterPageState();
}

class _AdminRegisterPageState extends State<AdminRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _hotelNameController = TextEditingController();
  final _hotelAddressController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'restaurant'; // 'restaurant' or 'delivery'
  File? _selectedImage;
  String? _base64Image;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _adminCodeController.dispose();
    _hotelNameController.dispose();
    _hotelAddressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        setState(() {
          _selectedImage = File(pickedFile.path);
          _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Format phone number before sending
    final phone = _phoneController.text.trim().isNotEmpty
        ? Validators.formatPhoneNumber(_phoneController.text.trim())
        : _phoneController.text.trim();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: phone,
      role: _selectedRole,
      adminCode: _adminCodeController.text.trim(),
      hotelName: _selectedRole == 'restaurant'
          ? _hotelNameController.text.trim()
          : null,
      hotelAddress: _selectedRole == 'restaurant'
          ? _hotelAddressController.text.trim()
          : null,
      hotelImage: _selectedRole == 'restaurant' ? _base64Image : null,
    );

    if (success && mounted) {
      if (_selectedRole == 'delivery') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DeliveryDashboardPage()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
          (route) => false,
        );
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
            colors: [Color(0xFF6B35FF), Color(0xFF8A5CFF)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B35FF)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                  _selectedRole == 'delivery'
                                      ? Icons.delivery_dining
                                      : Icons.restaurant,
                                  color: const Color(0xFF6B35FF),
                                  size: 28),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _selectedRole == 'delivery'
                                        ? 'Delivery Registration'
                                        : 'Restaurant Registration',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    _selectedRole == 'delivery'
                                        ? 'Delivery Person Access'
                                        : 'Hotel Management Access',
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Role selector
                        const Text('Select Role',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _selectedRole = 'restaurant'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'restaurant'
                                        ? const Color(0xFF6B35FF)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.restaurant,
                                          color: _selectedRole == 'restaurant'
                                              ? Colors.white
                                              : Colors.grey,
                                          size: 28),
                                      const SizedBox(height: 8),
                                      Text('Restaurant',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedRole == 'restaurant'
                                                ? Colors.white
                                                : Colors.grey,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedRole = 'delivery'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _selectedRole == 'delivery'
                                        ? const Color(0xFF8B5CF6)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.delivery_dining,
                                          color: _selectedRole == 'delivery'
                                              ? Colors.white
                                              : Colors.grey,
                                          size: 28),
                                      const SizedBox(height: 8),
                                      Text('Delivery',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _selectedRole == 'delivery'
                                                ? Colors.white
                                                : Colors.grey,
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text('Personal Information',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        _buildTextField(
                            _nameController, 'Full Name', Icons.person_outline,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        _buildTextField(
                            _emailController, 'Email', Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                                !v!.contains('@') ? 'Invalid email' : null),
                        const SizedBox(height: 12),
                        _buildPhoneField(),
                        const SizedBox(height: 12),
                        _buildPasswordField(),
                        if (_selectedRole == 'restaurant') ...[
                          const SizedBox(height: 20),
                          const Text('Hotel/Restaurant Information',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary)),
                          const SizedBox(height: 12),
                          // Hotel Image Picker
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.file(_selectedImage!,
                                              fit: BoxFit.cover),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => setState(() {
                                                _selectedImage = null;
                                                _base64Image = null;
                                              }),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 18),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 40,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text('Tap to add hotel image',
                                            style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13)),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                              _hotelNameController,
                              'Hotel/Restaurant Name',
                              Icons.restaurant_outlined,
                              validator: (v) => v!.isEmpty ? 'Required' : null),
                          const SizedBox(height: 12),
                          _buildTextField(_hotelAddressController,
                              'Hotel Address', Icons.location_on_outlined,
                              maxLines: 2),
                        ],
                        const SizedBox(height: 20),
                        const Text('Verification Code',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 12),
                        _buildTextField(_adminCodeController, 'Secret Code',
                            Icons.vpn_key_outlined,
                            validator: (v) => v!.isEmpty ? 'Required' : null),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.amber, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      'Contact system administrator for registration code',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.amber))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildRegisterButton(),
                        const SizedBox(height: 16),
                        _buildLoginLink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Register',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text('Hotel Management', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6B35FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B35FF)),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => v!.length < 6 ? 'Min 6 characters' : null,
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) => ElevatedButton(
        onPressed: auth.isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF6B35FF),
        ),
        child: auth.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Text(
                _selectedRole == 'delivery'
                    ? 'Register as Delivery'
                    : 'Register as Restaurant',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Already have an account? '),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text('Sign In',
              style: TextStyle(
                  color: Color(0xFF6B35FF), fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\s]')),
        LengthLimitingTextInputFormatter(15),
      ],
      decoration: InputDecoration(
        labelText: 'Phone Number',
        hintText: '+251912345678 or 0912345678',
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF6B35FF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperText: 'Ethiopian format: +251 or 09...',
        helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
      validator: Validators.validateRequiredPhone,
    );
  }
}
