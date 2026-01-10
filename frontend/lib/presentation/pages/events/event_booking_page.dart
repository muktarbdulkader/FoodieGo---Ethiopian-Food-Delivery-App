import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/food.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../state/auth/auth_provider.dart';

class EventBookingPage extends StatefulWidget {
  final Hotel? preselectedHotel;

  const EventBookingPage({super.key, this.preselectedHotel});

  @override
  State<EventBookingPage> createState() => _EventBookingPageState();
}

class _EventBookingPageState extends State<EventBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventRepository = EventRepository();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  List<Food> _recommendedFoods = [];
  List<dynamic> _venues = [];

  // Location data
  String _detectedAddress = '';

  // Form data
  String _eventType = 'wedding';
  final _eventNameController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _eventTime = const TimeOfDay(hour: 12, minute: 0);
  final _guestCountController = TextEditingController(text: '50');
  String _venue = 'restaurant';
  final _addressController = TextEditingController();
  final List<String> _selectedServices = [];
  String _foodPreference = 'mixed';
  final _specialRequestsController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  Hotel? _selectedHotel;

  final List<Map<String, dynamic>> _eventTypes = [
    {
      'value': 'wedding',
      'label': 'Wedding',
      'icon': '💒',
      'color': const Color(0xFFE91E63)
    },
    {
      'value': 'birthday',
      'label': 'Birthday',
      'icon': '🎂',
      'color': const Color(0xFF9C27B0)
    },
    {
      'value': 'ceremony',
      'label': 'Ceremony',
      'icon': '🎉',
      'color': const Color(0xFF673AB7)
    },
    {
      'value': 'corporate',
      'label': 'Corporate',
      'icon': '💼',
      'color': const Color(0xFF3F51B5)
    },
    {
      'value': 'graduation',
      'label': 'Graduation',
      'icon': '🎓',
      'color': const Color(0xFF2196F3)
    },
    {
      'value': 'anniversary',
      'label': 'Anniversary',
      'icon': '💕',
      'color': const Color(0xFFFF5722)
    },
    {
      'value': 'other',
      'label': 'Other',
      'icon': '🎊',
      'color': const Color(0xFF607D8B)
    },
  ];

  final List<Map<String, dynamic>> _services = [
    {'value': 'catering', 'label': 'Catering', 'icon': Icons.restaurant},
    {'value': 'decoration', 'label': 'Decoration', 'icon': Icons.celebration},
    {'value': 'cake', 'label': 'Cake', 'icon': Icons.cake},
    {'value': 'photography', 'label': 'Photography', 'icon': Icons.camera_alt},
    {'value': 'music', 'label': 'Music/DJ', 'icon': Icons.music_note},
    {
      'value': 'venue_rental',
      'label': 'Venue Rental',
      'icon': Icons.location_city
    },
    {'value': 'waiters', 'label': 'Waiters', 'icon': Icons.person},
    {'value': 'drinks', 'label': 'Drinks', 'icon': Icons.local_bar},
  ];

  @override
  void initState() {
    super.initState();
    _selectedHotel = widget.preselectedHotel;
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _phoneController.text = user.phone ?? '';
      _emailController.text = user.email;
    }
    _loadVenues();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final location = await LocationService.getFullLocation();
      if (location != null && mounted) {
        setState(() {
          _detectedAddress = location['address'] ?? '';
          _addressController.text = _detectedAddress;
        });
      }
    } catch (e) {
      // Location detection failed, user can enter manually
    }
    if (mounted) setState(() => _isLoadingLocation = false);
  }

  Future<void> _loadVenues() async {
    try {
      final venues = await _eventRepository.getNearbyVenues();
      if (mounted) setState(() => _venues = venues);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _guestCountController.dispose();
    _addressController.dispose();
    _specialRequestsController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    try {
      final foods = await _eventRepository.getEventRecommendations(
        _eventType,
        hotelId: _selectedHotel?.id,
      );
      setState(() => _recommendedFoods = foods);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHotel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a restaurant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _eventRepository.createBooking({
        'hotelId': _selectedHotel!.id,
        'eventType': _eventType,
        'eventName': _eventNameController.text,
        'eventDate': _eventDate.toIso8601String(),
        'eventTime':
            '${_eventTime.hour}:${_eventTime.minute.toString().padLeft(2, '0')}',
        'guestCount': int.parse(_guestCountController.text),
        'venue': _venue,
        'customLocation': _venue == 'custom_location'
            ? {
                'address': _addressController.text,
              }
            : null,
        'services': _selectedServices,
        'foodPreferences': _foodPreference,
        'specialRequests': _specialRequestsController.text,
        'budget': {
          'min': double.tryParse(_budgetMinController.text),
          'max': double.tryParse(_budgetMaxController.text),
        },
        'contactPhone': _phoneController.text,
        'contactEmail': _emailController.text,
      });

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.accentGreen, size: 60),
            ),
            const SizedBox(height: 20),
            const Text('Booking Submitted!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Your event booking request has been sent to ${_selectedHotel?.name}. They will respond soon with a quotation.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Book Event'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
              if (_currentStep == 3) _loadRecommendations();
            } else {
              _submitBooking();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(
                              _currentStep == 3 ? 'Submit Booking' : 'Continue',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Event Type'),
              subtitle: Text(_eventTypes
                  .firstWhere((e) => e['value'] == _eventType)['label']),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _buildEventTypeStep(),
            ),
            Step(
              title: const Text('Event Details'),
              subtitle: Text(_eventNameController.text.isEmpty
                  ? 'Fill details'
                  : _eventNameController.text),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: _buildEventDetailsStep(),
            ),
            Step(
              title: const Text('Services'),
              subtitle: Text('${_selectedServices.length} services selected'),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              content: _buildServicesStep(),
            ),
            Step(
              title: const Text('Contact & Submit'),
              subtitle: const Text('Review and submit'),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: _buildContactStep(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('What type of event are you planning?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _eventTypes.map((type) {
            final isSelected = _eventType == type['value'];
            return GestureDetector(
              onTap: () => setState(() => _eventType = type['value']),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (type['color'] as Color).withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? type['color'] : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type['icon'], style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(type['label'],
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? type['color'] : Colors.black87,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEventDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _eventNameController,
          decoration:
              _inputDecoration('Event Name', 'e.g., John & Mary Wedding'),
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _eventDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Text(
                          '${_eventDate.day}/${_eventDate.month}/${_eventDate.year}'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                      context: context, initialTime: _eventTime);
                  if (time != null) setState(() => _eventTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Text(_eventTime.format(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _guestCountController,
          decoration: _inputDecoration('Number of Guests', '50'),
          keyboardType: TextInputType.number,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        const Text('Venue', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildVenueChip('restaurant', 'At Restaurant', Icons.restaurant),
            _buildVenueChip('outdoor', 'Outdoor', Icons.park),
            _buildVenueChip('home_delivery', 'Home Delivery', Icons.home),
            _buildVenueChip(
                'custom_location', 'Custom Location', Icons.location_on),
          ],
        ),
        if (_venue == 'custom_location') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _addressController,
                  decoration:
                      _inputDecoration('Event Address', 'Enter full address'),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _isLoadingLocation ? null : _detectLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location,
                          color: AppTheme.primaryColor),
                  tooltip: 'Use current location',
                ),
              ),
            ],
          ),
          if (_detectedAddress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppTheme.successColor, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Location detected: $_detectedAddress',
                      style: const TextStyle(
                          color: AppTheme.successColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 24),
        const Text('Select Restaurant',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (_venues.isEmpty)
          const Center(child: CircularProgressIndicator())
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _venues.length,
              itemBuilder: (context, index) {
                final venue = _venues[index];
                final isSelected = _selectedHotel?.id == venue['_id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedHotel = Hotel(
                        id: venue['_id'],
                        name:
                            venue['hotelName'] ?? venue['name'] ?? 'Restaurant',
                        image: venue['hotelImage'] ?? '',
                        address: venue['address'] ?? '',
                      );
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(11)),
                          child: (venue['hotelImage'] != null &&
                                  venue['hotelImage'].toString().isNotEmpty)
                              ? Image.network(
                                  venue['hotelImage'],
                                  height: 70,
                                  width: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 70,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.restaurant,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  height: 70,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.restaurant,
                                      color: Colors.grey),
                                ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  venue['hotelName'] ??
                                      venue['name'] ??
                                      'Restaurant',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppTheme.primaryColor, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVenueChip(String value, String label, IconData icon) {
    final isSelected = _venue == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _venue = value),
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
    );
  }

  Widget _buildServicesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select services you need:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _services.map((service) {
            final isSelected = _selectedServices.contains(service['value']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServices.remove(service['value']);
                  } else {
                    _selectedServices.add(service['value']);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(service['icon'],
                        size: 18,
                        color:
                            isSelected ? AppTheme.primaryColor : Colors.grey),
                    const SizedBox(width: 6),
                    Text(service['label'],
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Food Preference',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _foodPreference,
          decoration: _inputDecoration('', ''),
          items: const [
            DropdownMenuItem(value: 'ethiopian', child: Text('🇪🇹 Ethiopian')),
            DropdownMenuItem(
                value: 'international', child: Text('🌍 International')),
            DropdownMenuItem(value: 'mixed', child: Text('🍽️ Mixed')),
            DropdownMenuItem(value: 'vegetarian', child: Text('🥗 Vegetarian')),
            DropdownMenuItem(value: 'custom', child: Text('✨ Custom Menu')),
          ],
          onChanged: (v) => setState(() => _foodPreference = v!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _specialRequestsController,
          decoration: _inputDecoration(
              'Special Requests', 'Any special requirements...'),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        const Text('Budget Range (ETB)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _budgetMinController,
                decoration: _inputDecoration('Min', '5000'),
                keyboardType: TextInputType.number,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('-'),
            ),
            Expanded(
              child: TextFormField(
                controller: _budgetMaxController,
                decoration: _inputDecoration('Max', '50000'),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _phoneController,
          decoration: _inputDecoration('Contact Phone', '+251...'),
          keyboardType: TextInputType.phone,
          validator: (v) => v?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: _inputDecoration('Email (Optional)', 'email@example.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        if (_recommendedFoods.isNotEmpty) ...[
          const Text('Recommended Foods for Your Event',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedFoods.length,
              itemBuilder: (context, index) {
                final food = _recommendedFoods[index];
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: food.image.isNotEmpty
                            ? Image.network(food.image,
                                height: 60,
                                width: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.grey)))
                            : Container(
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.fastfood,
                                    color: Colors.grey)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(food.name,
                            style: const TextStyle(fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppTheme.primaryColor, size: 20),
                  SizedBox(width: 8),
                  Text('Booking Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 12),
              _summaryRow(
                  'Event',
                  _eventTypes
                      .firstWhere((e) => e['value'] == _eventType)['label']),
              _summaryRow('Date',
                  '${_eventDate.day}/${_eventDate.month}/${_eventDate.year} at ${_eventTime.format(context)}'),
              _summaryRow('Guests', _guestCountController.text),
              _summaryRow(
                  'Services',
                  _selectedServices.isEmpty
                      ? 'None'
                      : _selectedServices.length.toString()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
