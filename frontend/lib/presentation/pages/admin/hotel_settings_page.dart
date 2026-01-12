import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../../state/auth/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../location/location_picker_page.dart';

class HotelSettingsPage extends StatefulWidget {
  const HotelSettingsPage({super.key});

  @override
  State<HotelSettingsPage> createState() => _HotelSettingsPageState();
}

class _HotelSettingsPageState extends State<HotelSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _hotelNameController = TextEditingController();
  final _hotelAddressController = TextEditingController();
  final _hotelPhoneController = TextEditingController();
  final _hotelDescriptionController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _minOrderController = TextEditingController();

  String _selectedCategory = 'restaurant';
  bool _isOpen = true;
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentImageUrl;
  String? _base64Image;

  // Location fields
  double? _latitude;
  double? _longitude;
  String? _locationAddress;
  String? _locationCity;

  final List<String> _categories = [
    'restaurant',
    'cafe',
    'fast_food',
    'fine_dining',
    'bakery',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _hotelNameController.text = user.hotelName ?? '';
      _hotelAddressController.text = user.hotelAddress ?? '';
      _hotelPhoneController.text = user.hotelPhone ?? '';
      _hotelDescriptionController.text = user.hotelDescription ?? '';
      _deliveryFeeController.text = (user.deliveryFee ?? 50).toString();
      _minOrderController.text = (user.minOrderAmount ?? 0).toString();
      _selectedCategory = user.hotelCategory ?? 'restaurant';
      _isOpen = user.isOpen ?? true;
      _currentImageUrl = user.hotelImage;
      // Load location
      _latitude = user.location?.latitude;
      _longitude = user.location?.longitude;
      _locationAddress = user.location?.address;
      _locationCity = user.location?.city;
    }
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _hotelAddressController.dispose();
    _hotelPhoneController.dispose();
    _hotelDescriptionController.dispose();
    _deliveryFeeController.dispose();
    _minOrderController.dispose();
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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authRepo = AuthRepository();
      final updatedUser = await authRepo.updateHotelSettings(
        hotelName: _hotelNameController.text.trim(),
        hotelAddress: _hotelAddressController.text.trim(),
        hotelPhone: _hotelPhoneController.text.trim(),
        hotelDescription: _hotelDescriptionController.text.trim(),
        hotelImage: _base64Image,
        hotelCategory: _selectedCategory,
        isOpen: _isOpen,
        deliveryFee: double.tryParse(_deliveryFeeController.text) ?? 50,
        minOrderAmount: double.tryParse(_minOrderController.text) ?? 0,
        latitude: _latitude,
        longitude: _longitude,
        locationAddress: _locationAddress,
        locationCity: _locationCity,
      );

      // Update auth provider
      if (mounted) {
        context.read<AuthProvider>().updateUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Hotel Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hotel Image
              _buildImageSection(),
              const SizedBox(height: 24),

              // Basic Info
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hotelNameController,
                label: 'Hotel/Restaurant Name',
                icon: Icons.store,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hotelAddressController,
                label: 'Address',
                icon: Icons.location_on,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hotelPhoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _hotelDescriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Category & Status'),
              const SizedBox(height: 12),

              // Category Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(_formatCategory(cat)),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Open/Closed Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isOpen ? Icons.check_circle : Icons.cancel,
                          color:
                              _isOpen ? const Color(0xFF10B981) : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isOpen ? 'Open for Orders' : 'Closed',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isOpen,
                      onChanged: (v) => setState(() => _isOpen = v),
                      activeColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Delivery Settings'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _deliveryFeeController,
                      label: 'Delivery Fee (ETB)',
                      icon: Icons.delivery_dining,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _minOrderController,
                      label: 'Min Order (ETB)',
                      icon: Icons.shopping_bag,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Restaurant Location'),
              const SizedBox(height: 8),
              Text(
                'Set your location so customers can find nearby restaurants',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildLocationPicker(),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hotel Banner Image'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_selectedImage!, fit: BoxFit.cover),
                        _buildImageOverlay(),
                      ],
                    ),
                  )
                : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _currentImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            ),
                            _buildImageOverlay(),
                          ],
                        ),
                      )
                    : _buildPlaceholder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Tap to add hotel banner image',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildImageOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Tap to change image',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: validator,
    );
  }

  String _formatCategory(String cat) {
    return cat.replaceAll('_', ' ').split(' ').map((word) {
      return word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '';
    }).join(' ');
  }

  Widget _buildLocationPicker() {
    final hasLocation = _latitude != null && _longitude != null;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (_) => LocationPickerPage(
              initialLat: _latitude,
              initialLng: _longitude,
            ),
          ),
        );
        if (result != null && mounted) {
          setState(() {
            _latitude = result['lat'];
            _longitude = result['lng'];
            _locationAddress = result['address'];
            _locationCity = result['name'];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasLocation ? const Color(0xFF10B981) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasLocation
                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                hasLocation ? Icons.check_circle : Icons.location_on,
                color: hasLocation
                    ? const Color(0xFF10B981)
                    : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation
                        ? (_locationCity ?? 'Location Set')
                        : 'Set Restaurant Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasLocation
                          ? const Color(0xFF10B981)
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasLocation
                        ? (_locationAddress ??
                            '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}')
                        : 'Tap to pick location on map',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
