import 'package:flutter/foundation.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/utils/storage_utils.dart';

/// Auth Provider - Extended for Hotel Management
/// Supports separate admin, user, and delivery sessions
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  User? _user;
  bool _isLoading = false;
  String? _error;
  SessionType _sessionType = SessionType.user;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.role == 'restaurant';
  bool get isRestaurant => _user?.role == 'restaurant';
  bool get isDelivery => _user?.role == 'delivery';
  SessionType get sessionType => _sessionType;

  /// Initialize with specific session type (based on route)
  void init({SessionType sessionType = SessionType.user}) {
    _sessionType = sessionType;
    StorageUtils.setSessionType(sessionType);
    _user = _authRepository.getCurrentUser(sessionType);
    notifyListeners();
  }

  /// Initialize without changing the global session type
  /// Used during app startup to load all sessions without conflicts
  void initWithoutSettingSession({SessionType sessionType = SessionType.user}) {
    _sessionType = sessionType;
    _user = _authRepository.getCurrentUser(sessionType);
    notifyListeners();
  }

  /// Switch session type (when navigating between portals)
  void switchSessionType(SessionType type) {
    if (_sessionType != type) {
      _sessionType = type;
      StorageUtils.setSessionType(type);
      _user = _authRepository.getCurrentUser(type);
      notifyListeners();
    }
  }

  /// Register new user (supports admin with hotel info)
  Future<bool> register({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        role: role,
        adminCode: adminCode,
        hotelName: hotelName,
        hotelAddress: hotelAddress,
        hotelImage: hotelImage,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Register delivery personnel
  Future<bool> registerDelivery({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String adminCode,
  }) async {
    return register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: 'delivery',
      adminCode: adminCode,
    );
  }

  /// Update user location
  Future<bool> updateLocation({
    required double latitude,
    required double longitude,
    required String address,
    required String city,
  }) async {
    try {
      _user = await _authRepository.updateLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: city,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String name,
    String? phone,
    String? address,
  }) async {
    try {
      _user = await _authRepository.updateProfile(
        name: name,
        phone: phone,
        address: address,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh user data from storage
  void refreshUser() {
    _user = _authRepository.getCurrentUser();
    notifyListeners();
  }

  /// Update user object directly (after settings change)
  void updateUser(User updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }
}
