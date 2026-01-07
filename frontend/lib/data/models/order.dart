import 'cart_item.dart';

class DeliveryAddress {
  final String label;
  final String fullAddress;
  final String? street;
  final String? city;
  final String? state;
  final String? zipCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? instructions;

  DeliveryAddress({
    this.label = 'Home',
    required this.fullAddress,
    this.street,
    this.city,
    this.state,
    this.zipCode,
    this.country,
    this.latitude,
    this.longitude,
    this.instructions,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      label: json['label']?.toString() ?? 'Home',
      fullAddress: json['fullAddress']?.toString() ?? '',
      street: json['street']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      zipCode: json['zipCode']?.toString(),
      country: json['country']?.toString(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'fullAddress': fullAddress,
        'street': street,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
        'instructions': instructions,
      };
}

class Payment {
  final String method;
  final String status;
  final String? transactionId;
  final String? cardLast4;
  final DateTime? paidAt;

  Payment({
    this.method = 'cash',
    this.status = 'pending',
    this.transactionId,
    this.cardLast4,
    this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      method: json['method']?.toString() ?? 'cash',
      status: json['status']?.toString() ?? 'pending',
      transactionId: json['transactionId']?.toString(),
      cardLast4: json['cardLast4']?.toString(),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'status': status,
        'transactionId': transactionId,
        'cardLast4': cardLast4,
      };
}

class Delivery {
  final String type;
  final double fee;
  final int estimatedTime;
  final double? distance;
  final String? driverName;
  final String? driverPhone;
  final String trackingStatus;
  final DateTime? deliveredAt;

  Delivery({
    this.type = 'delivery',
    this.fee = 2.99,
    this.estimatedTime = 30,
    this.distance,
    this.driverName,
    this.driverPhone,
    this.trackingStatus = 'pending',
    this.deliveredAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      type: json['type']?.toString() ?? 'delivery',
      fee: (json['fee'] ?? 2.99).toDouble(),
      estimatedTime: json['estimatedTime'] ?? 30,
      distance: (json['distance'] as num?)?.toDouble(),
      driverName: json['driverName']?.toString(),
      driverPhone: json['driverPhone']?.toString(),
      trackingStatus: json['trackingStatus']?.toString() ?? 'pending',
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'fee': fee,
        'estimatedTime': estimatedTime,
      };
}

class Order {
  final String id;
  final String orderNumber;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double tip;
  final double discount;
  final double totalPrice;
  final String status;
  final DeliveryAddress? deliveryAddress;
  final Payment? payment;
  final Delivery? delivery;
  final String? notes;
  final String? promoCode;
  final String? cancelReason;
  final DateTime? createdAt;

  Order({
    required this.id,
    this.orderNumber = '',
    required this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    required this.items,
    this.subtotal = 0,
    this.deliveryFee = 2.99,
    this.tax = 0,
    this.tip = 0,
    this.discount = 0,
    required this.totalPrice,
    this.status = 'pending',
    this.deliveryAddress,
    this.payment,
    this.delivery,
    this.notes,
    this.promoCode,
    this.cancelReason,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Handle user field - can be string ID or object
    String oderId = '';
    String? userName;
    String? userEmail;
    String? userPhone;
    if (json['user'] is Map) {
      oderId = json['user']['_id'] ?? json['user']['id'] ?? '';
      userName = json['user']['name'];
      userEmail = json['user']['email'];
      userPhone = json['user']['phone'];
    } else {
      oderId = json['user']?.toString() ?? '';
    }

    return Order(
      id: json['_id'] ?? json['id'] ?? '',
      orderNumber: json['orderNumber']?.toString() ?? '',
      userId: oderId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 2.99).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      tip: (json['tip'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status']?.toString() ?? 'pending',
      deliveryAddress: json['deliveryAddress'] is Map
          ? DeliveryAddress.fromJson(json['deliveryAddress'])
          : null,
      payment:
          json['payment'] is Map ? Payment.fromJson(json['payment']) : null,
      delivery:
          json['delivery'] is Map ? Delivery.fromJson(json['delivery']) : null,
      notes: json['notes']?.toString(),
      promoCode: json['promoCode']?.toString(),
      cancelReason: json['cancelReason']?.toString(),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'tax': tax,
      'tip': tip,
      'discount': discount,
      'totalPrice': totalPrice,
      'deliveryAddress': deliveryAddress?.toJson(),
      'payment': payment?.toJson(),
      'delivery': delivery?.toJson(),
      'notes': notes,
      'promoCode': promoCode,
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get deliveryStatusDisplay {
    if (delivery == null) return 'Pending';
    switch (delivery!.trackingStatus) {
      case 'pending':
        return 'Waiting for driver';
      case 'assigned':
        return 'Driver assigned';
      case 'picked_up':
        return 'Order picked up';
      case 'on_the_way':
        return 'On the way';
      case 'arrived':
        return 'Driver arrived';
      case 'delivered':
        return 'Delivered';
      default:
        return delivery!.trackingStatus;
    }
  }
}
