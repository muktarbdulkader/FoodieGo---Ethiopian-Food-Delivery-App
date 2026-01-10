import 'package:flutter/foundation.dart';
import '../../data/models/order.dart';
import '../../data/repositories/admin_repository.dart';
import '../../data/repositories/order_repository.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepo = AdminRepository();
  final OrderRepository _orderRepo = OrderRepository();

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _users = [];
  List<Order> _allOrders = [];
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _paymentStats = [];
  List<Map<String, dynamic>> _activeDeliveries = [];
  Map<String, dynamic>? _analytics;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get stats => _stats;
  List<Map<String, dynamic>> get users => _users;
  List<Order> get allOrders => _allOrders;
  List<Map<String, dynamic>> get transactions => _transactions;
  List<Map<String, dynamic>> get paymentStats => _paymentStats;
  List<Map<String, dynamic>> get activeDeliveries => _activeDeliveries;
  Map<String, dynamic>? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await _adminRepo.getDashboardStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _users = await _adminRepo.getAllUsersRaw();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllOrders() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allOrders = await _orderRepo.getAllOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _adminRepo.getAllPayments();
      _transactions =
          (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _paymentStats =
          (data['stats'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDeliveries() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _adminRepo.getDeliveryManagement();
      _activeDeliveries =
          (data['activeDeliveries'] as List?)?.cast<Map<String, dynamic>>() ??
              [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalytics(String period) async {
    _isLoading = true;
    notifyListeners();
    try {
      _analytics = await _adminRepo.getAnalytics(period);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _adminRepo.updateOrderStatus(orderId, status);
      await fetchAllOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String status) async {
    try {
      await _adminRepo.updatePaymentStatus(orderId, status);
      await fetchPayments();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignDriver(
      String orderId, String driverName, String driverPhone) async {
    try {
      await _adminRepo.assignDriver(orderId, driverName, driverPhone);
      await fetchAllOrders();
      await fetchDeliveries();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, String role) async {
    try {
      await _adminRepo.updateUserRole(userId, role);
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _adminRepo.deleteUser(userId);
      await fetchUsers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String orderId) async {
    try {
      await _adminRepo.deleteOrder(orderId);
      _allOrders.removeWhere((o) => o.id == orderId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> createFood(Map<String, dynamic> data) async {
    try {
      await _adminRepo.createFood(data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteFood(String id) async {
    try {
      await _adminRepo.deleteFood(id);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateFood(String id, Map<String, dynamic> data) async {
    try {
      await _adminRepo.updateFood(id, data);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
