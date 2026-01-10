/// API Constants
/// Contains all API-related configuration values
class ApiConstants {
  // Set to true for production build, false for local development
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // Production URL - FoodieGo backend on Render
  static const String productionUrl = 'https://foodiego-tqz4.onrender.com/api';

  // Development URL - localhost for testing
  static const String developmentUrl = 'http://localhost:5001/api';

  // Automatically select URL based on environment
  static String get baseUrl => isProduction ? productionUrl : developmentUrl;

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
