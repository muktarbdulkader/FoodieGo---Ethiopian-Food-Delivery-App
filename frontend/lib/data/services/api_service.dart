import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_utils.dart';

/// Callback for handling 401 unauthorized errors
typedef UnauthorizedCallback = void Function();

class ApiService {
  static UnauthorizedCallback? _onUnauthorized;

  /// Set callback to handle 401 errors (logout and redirect)
  static void setUnauthorizedCallback(UnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _getHeaders(),
        )
        .timeout(ApiConstants.timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(ApiConstants.timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .put(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(ApiConstants.timeout);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http
        .delete(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _getHeaders(),
        )
        .timeout(ApiConstants.timeout);
    return _handleResponse(response);
  }

  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    };
    final token = StorageUtils.getToken();
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    // Clear token on 401 and trigger logout callback
    if (response.statusCode == 401) {
      StorageUtils.clear();
      _onUnauthorized?.call();
    }

    throw ApiException(
        body['message'] ?? 'An error occurred', response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
