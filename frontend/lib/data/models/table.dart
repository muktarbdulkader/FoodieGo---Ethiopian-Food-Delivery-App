/// Table Model - For QR-based dine-in ordering
class TableModel {
  final String id;
  final String restaurantId;
  final String tableNumber;
  final String qrCodeData;
  final int capacity;
  final bool isActive;
  final String location;
  final TableSession? currentSession;

  TableModel({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.qrCodeData,
    this.capacity = 4,
    this.isActive = true,
    this.location = '',
    this.currentSession,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    // Handle restaurantId - can be String or populated Object
    String restaurantIdValue = '';
    if (json['restaurantId'] is String) {
      restaurantIdValue = json['restaurantId'];
    } else if (json['restaurantId'] is Map) {
      restaurantIdValue = json['restaurantId']['_id'] ?? json['restaurantId']['id'] ?? '';
    }
    
    return TableModel(
      id: json['_id'] ?? '',
      restaurantId: restaurantIdValue,
      tableNumber: json['tableNumber'] ?? '',
      qrCodeData: json['qrCodeData'] ?? '',
      capacity: json['capacity'] ?? 4,
      isActive: json['isActive'] ?? true,
      location: json['location'] ?? '',
      currentSession: json['currentSession'] != null
          ? TableSession.fromJson(json['currentSession'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'qrCodeData': qrCodeData,
      'capacity': capacity,
      'isActive': isActive,
      'location': location,
      'currentSession': currentSession?.toJson(),
    };
  }
}

class TableSession {
  final bool isOccupied;
  final String? customerId;
  final DateTime? startTime;
  final List<String> orderIds;

  TableSession({
    this.isOccupied = false,
    this.customerId,
    this.startTime,
    this.orderIds = const [],
  });

  factory TableSession.fromJson(Map<String, dynamic> json) {
    return TableSession(
      isOccupied: json['isOccupied'] ?? false,
      customerId: json['customerId'],
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : null,
      orderIds: json['orderIds'] != null
          ? List<String>.from(json['orderIds'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isOccupied': isOccupied,
      'customerId': customerId,
      'startTime': startTime?.toIso8601String(),
      'orderIds': orderIds,
    };
  }
}
