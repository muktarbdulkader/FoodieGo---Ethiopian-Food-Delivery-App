import 'dart:convert';
import '../models/user.dart';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_utils.dart';

/// Auth Repository - Extended for Hotel Management
class AuthRepository {
  /// Register a new user (supports admin with hotel info)
  Future<User> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
    String role = 'user',
    String? adminCode,
    String? hotelName,
    String? hotelAddress,
    String? hotelImage,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (adminCode != null) body['adminCode'] = adminCode;
    if (hotelName != null && hotelName.isNotEmpty) {
      body['hotelName'] = hotelName;
    }
    if (hotelAddress != null && hotelAddress.isNotEmpty) {
      body['hotelAddress'] = hotelAddress;
    }
    if (hotelImage != null && hotelImage.isNotEmpty) {
      body['hotelImage'] = hotelImage;
    }

    final response = await ApiService.post(ApiConstants.register, body);

    final data = response['data'];
    final user = User.fromJson(data['user']);

    // Determine session type based on role
    SessionType sessionType;
    switch (user.role) {
      case 'restaurant':
        sessionType = SessionType.admin;
        break;
      case 'delivery':
        sessionType = SessionType.delivery;
        break;
      default:
        sessionType = SessionType.user;
    }

    StorageUtils.setSessionType(sessionType);
    await StorageUtils.saveToken(data['token'], sessionType);
    await StorageUtils.saveUser(jsonEncode(data['user']), sessionType);

    return user;
  }

  /// Login user
  Future<User> login({required String email, required String password}) async {
    final response = await ApiService.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });

    final data = response['data'];
    final user = User.fromJson(data['user']);

    // Determine session type based on role
    SessionType sessionType;
    switch (user.role) {
      case 'restaurant':
        sessionType = SessionType.admin;
        break;
      case 'delivery':
        sessionType = SessionType.delivery;
        break;
      default:
        sessionType = SessionType.user;
    }

    StorageUtils.setSessionType(sessionType);
    await StorageUtils.saveToken(data['token'], sessionType);
    await StorageUtils.saveUser(jsonEncode(data['user']), sessionType);

    return user;
  }

  Future<void> logout() async {
    await StorageUtils.clear();
  }

  User? getCurrentUser([SessionType? sessionType]) {
    final type = sessionType ?? StorageUtils.currentSessionType;
    final userJson = StorageUtils.getUser(type);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  bool isLoggedIn([SessionType? sessionType]) {
    final type = sessionType ?? StorageUtils.currentSessionType;
    return StorageUtils.isLoggedIn(type);
  }

  /// Update user location
  Future<User> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
    required String city,
  }) async {
    final response = await ApiService.put('${ApiConstants.auth}/location', {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
    });

    final user = User.fromJson(response['data']);
    await StorageUtils.saveUser(jsonEncode(response['data']));
    return user;
  }

  /// Update user profile
  Future<User> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final response = await ApiService.put('${ApiConstants.auth}/profile', body);
    final user = User.fromJson(response['data']);
    await StorageUtils.saveUser(jsonEncode(response['data']));
    return user;
  }

  /// Update hotel settings (for restaurant owners)
  Future<User> updateHotelSettings({
    String? hotelName,
    String? hotelAddress,
    String? hotelPhone,
    String? hotelDescription,
    String? hotelImage,
    String? hotelCategory,
    bool? isOpen,
    double? deliveryFee,
    double? minOrderAmount,
    double? deliveryRadius,
  }) async {
    final body = <String, dynamic>{};
    if (hotelName != null) body['hotelName'] = hotelName;
    if (hotelAddress != null) body['hotelAddress'] = hotelAddress;
    if (hotelPhone != null) body['hotelPhone'] = hotelPhone;
    if (hotelDescription != null) body['hotelDescription'] = hotelDescription;
    if (hotelImage != null) body['hotelImage'] = hotelImage;
    if (hotelCategory != null) body['hotelCategory'] = hotelCategory;
    if (isOpen != null) body['isOpen'] = isOpen;
    if (deliveryFee != null) body['deliveryFee'] = deliveryFee;
    if (minOrderAmount != null) body['minOrderAmount'] = minOrderAmount;
    if (deliveryRadius != null) body['deliveryRadius'] = deliveryRadius;

    final response =
        await ApiService.put('${ApiConstants.auth}/hotel-settings', body);
    final user = User.fromJson(response['data']);
    await StorageUtils.saveUser(
        jsonEncode(response['data']), SessionType.admin);
    return user;
  }
}
