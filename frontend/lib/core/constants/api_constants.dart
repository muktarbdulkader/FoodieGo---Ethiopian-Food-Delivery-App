/// API Constants
/// Contains all API-related configuration values
class ApiConstants {
  static const String baseUrl = 'http://localhost:5001/api';

  // Auth endpoints
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Food endpoints
  static const String foods = '/foods';

  // Order endpoints
  static const String orders = '/orders';

  // Request timeout
  static const Duration timeout = Duration(seconds: 30);
}
