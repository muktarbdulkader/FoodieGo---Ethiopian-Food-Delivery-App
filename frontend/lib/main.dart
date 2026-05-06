import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/storage_utils.dart';
import 'core/services/notification_service.dart';
import 'data/services/api_service.dart';
import 'state/auth/auth_provider.dart';
import 'state/food/food_provider.dart';
import 'state/cart/cart_provider.dart';
import 'state/order/order_provider.dart';
import 'state/admin/admin_provider.dart';
import 'state/language/language_provider.dart';
import 'state/dine_in/dine_in_provider.dart';
import 'state/websocket/websocket_provider.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/admin_login_page.dart';
import 'presentation/pages/auth/delivery_login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/admin/admin_dashboard_page.dart';
import 'presentation/pages/language/language_selection_page.dart';
import 'presentation/pages/delivery/delivery_dashboard_page.dart';
import 'presentation/pages/dine_in/qr_scanner_page.dart';
import 'presentation/pages/dine_in/dine_in_menu_page.dart';
import 'presentation/pages/splash/splash_page.dart';

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
  await NotificationService.init();
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
  late AppLinks _appLinks;

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
    _initDeepLinks();

    // Set up notification tap handler for driver assignments
    NotificationService.setNotificationTapCallback(_handleNotificationTap);

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

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened from a link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('Error listening to deep links: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    // Handle dine-in menu deep link
    // Example: https://your-app.web.app/dine-in-menu?restaurantId=xxx&tableId=T05
    if (uri.path == '/dine-in-menu') {
      final restaurantId = uri.queryParameters['restaurantId'];
      final tableId = uri.queryParameters['tableId'];
      
      if (restaurantId != null && tableId != null) {
        // Navigate to dine-in menu page
        Future.delayed(const Duration(milliseconds: 500), () {
          navigatorKey.currentState?.pushNamed(
            '/dine-in-menu',
            arguments: {
              'restaurantId': restaurantId,
              'tableId': tableId,
            },
          );
        });
      }
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    // Handle driver assignment notification
    if (payload.startsWith('driver_assignment:')) {
      // Navigate to delivery dashboard
      // Check if user is logged in as delivery
      if (_deliveryAuthProvider.isLoggedIn && 
          _deliveryAuthProvider.user?.role == 'delivery') {
        // Navigate to delivery dashboard
        navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/delivery',
          (route) => false,
        );
      }
    }
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
        ChangeNotifierProvider(create: (_) => DineInProvider()),
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Connect WebSocket if user is logged in
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final token = StorageUtils.getToken();
            if (token != null) {
              final webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);
              if (!webSocketProvider.isConnected) {
                webSocketProvider.connect(token);
                debugPrint('[MAIN] WebSocket connected with token');
              }
            }
          });

          return Consumer<LanguageProvider>(
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
                debugPrint('Generating route for: ${settings.name}');
                
                // SPLASH SCREEN - Show first
                if (settings.name == '/splash') {
                  return PageRouteBuilder(
                    settings: settings,
                    pageBuilder: (_, __, ___) => const SplashPage(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  );
                }
                
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
              onUnknownRoute: (settings) {
                debugPrint('Unknown route: ${settings.name}');
                return _buildUserRoute(settings);
              },
            ),
          );
        },
      ),
    );
  }

  /// Determine initial route based on last session and login status
  String _getInitialRoute() {
    // For web, check if there's a specific path in the URL
    if (kIsWeb) {
      final uri = Uri.base;
      debugPrint('Initial URL path: ${uri.path}, query: ${uri.query}');
      
      // If URL has /dine-in-menu path, return it
      if (uri.path == '/dine-in-menu' && 
          uri.queryParameters.containsKey('restaurantId') && 
          uri.queryParameters.containsKey('tableId')) {
        return '/dine-in-menu';
      }
    }
    
    // Default: show splash screen first
    return '/splash';
  }

  /// Build admin/restaurant portal route
  PageRouteBuilder _buildAdminRoute(RouteSettings settings) {
    // Set admin session type IMMEDIATELY before building route
    StorageUtils.setSessionType(SessionType.admin);
    
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
        value: _adminAuthProvider,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Session type already set above

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
    // Set delivery session type IMMEDIATELY before building route
    StorageUtils.setSessionType(SessionType.delivery);
    
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
        value: _deliveryAuthProvider,
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Session type already set above

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
    // Handle specific routes
    if (settings.name == '/qr-scanner') {
      // Set user session type for QR scanner
      StorageUtils.setSessionType(SessionType.user);
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => const QRScannerPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }
    
    if (settings.name == '/dine-in-menu') {
      // Set user session type for dine-in menu (guests can view without login)
      StorageUtils.setSessionType(SessionType.user);
      
      // Get arguments from route settings or from URL query parameters (for web)
      Map<String, dynamic>? args = settings.arguments as Map<String, dynamic>?;
      
      // For web, if no arguments provided, try to get from URL
      if (kIsWeb && args == null) {
        final uri = Uri.base;
        if (uri.queryParameters.containsKey('restaurantId') && 
            uri.queryParameters.containsKey('tableId')) {
          args = {
            'restaurantId': uri.queryParameters['restaurantId']!,
            'tableId': uri.queryParameters['tableId']!,
          };
        }
      }
      
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => DineInMenuPage(
          restaurantId: args?['restaurantId'] ?? '',
          tableId: args?['tableId'] ?? '',
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    }
    
    // Set user session type for default routes
    StorageUtils.setSessionType(SessionType.user);
    
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
              // Session type already set above

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
