import '../models/user.dart';
import '../models/food.dart';
import '../services/api_service.dart';

class AdminRepository {
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await ApiService.get('/admin/dashboard');
    return response['data'];
  }

  Future<List<User>> getAllUsers() async {
    final response = await ApiService.get('/admin/users');
    return (response['data'] as List).map((u) => User.fromJson(u)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllUsersRaw() async {
    final response = await ApiService.get('/admin/users');
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await ApiService.get('/admin/users/$userId');
    return response['data'];
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await ApiService.put('/admin/users/$userId', data);
  }

  Future<void> updateUserRole(String userId, String role) async {
    await ApiService.put('/admin/users/$userId/role', {'role': role});
  }

  Future<void> deleteUser(String userId) async {
    await ApiService.delete('/admin/users/$userId');
  }

  // Payments
  Future<Map<String, dynamic>> getAllPayments() async {
    final response = await ApiService.get('/admin/payments');
    return response['data'];
  }

  Future<void> updatePaymentStatus(String orderId, String status) async {
    await ApiService.put('/admin/payments/$orderId', {'status': status});
  }

  // Deliveries
  Future<Map<String, dynamic>> getDeliveryManagement() async {
    final response = await ApiService.get('/admin/deliveries');
    return response['data'];
  }

  Future<void> assignDriver(
      String orderId, String driverName, String driverPhone) async {
    await ApiService.put('/admin/deliveries/$orderId/assign', {
      'driverName': driverName,
      'driverPhone': driverPhone,
    });
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics(String period) async {
    final response = await ApiService.get('/admin/analytics?period=$period');
    return response['data'];
  }

  // Foods
  Future<Food> createFood(Map<String, dynamic> data) async {
    final response = await ApiService.post('/foods', data);
    return Food.fromJson(response['data']);
  }

  Future<Food> updateFood(String id, Map<String, dynamic> data) async {
    final response = await ApiService.put('/foods/$id', data);
    return Food.fromJson(response['data']);
  }

  Future<void> deleteFood(String id) async {
    await ApiService.delete('/foods/$id');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await ApiService.put('/orders/$orderId/status', {'status': status});
  }
}
