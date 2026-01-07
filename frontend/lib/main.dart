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
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/admin_login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/admin/admin_dashboard_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
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
  // Separate auth providers for admin and user sessions
  late AuthProvider _userAuthProvider;
  late AuthProvider _adminAuthProvider;

  @override
  void initState() {
    super.initState();
    // Initialize separate auth providers for user and admin
    _userAuthProvider = AuthProvider()..init(sessionType: SessionType.user);
    _adminAuthProvider = AuthProvider()..init(sessionType: SessionType.admin);

    // Set up 401 handler - will logout the appropriate session
    ApiService.setUnauthorizedCallback(() {
      // Logout both sessions on 401 (token expired)
      _userAuthProvider.logout();
      _adminAuthProvider.logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // User auth provider (default)
        ChangeNotifierProvider.value(value: _userAuthProvider),
        ChangeNotifierProvider(create: (_) => FoodProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'FoodieGo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // Scroll behavior for web/desktop
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          physics: const BouncingScrollPhysics(),
        ),

        initialRoute: '/',
        onGenerateRoute: (settings) {
          // Admin routes - ONLY accessible via /admin URL
          // Uses separate admin auth provider
          if (settings.name == '/admin' ||
              settings.name?.startsWith('/admin') == true) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (_, __, ___) => ChangeNotifierProvider.value(
                value: _adminAuthProvider,
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    // Ensure admin session type is set
                    StorageUtils.setSessionType(SessionType.admin);

                    if (!auth.isLoggedIn) {
                      return const AdminLoginPage();
                    }
                    if (auth.user?.role == 'admin') {
                      return const AdminDashboardPage();
                    }
                    return _AccessDeniedPage(authProvider: _adminAuthProvider);
                  },
                ),
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }

          // Default user routes - uses user auth provider
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => Consumer<AuthProvider>(
              builder: (context, auth, _) {
                // Ensure user session type is set
                StorageUtils.setSessionType(SessionType.user);

                if (!auth.isLoggedIn) {
                  return const LoginPage();
                }
                if (auth.user?.role == 'admin') {
                  return _AdminMustUsePortalPage(
                      authProvider: _userAuthProvider);
                }
                return const HomePage();
              },
            ),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
    );
  }
}

// Access denied page for non-admin users
class _AccessDeniedPage extends StatelessWidget {
  final AuthProvider authProvider;

  const _AccessDeniedPage({required this.authProvider});

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
                  'You do not have permission\nto access the admin area.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.buttonShadow,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.home_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Go to Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
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

// Page shown when admin tries to access user area
class _AdminMustUsePortalPage extends StatelessWidget {
  final AuthProvider authProvider;

  const _AdminMustUsePortalPage({required this.authProvider});

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
                        AppTheme.secondaryColor.withValues(alpha: 0.1),
                        AppTheme.secondaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      size: 64, color: AppTheme.secondaryColor),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Admin Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please use the admin portal\nto manage your restaurant.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.secondaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.dashboard_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Go to Admin Portal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    authProvider.logout();
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  icon: const Icon(Icons.logout_rounded),
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
