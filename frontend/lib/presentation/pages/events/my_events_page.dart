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
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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
                _buildDetailRow(Icons.location_on, 'Venue', booking.venue),
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
                color: Colors.blue.withOpacity(0.05),
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
          if (booking.status == 'confirmed')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Contact restaurant
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Contact'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // View details
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
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
        color: color.withOpacity(0.1),
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
}
