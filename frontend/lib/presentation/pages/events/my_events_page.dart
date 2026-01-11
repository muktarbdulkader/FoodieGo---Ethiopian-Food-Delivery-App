import 'package:flutter/material.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/models/event_booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import 'event_booking_page.dart';

class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> {
  final EventRepository _eventRepo = EventRepository();
  List<EventBooking> _bookings = [];
  bool _isLoading = true;

  final Map<String, Map<String, dynamic>> _eventTypes = {
    'wedding': {
      'label': 'Wedding',
      'icon': '💒',
      'color': const Color(0xFFE91E63)
    },
    'birthday': {
      'label': 'Birthday',
      'icon': '🎂',
      'color': const Color(0xFF9C27B0)
    },
    'ceremony': {
      'label': 'Ceremony',
      'icon': '🎉',
      'color': const Color(0xFF673AB7)
    },
    'corporate': {
      'label': 'Corporate',
      'icon': '💼',
      'color': const Color(0xFF3F51B5)
    },
    'graduation': {
      'label': 'Graduation',
      'icon': '🎓',
      'color': const Color(0xFF2196F3)
    },
    'anniversary': {
      'label': 'Anniversary',
      'icon': '💕',
      'color': const Color(0xFFFF5722)
    },
    'other': {'label': 'Other', 'icon': '🎊', 'color': const Color(0xFF607D8B)},
  };

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _eventRepo.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('My Event Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) =>
                        _buildBookingCard(_bookings[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EventBookingPage()),
          );
          _loadBookings();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Book Event', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No Event Bookings Yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first event for weddings,\nbirthdays, ceremonies and more!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EventBookingPage()),
              );
              _loadBookings();
            },
            icon: const Icon(Icons.add),
            label: const Text('Book an Event'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(EventBooking booking) {
    final eventInfo = _eventTypes[booking.eventType] ?? _eventTypes['other']!;
    final color = eventInfo['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(eventInfo['icon'] as String,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.eventName.isNotEmpty
                            ? booking.eventName
                            : '${eventInfo['label']} Event',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        booking.hotelName ?? 'Restaurant',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.calendar_today, 'Date',
                    _formatDate(booking.eventDate)),
                _buildDetailRow(Icons.access_time, 'Time', booking.eventTime),
                _buildDetailRow(
                    Icons.people, 'Guests', '${booking.guestCount} people'),
                _buildDetailRow(Icons.location_on, 'Venue',
                    _getVenueDisplay(booking.venue)),
                // Show custom location address if available
                if (booking.customLocation != null &&
                    booking.customLocation!.address != null)
                  _buildDetailRow(
                      Icons.map, 'Location', booking.customLocation!.address!),
                if (booking.budget != null)
                  _buildDetailRow(
                    Icons.attach_money,
                    'Budget',
                    '${AppConstants.currency}${booking.budget!.min?.toStringAsFixed(0) ?? 0} - ${AppConstants.currency}${booking.budget!.max?.toStringAsFixed(0) ?? 0}',
                  ),
              ],
            ),
          ),
          // Admin Response (if any)
          if (booking.adminResponse != null &&
              booking.adminResponse!.message != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.message, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Restaurant Response',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.adminResponse!.message!,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  if (booking.adminResponse!.quotation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Quoted Price: ${AppConstants.currency}${booking.adminResponse!.quotation!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // Status-specific actions
          if (booking.status == 'confirmed' ||
              booking.status == 'completed' ||
              booking.status == 'cancelled')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                children: [
                  // Show confirmation status for confirmed/completed events
                  if (booking.status != 'cancelled') ...[
                    Row(
                      children: [
                        Icon(
                          booking.userConfirmedComplete
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: booking.userConfirmedComplete
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'You: ${booking.userConfirmedComplete ? "Confirmed" : "Pending"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: booking.userConfirmedComplete
                                ? AppTheme.successColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          booking.hotelConfirmedComplete
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 16,
                          color: booking.hotelConfirmedComplete
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Hotel: ${booking.hotelConfirmedComplete ? "Confirmed" : "Pending"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: booking.hotelConfirmedComplete
                                ? AppTheme.successColor
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      // Details button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showEventDetails(booking),
                          icon: const Icon(Icons.info_outline, size: 16),
                          label: const Text('Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (booking.status == 'confirmed') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showContactDialog(booking),
                            icon: const Icon(Icons.phone, size: 16),
                            label: const Text('Contact'),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Confirm complete button (only if not already confirmed by user)
                      if (!booking.userConfirmedComplete &&
                          booking.status != 'cancelled')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmComplete(booking),
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Confirm Done'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      // Delete button (only if both confirmed or cancelled)
                      if (booking.canDelete) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDeleteBooking(booking),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side:
                                  const BorderSide(color: AppTheme.errorColor),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'confirmed':
        color = AppTheme.successColor;
        label = 'Confirmed';
        icon = Icons.check_circle;
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      case 'in_progress':
        color = Colors.orange;
        label = 'In Progress';
        icon = Icons.hourglass_empty;
        break;
      default:
        color = AppTheme.warningColor;
        label = 'Pending';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getVenueDisplay(String venue) {
    switch (venue) {
      case 'restaurant':
        return 'At Restaurant';
      case 'outdoor':
        return 'Outdoor Venue';
      case 'custom':
        return 'Custom Location';
      case 'banquet':
        return 'Banquet Hall';
      case 'rooftop':
        return 'Rooftop';
      case 'garden':
        return 'Garden';
      default:
        return venue;
    }
  }

  void _showContactDialog(EventBooking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.phone, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Contact Restaurant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              booking.hotelName ?? 'Restaurant',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (booking.hotelAddress != null &&
                booking.hotelAddress!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.hotelAddress!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Restaurant Contact:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  booking.hotelPhone != null && booking.hotelPhone!.isNotEmpty
                      ? booking.hotelPhone!
                      : 'No phone available',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            if (booking.hotelEmail != null &&
                booking.hotelEmail!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking.hotelEmail!,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(EventBooking booking) {
    final eventInfo = _eventTypes[booking.eventType] ?? _eventTypes['other']!;
    final color = eventInfo['color'] as Color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Text(eventInfo['icon'] as String,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.eventName.isNotEmpty
                              ? booking.eventName
                              : '${eventInfo['label']} Event',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.hotelName ?? 'Restaurant',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),
            ),
            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection('Event Information', [
                      _buildDetailItem(Icons.event, 'Event Type',
                          eventInfo['label'] as String),
                      _buildDetailItem(Icons.calendar_today, 'Date',
                          _formatDate(booking.eventDate)),
                      _buildDetailItem(
                          Icons.access_time, 'Time', booking.eventTime),
                      _buildDetailItem(Icons.people, 'Guests',
                          '${booking.guestCount} people'),
                    ]),
                    const SizedBox(height: 20),
                    _buildDetailSection('Venue', [
                      _buildDetailItem(Icons.location_on, 'Venue Type',
                          _getVenueDisplay(booking.venue)),
                      if (booking.customLocation != null &&
                          booking.customLocation!.address != null)
                        _buildDetailItem(Icons.map, 'Address',
                            booking.customLocation!.address!),
                      if (booking.customLocation != null &&
                          booking.customLocation!.city != null)
                        _buildDetailItem(Icons.location_city, 'City',
                            booking.customLocation!.city!),
                    ]),
                    if (booking.services.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Services', [
                        _buildDetailItem(Icons.room_service, 'Requested',
                            booking.services.join(', ')),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    _buildDetailSection('Preferences', [
                      _buildDetailItem(Icons.restaurant_menu, 'Food',
                          _getFoodPreferenceDisplay(booking.foodPreferences)),
                      if (booking.budget != null)
                        _buildDetailItem(
                          Icons.attach_money,
                          'Budget',
                          '${AppConstants.currency}${booking.budget!.min?.toStringAsFixed(0) ?? 0} - ${AppConstants.currency}${booking.budget!.max?.toStringAsFixed(0) ?? 0}',
                        ),
                    ]),
                    if (booking.specialRequests != null &&
                        booking.specialRequests!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Special Requests', [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            booking.specialRequests!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ]),
                    ],
                    if (booking.adminResponse != null &&
                        booking.adminResponse!.message != null) ...[
                      const SizedBox(height: 20),
                      _buildDetailSection('Restaurant Response', [
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            booking.adminResponse!.message!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                        if (booking.adminResponse!.quotation != null)
                          _buildDetailItem(
                            Icons.receipt,
                            'Quoted Price',
                            '${AppConstants.currency}${booking.adminResponse!.quotation!.toStringAsFixed(0)}',
                          ),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    _buildDetailSection('Contact', [
                      _buildDetailItem(
                          Icons.phone, 'Phone', booking.contactPhone),
                      if (booking.contactEmail != null &&
                          booking.contactEmail!.isNotEmpty)
                        _buildDetailItem(
                            Icons.email, 'Email', booking.contactEmail!),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 10),
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getFoodPreferenceDisplay(String pref) {
    switch (pref) {
      case 'veg':
        return 'Vegetarian';
      case 'non_veg':
        return 'Non-Vegetarian';
      case 'mixed':
        return 'Mixed';
      case 'vegan':
        return 'Vegan';
      default:
        return pref;
    }
  }

  Future<void> _confirmComplete(EventBooking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: Text(
          'Confirm that "${booking.eventName}" event has been completed?\n\n'
          'Note: Both you and the restaurant must confirm before the booking can be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventRepo.confirmComplete(booking.id);
        _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event marked as complete!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteBooking(EventBooking booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.errorColor),
            SizedBox(width: 8),
            Text('Delete Booking'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${booking.eventName}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _eventRepo.deleteBooking(booking.id);
        _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking deleted'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppTheme.errorColor),
          );
        }
      }
    }
  }
}
