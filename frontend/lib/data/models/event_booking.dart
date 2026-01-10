class EventBooking {
  final String id;
  final String hotelId;
  final String? hotelName;
  final String? hotelImage;
  final Map<String, dynamic>? user;
  final String eventType;
  final String eventName;
  final DateTime eventDate;
  final String eventTime;
  final int guestCount;
  final String venue;
  final EventLocation? customLocation;
  final List<String> services;
  final String foodPreferences;
  final String? specialRequests;
  final EventBudget? budget;
  final String contactPhone;
  final String? contactEmail;
  final String status;
  final AdminResponse? adminResponse;
  final double totalPrice;
  final DateTime createdAt;

  EventBooking({
    required this.id,
    required this.hotelId,
    this.hotelName,
    this.hotelImage,
    this.user,
    required this.eventType,
    required this.eventName,
    required this.eventDate,
    required this.eventTime,
    required this.guestCount,
    required this.venue,
    this.customLocation,
    required this.services,
    required this.foodPreferences,
    this.specialRequests,
    this.budget,
    required this.contactPhone,
    this.contactEmail,
    required this.status,
    this.adminResponse,
    required this.totalPrice,
    required this.createdAt,
  });

  factory EventBooking.fromJson(Map<String, dynamic> json) {
    final hotel = json['hotel'];
    final userData = json['user'];
    return EventBooking(
      id: json['_id'] ?? '',
      hotelId: hotel is Map ? hotel['_id'] ?? '' : hotel ?? '',
      hotelName: hotel is Map ? hotel['hotelName'] ?? hotel['name'] : null,
      hotelImage: hotel is Map ? hotel['hotelImage'] : null,
      user: userData is Map<String, dynamic> ? userData : null,
      eventType: json['eventType'] ?? '',
      eventName: json['eventName'] ?? '',
      eventDate:
          DateTime.parse(json['eventDate'] ?? DateTime.now().toIso8601String()),
      eventTime: json['eventTime'] ?? '',
      guestCount: json['guestCount'] ?? 0,
      venue: json['venue'] ?? 'restaurant',
      customLocation: json['customLocation'] != null
          ? EventLocation.fromJson(json['customLocation'])
          : null,
      services: List<String>.from(json['services'] ?? []),
      foodPreferences: json['foodPreferences'] ?? 'mixed',
      specialRequests: json['specialRequests'],
      budget:
          json['budget'] != null ? EventBudget.fromJson(json['budget']) : null,
      contactPhone: json['contactPhone'] ?? '',
      contactEmail: json['contactEmail'],
      status: json['status'] ?? 'pending',
      adminResponse: json['adminResponse'] != null
          ? AdminResponse.fromJson(json['adminResponse'])
          : null,
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'hotelId': hotelId,
        'eventType': eventType,
        'eventName': eventName,
        'eventDate': eventDate.toIso8601String(),
        'eventTime': eventTime,
        'guestCount': guestCount,
        'venue': venue,
        'customLocation': customLocation?.toJson(),
        'services': services,
        'foodPreferences': foodPreferences,
        'specialRequests': specialRequests,
        'budget': budget?.toJson(),
        'contactPhone': contactPhone,
        'contactEmail': contactEmail,
      };

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get eventTypeDisplay {
    switch (eventType) {
      case 'wedding':
        return '💒 Wedding';
      case 'birthday':
        return '🎂 Birthday';
      case 'ceremony':
        return '🎉 Ceremony';
      case 'corporate':
        return '💼 Corporate';
      case 'graduation':
        return '🎓 Graduation';
      case 'anniversary':
        return '💕 Anniversary';
      default:
        return '🎊 Event';
    }
  }
}

class EventLocation {
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;

  EventLocation({this.address, this.city, this.latitude, this.longitude});

  factory EventLocation.fromJson(Map<String, dynamic> json) => EventLocation(
        address: json['address'],
        city: json['city'],
        latitude: json['latitude']?.toDouble(),
        longitude: json['longitude']?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class EventBudget {
  final double? min;
  final double? max;
  final String currency;

  EventBudget({this.min, this.max, this.currency = 'ETB'});

  factory EventBudget.fromJson(Map<String, dynamic> json) => EventBudget(
        min: json['min']?.toDouble(),
        max: json['max']?.toDouble(),
        currency: json['currency'] ?? 'ETB',
      );

  Map<String, dynamic> toJson() =>
      {'min': min, 'max': max, 'currency': currency};
}

class AdminResponse {
  final String? message;
  final double? quotation;
  final DateTime? respondedAt;

  AdminResponse({this.message, this.quotation, this.respondedAt});

  factory AdminResponse.fromJson(Map<String, dynamic> json) => AdminResponse(
        message: json['message'],
        quotation: json['quotation']?.toDouble(),
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'])
            : null,
      );
}
