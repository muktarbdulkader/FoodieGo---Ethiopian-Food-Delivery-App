import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_utils.dart';

/// Callback for handling 401 unauthorized errors
typedef UnauthorizedCallback = void Function();

/// Callback for network status changes
typedef NetworkStatusCallback = void Function(bool isOnline);

class ApiService {
  static UnauthorizedCallback? _onUnauthorized;
  static NetworkStatusCallback? _onNetworkStatusChange;
  static bool _isOnline = true;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Set callback to handle 401 errors (logout and redirect)
  static void setUnauthorizedCallback(UnauthorizedCallback callback) {
    _onUnauthorized = callback;
  }

  /// Set callback for network status changes
  static void setNetworkStatusCallback(NetworkStatusCallback callback) {
    _onNetworkStatusChange = callback;
  }

  /// Check if currently online
  static bool get isOnline => _isOnline;

  /// GET request with retry logic
  static Future<Map<String, dynamic>> get(String endpoint) async {
    return _executeWithRetry(() async {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _getHeaders(),
          )
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    });
  }

  /// POST request with retry logic
  static Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> body) async {
    return _executeWithRetry(() async {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    });
  }

  /// PUT request with retry logic
  static Future<Map<String, dynamic>> put(
      String endpoint, Map<String, dynamic> body) async {
    return _executeWithRetry(() async {
      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _getHeaders(),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    });
  }

  /// DELETE request with retry logic
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return _executeWithRetry(() async {
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _getHeaders(),
          )
          .timeout(ApiConstants.timeout);
      return _handleResponse(response);
    });
  }

  /// Execute request with automatic retry on network failures
  static Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() request, {
    int retryCount = 0,
  }) async {
    try {
      final result = await request();
      _updateNetworkStatus(true);
      return result;
    } on SocketException catch (e) {
      _updateNetworkStatus(false);
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _executeWithRetry(request, retryCount: retryCount + 1);
      }
      // Check specific socket errors
      final msg = e.message.toLowerCase();
      if (msg.contains('failed host lookup') || msg.contains('no address')) {
        throw ApiException(
            'Cannot reach server. Check your internet connection.', 0);
      }
      if (msg.contains('connection refused') ||
          msg.contains('connection reset')) {
        throw ApiException(
            'Server unavailable. Please try again in a moment.', 0);
      }
      throw ApiException(
          'No internet connection. Please check your network.', 0);
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _executeWithRetry(request, retryCount: retryCount + 1);
      }
      // Server timeout - likely server is waking up or slow
      throw ApiException(
          'Server is starting up. Please wait a moment and try again.', 408);
    } on http.ClientException {
      _updateNetworkStatus(false);
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _executeWithRetry(request, retryCount: retryCount + 1);
      }
      throw ApiException(
          'Unable to connect to server. Please check your internet connection.',
          0);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _executeWithRetry(request, retryCount: retryCount + 1);
      }
      throw ApiException(
          'Something went wrong. Please check your internet and try again.', 0);
    }
  }

  static void _updateNetworkStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _onNetworkStatusChange?.call(isOnline);
    }
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
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException('Invalid server response', response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return body;

    // Handle 401 unauthorized
    if (response.statusCode == 401) {
      StorageUtils.clear();
      _onUnauthorized?.call();
      throw ApiException('Session expired. Please login again.', 401);
    }

    // Handle 500 server errors
    if (response.statusCode >= 500) {
      throw ApiException(
          'Server error. Please try again later.', response.statusCode);
    }

    throw ApiException(
        body['message'] ?? 'An error occurred', response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final bool isNetworkError;

  ApiException(this.message, this.statusCode)
      : isNetworkError = statusCode == 0;

  @override
  String toString() => message;

  /// Check if error is recoverable (network issues, timeouts)
  bool get isRecoverable => statusCode == 0 || statusCode >= 500;
}
