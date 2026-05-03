import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/table.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_utils.dart';

class TableRepository {
  Future<TableModel> getTableByQRCode(String restaurantId, String tableId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/tables/qr?restaurantId=$restaurantId&tableId=$tableId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TableModel.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load table data');
      }
    } catch (e) {
      throw Exception('Failed to load table: $e');
    }
  }

  Future<void> startTableSession(String tableId) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tables/$tableId/session/start'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to start table session');
      }
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  Future<void> endTableSession(String tableId) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tables/$tableId/session/end'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to end table session');
      }
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  Future<void> callWaiter(String tableId, String message) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/dine-in/call-waiter'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'tableId': tableId,
          'message': message,
        }),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to call waiter');
      }
    } catch (e) {
      throw Exception('Failed to call waiter: $e');
    }
  }

  Future<List<TableModel>> getAllTables({String? restaurantId}) async {
    try {
      final token = StorageUtils.getToken();
      final url = restaurantId != null
          ? '${ApiConstants.baseUrl}/tables?restaurantId=$restaurantId'
          : '${ApiConstants.baseUrl}/tables';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tablesJson = data['data'];
        return tablesJson.map((json) => TableModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to load tables');
      }
    } catch (e) {
      throw Exception('Failed to load tables: $e');
    }
  }

  Future<TableModel> createTable({
    required String tableNumber,
    required int capacity,
    String? location,
  }) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tables'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'tableNumber': tableNumber,
          'capacity': capacity,
          if (location != null) 'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TableModel.fromJson(data['data']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create table');
      }
    } catch (e) {
      throw Exception('Failed to create table: $e');
    }
  }

  Future<List<TableModel>> bulkCreateTables({
    required int count,
    String? prefix,
    int? capacity,
    String? location,
  }) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/tables/bulk'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'count': count,
          if (prefix != null) 'prefix': prefix,
          if (capacity != null) 'capacity': capacity,
          if (location != null) 'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final List<dynamic> tablesJson = data['data'];
        return tablesJson.map((json) => TableModel.fromJson(json)).toList();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create tables');
      }
    } catch (e) {
      throw Exception('Failed to create tables: $e');
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      final token = StorageUtils.getToken();
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/tables/$tableId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to delete table');
      }
    } catch (e) {
      throw Exception('Failed to delete table: $e');
    }
  }
}
