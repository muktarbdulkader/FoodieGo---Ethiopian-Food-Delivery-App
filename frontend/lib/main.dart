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
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..init();

    // Set up 401 handler to auto-logout
    ApiService.setUnauthorizedCallback(() {
      _authProvider.logout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
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
          if (settings.name == '/admin' ||
              settings.name?.startsWith('/admin') == true) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (_, __, ___) => Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (!auth.isLoggedIn) {
                    return const AdminLoginPage();
                  }
                  if (auth.user?.role == 'admin') {
                    return const AdminDashboardPage();
                  }
                  return const _AccessDeniedPage();
                },
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          }

          // Default user routes
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (_, __, ___) => Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (!auth.isLoggedIn) {
                  return const LoginPage();
                }
                if (auth.user?.role == 'admin') {
                  return const _AdminMustUsePortalPage();
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
  const _AccessDeniedPage();

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
                    context.read<AuthProvider>().logout();
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
  const _AdminMustUsePortalPage();

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
                    context.read<AuthProvider>().logout();
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
