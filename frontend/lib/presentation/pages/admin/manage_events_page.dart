import 'package:flutter/material.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../data/models/event_booking.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class ManageEventsPage extends StatefulWidget {
  const ManageEventsPage({super.key});

  @override
  State<ManageEventsPage> createState() => _ManageEventsPageState();
}

class _ManageEventsPageState extends State<ManageEventsPage>
    with SingleTickerProviderStateMixin {
  final EventRepository _eventRepo = EventRepository();
  late TabController _tabController;
  List<EventBooking> _bookings = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _eventCategories = [
    {'type': 'all', 'label': 'All', 'icon': '📋', 'color': Colors.blue},
    {'type': 'wedding', 'label': 'Wedding', 'icon': '💒', 'color': Colors.pink},
    {
      'type': 'birthday',
      'label': 'Birthday',
      'icon': '🎂',
      'color': Colors.orange
    },
    {
      'type': 'ceremony',
      'label': 'Ceremony',
      'icon': '🎊',
      'color': Colors.purple
    },
    {
      'type': 'corporate',
      'label': 'Corporate',
      'icon': '💼',
      'color': Colors.indigo
    },
    {
      'type': 'graduation',
      'label': 'Graduation',
      'icon': '🎓',
      'color': Colors.green
    },
    {
      'type': 'anniversary',
      'label': 'Anniversary',
      'icon': '💝',
      'color': Colors.red
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _eventRepo.getHotelBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  List<EventBooking> _getFilteredBookings(String status) {
    var filtered = _bookings.where((b) {
      if (status == 'pending') return b.status == 'pending';
      if (status == 'confirmed')
        return b.status == 'confirmed' || b.status == 'in_progress';
      if (status == 'completed')
        return b.status == 'completed' || b.status == 'cancelled';
      return true;
    }).toList();

    if (_selectedFilter != 'all') {
      filtered = filtered.where((b) => b.eventType == _selectedFilter).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Event Bookings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList('pending'),
                      _buildBookingsList('confirmed'),
                      _buildBookingsList('completed'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _eventCategories.length,
        itemBuilder: (context, index) {
          final cat = _eventCategories[index];
          final isSelected = _selectedFilter == cat['type'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = cat['type']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (cat['color'] as Color).withOpacity(0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? cat['color'] as Color : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Text(cat['icon'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    cat['label'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? cat['color'] as Color
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(String status) {
    final bookings = _getFilteredBookings(status);
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No $status bookings',
                style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildBookingCard(EventBooking booking) {
    final category = _eventCategories.firstWhere(
      (c) => c['type'] == booking.eventType,
      orElse: () => _eventCategories[0],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (category['color'] as Color).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(category['icon'], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.eventName.isNotEmpty
                            ? booking.eventName
                            : '${category['label']} Event',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${booking.guestCount} guests • ${_formatDate(booking.eventDate)}',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
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
                _buildDetailRow(Icons.person, 'Customer',
                    booking.user?['name'] ?? 'Unknown'),
                _buildDetailRow(Icons.phone, 'Phone', booking.contactPhone),
                _buildDetailRow(Icons.location_on, 'Venue', booking.venue),
                if (booking.customLocation != null)
                  _buildDetailRow(Icons.map, 'Location',
                      booking.customLocation!.address ?? 'N/A'),
                _buildDetailRow(Icons.attach_money, 'Budget',
                    '${AppConstants.currency}${booking.budget?.max ?? 0}'),
                if (booking.services.isNotEmpty)
                  _buildDetailRow(Icons.room_service, 'Services',
                      booking.services.join(', ')),
                if (booking.specialRequests != null &&
                    booking.specialRequests!.isNotEmpty)
                  _buildDetailRow(
                      Icons.note, 'Notes', booking.specialRequests!),
              ],
            ),
          ),
          // Actions
          if (booking.status == 'pending')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToBooking(booking, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: const BorderSide(color: AppTheme.errorColor),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showResponseDialog(booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                      ),
                      child: const Text('Accept'),
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
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Text('$label: ',
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppTheme.successColor;
        label = 'Confirmed';
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = 'Cancelled';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completed';
        break;
      default:
        color = AppTheme.warningColor;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'TBD';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showResponseDialog(EventBooking booking) {
    final quotationController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quotationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quotation Price',
                prefixText: '${AppConstants.currency} ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message to Customer',
                hintText: 'Add any details about the event...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToBooking(
                booking,
                'confirmed',
                quotation: double.tryParse(quotationController.text),
                message: messageController.text,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToBooking(
    EventBooking booking,
    String status, {
    double? quotation,
    String? message,
  }) async {
    try {
      await _eventRepo.respondToBooking(booking.id, {
        'status': status,
        'quotation': quotation,
        'message': message,
      });
      _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'confirmed'
                ? 'Booking confirmed!'
                : 'Booking declined'),
            backgroundColor: status == 'confirmed'
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}
