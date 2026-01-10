import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_utils.dart';
import 'data/services/api_service.dart';
import 'state/auth/auth_provider.dart';
import 'state/food/food_provider.dart';
import 'state/cart/cart_provider.dart';
import 'state/order/order_provider.dart';
import 'state/admin/admin_provider.dart';
import 'state/language/language_provider.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/admin_login_page.dart';
import 'presentation/pages/auth/delivery_login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/admin/admin_dashboard_page.dart';
import 'presentation/pages/language/language_selection_page.dart';
import 'presentation/pages/delivery/delivery_dashboard_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await StorageUtils.init();
  runApp(const FoodieGoApp());
}

class FoodieGoApp extends StatefulWidget {
  const FoodieGoApp({super.key});

  @override
  State<FoodieGoApp> createState() => _FoodieGoAppState();
}

class _FoodieGoAppState extends State<FoodieGoApp> {
  // Separate auth providers for each session type
  late AuthProvider _userAuthProvider;
  late AuthProvider _adminAuthProvider;
  late AuthProvider _deliveryAuthProvider;
  late LanguageProvider _languageProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Get the last session type BEFORE initializing providers
    final lastSession = StorageUtils.currentSessionType;

    // Initialize separate auth providers for each role
    // Don't change the session type during init - just load the data
    _userAuthProvider = AuthProvider()
      ..initWithoutSettingSession(sessionType: SessionType.user);
    _adminAuthProvider = AuthProvider()
      ..initWithoutSettingSession(sessionType: SessionType.admin);
    _deliveryAuthProvider = AuthProvider()
      ..initWithoutSettingSession(sessionType: SessionType.delivery);
    _languageProvider = LanguageProvider();

    // Restore the correct session type
    StorageUtils.setSessionType(lastSession);

    _initLanguage();

    // Set up 401 handler - logout only the current session
    ApiService.setUnauthorizedCallback(() {
      final currentSession = StorageUtils.currentSessionType;
      switch (currentSession) {
        case SessionType.admin:
          _adminAuthProvider.logout();
          break;
        case SessionType.delivery:
          _deliveryAuthProvider.logout();
          break;
        case SessionType.user:
          _userAuthProvider.logout();
          break;
      }
    });
  }

  Future<void> _initLanguage() async {
    await _languageProvider.init();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _languageProvider),
        ChangeNotifierProvider.value(value: _userAuthProvider),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: 'FoodieGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          initialRoute: _getInitialRoute(),
          onGenerateRoute: (settings) {
            // ADMIN/RESTAURANT PORTAL - /admin routes
            if (settings.name?.startsWith('/admin') == true) {
              return _buildAdminRoute(settings);
            }
            // DELIVERY PORTAL - /delivery routes
            if (settings.name?.startsWith('/delivery') == true) {
              return _buildDeliveryRoute(settings);
            }
            // USER PORTAL - default routes
            return _buildUserRoute(settings);
          },
        ),
      ),
    );
  }

  /// Determine initial route based on last session and login status
  String _getInitialRoute() {
    final lastSession = StorageUtils.currentSessionType;

    // Check which sessions are logged in
    final isUserLoggedIn = StorageUtils.isLoggedIn(SessionType.user);
    final isAdminLoggedIn = StorageUtils.isLoggedIn(SessionType.admin);
    final isDeliveryLoggedIn = StorageUtils.isLoggedIn(SessionType.delivery);

    // If last session is still logged in, go there
    switch (lastSession) {
      case SessionType.admin:
        if (isAdminLoggedIn) return '/admin';
        break;
      case SessionType.delivery:
        if (isDeliveryLoggedIn) return '/delivery';
        break;
      case SessionType.user:
        if (isUserLoggedIn) return '/';
        break;
    }

    // If last session is not logged in, check others
    if (isAdminLoggedIn) return '/admin';
    if (isDeliveryLoggedIn) return '/delivery';

    // Default to user login
    return '/';
  }

  /// Build admin/restaurant portal route
  PageRouteBuilder _buildAdminRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
        value: _adminAuthProvider,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            StorageUtils.setSessionType(SessionType.admin);

            if (!auth.isLoggedIn) {
              return const AdminLoginPage();
            }
            if (auth.user?.role == 'restaurant') {
              return const AdminDashboardPage();
            }
            return _AccessDeniedPage(
              authProvider: _adminAuthProvider,
              message: 'Restaurant access only',
              redirectRoute: '/admin',
            );
          },
        ),
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Build delivery portal route
  PageRouteBuilder _buildDeliveryRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
        value: _deliveryAuthProvider,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            StorageUtils.setSessionType(SessionType.delivery);

            if (!auth.isLoggedIn) {
              return const _DeliveryLoginPage();
            }
            if (auth.user?.role == 'delivery') {
              return const DeliveryDashboardPage();
            }
            return _AccessDeniedPage(
              authProvider: _deliveryAuthProvider,
              message: 'Delivery access only',
              redirectRoute: '/delivery',
            );
          },
        ),
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Build user portal route
  PageRouteBuilder _buildUserRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => FutureBuilder<bool>(
        future: _languageProvider.hasSelectedLanguage(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (!snapshot.data!) {
            return const LanguageSelectionPage();
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              StorageUtils.setSessionType(SessionType.user);

              if (!auth.isLoggedIn) {
                return const LoginPage();
              }
              // If user is restaurant role, redirect to admin portal
              if (auth.user?.role == 'restaurant') {
                return _PortalRedirectPage(
                  title: 'Restaurant Account',
                  message:
                      'Please use the Restaurant Portal\nto manage your hotel.',
                  icon: Icons.restaurant,
                  color: AppTheme.secondaryColor,
                  buttonText: 'Go to Restaurant Portal',
                  onButtonPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                  onLogout: () {
                    _userAuthProvider.logout();
                  },
                );
              }
              // If user is delivery role, redirect to delivery portal
              if (auth.user?.role == 'delivery') {
                return _PortalRedirectPage(
                  title: 'Delivery Account',
                  message:
                      'Please use the Delivery Portal\nto manage deliveries.',
                  icon: Icons.delivery_dining,
                  color: Colors.orange,
                  buttonText: 'Go to Delivery Portal',
                  onButtonPressed: () {
                    Navigator.pushReplacementNamed(context, '/delivery');
                  },
                  onLogout: () {
                    _userAuthProvider.logout();
                  },
                );
              }
              return const HomePage();
            },
          );
        },
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

/// Delivery Login Page - Separate login for delivery partners
class _DeliveryLoginPage extends StatelessWidget {
  const _DeliveryLoginPage();

  @override
  Widget build(BuildContext context) {
    return const DeliveryLoginPage();
  }
}

/// Access denied page
class _AccessDeniedPage extends StatelessWidget {
  final AuthProvider authProvider;
  final String message;
  final String redirectRoute;

  const _AccessDeniedPage({
    required this.authProvider,
    required this.message,
    required this.redirectRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.errorColor.withValues(alpha: 0.1),
                        AppTheme.errorColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      size: 64, color: AppTheme.errorColor),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, redirectRoute);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout & Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Portal redirect page - shown when user is in wrong portal
class _PortalRedirectPage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final VoidCallback onLogout;

  const _PortalRedirectPage({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.buttonText,
    required this.onButtonPressed,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: color),
                ),
                const SizedBox(height: 32),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onButtonPressed,
                  icon: Icon(icon),
                  label: Text(buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
