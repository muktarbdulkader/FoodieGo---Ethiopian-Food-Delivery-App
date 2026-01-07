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

    final response = await ApiService.post(ApiConstants.register, body);

    final data = response['data'];
    final user = User.fromJson(data['user']);

    await StorageUtils.saveToken(data['token']);
    await StorageUtils.saveUser(jsonEncode(data['user']));

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

    await StorageUtils.saveToken(data['token']);
    await StorageUtils.saveUser(jsonEncode(data['user']));

    return user;
  }

  Future<void> logout() async {
    await StorageUtils.clear();
  }

  User? getCurrentUser() {
    final userJson = StorageUtils.getUser();
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  bool isLoggedIn() {
    return StorageUtils.isLoggedIn();
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
}
