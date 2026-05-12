import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../state/food/food_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _foodController;
  late AnimationController _textController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _food1Slide;
  late Animation<double> _food2Slide;
  late Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();

    // Logo animation controller - faster
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Food images animation controller - faster
    _foodController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Text animation controller - faster
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Food images slide animations
    _food1Slide = Tween<double>(begin: -200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _foodController,
        curve: Curves.easeOutBack,
      ),
    );

    _food2Slide = Tween<double>(begin: 200.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _foodController,
        curve: Curves.easeOutBack,
      ),
    );

    // Text fade in
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // Start animations sequence
    _startAnimations();
  }

  void _startAnimations() async {
    // Start logo animation immediately
    _logoController.forward();

    // Start food images animation quickly after
    await Future.delayed(const Duration(milliseconds: 200));
    _foodController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // For web Dine-In, pre-fetch data while splash is showing
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.path == '/dine-in-menu' &&
          uri.queryParameters.containsKey('restaurantId')) {
        final restaurantId = uri.queryParameters['restaurantId']!;
        try {
          // Trigger fetch in background
          await context.read<FoodProvider>().fetchFoodsByHotel(
                restaurantId,
                menuType: 'dine_in',
              );
        } catch (e) {
          debugPrint('Error pre-fetching foods: $e');
        }
      }
    }

    // Minimum delay to ensure animations are seen
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    // For web, check if we're on a dine-in menu URL - if so, don't navigate away
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.path == '/dine-in-menu' &&
          uri.queryParameters.containsKey('restaurantId') &&
          uri.queryParameters.containsKey('tableId')) {
        // Navigate to dine-in menu with parameters
        Navigator.of(context).pushReplacementNamed(
          '/dine-in-menu',
          arguments: {
            'restaurantId': uri.queryParameters['restaurantId']!,
            'tableId': uri.queryParameters['tableId']!,
          },
        );
        return;
      }
    }

    final lastSession = StorageUtils.currentSessionType;
    final isUserLoggedIn = StorageUtils.isLoggedIn(SessionType.user);
    final isAdminLoggedIn = StorageUtils.isLoggedIn(SessionType.admin);
    final isDeliveryLoggedIn = StorageUtils.isLoggedIn(SessionType.delivery);

    String route = '/';

    // Determine which route to navigate to
    switch (lastSession) {
      case SessionType.admin:
        if (isAdminLoggedIn) route = '/admin';
        break;
      case SessionType.delivery:
        if (isDeliveryLoggedIn) route = '/delivery';
        break;
      case SessionType.superAdmin:
        if (StorageUtils.isLoggedIn(SessionType.superAdmin)) route = '/super-admin';
        break;
      case SessionType.user:
        if (isUserLoggedIn) route = '/';
        break;
    }

    // If no one is logged in, check if any session exists
    if (!isUserLoggedIn && !isAdminLoggedIn && !isDeliveryLoggedIn) {
      if (isAdminLoggedIn) {
        route = '/admin';
      } else if (isDeliveryLoggedIn) {
        route = '/delivery';
      }
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _foodController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF6B35),
              Color(0xFFFF8C42),
              Color(0xFFFFA94D),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated food images in background
            _buildFoodImages(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(35),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 70,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // Animated app name
                  AnimatedBuilder(
                    animation: _textController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            const Text(
                              'FoodieGo',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Delicious food at your doorstep',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Loading indicator at bottom
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.7),
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImages() {
    return Stack(
      children: [
        // Food emoji 1 - sliding from left
        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              top: 100,
              left: _food1Slide.value,
              child: Opacity(
                opacity: ((_food1Slide.value + 200) / 200).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: -0.2,
                  child: const Text(
                    '🍕',
                    style: TextStyle(fontSize: 80),
                  ),
                ),
              ),
            );
          },
        ),

        // Food emoji 2 - sliding from right
        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              top: 150,
              right: _food2Slide.value,
              child: Opacity(
                opacity: ((200 - _food2Slide.value) / 200).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: 0.2,
                  child: const Text(
                    '🍔',
                    style: TextStyle(fontSize: 70),
                  ),
                ),
              ),
            );
          },
        ),

        // Food emoji 3 - sliding from left (lower)
        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              bottom: 200,
              left: _food1Slide.value - 50,
              child: Opacity(
                opacity: ((_food1Slide.value + 200) / 200).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: 0.15,
                  child: const Text(
                    '🍜',
                    style: TextStyle(fontSize: 65),
                  ),
                ),
              ),
            );
          },
        ),

        // Food emoji 4 - sliding from right (lower)
        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              bottom: 150,
              right: _food2Slide.value - 30,
              child: Opacity(
                opacity: ((200 - _food2Slide.value) / 200).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: -0.15,
                  child: const Text(
                    '🍰',
                    style: TextStyle(fontSize: 60),
                  ),
                ),
              ),
            );
          },
        ),

        // Additional decorative food emojis
        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              top: 250,
              left: 50 + _food1Slide.value / 2,
              child: Opacity(
                opacity: ((_food1Slide.value + 200) / 300).clamp(0.0, 1.0),
                child: const Text(
                  '🍕',
                  style: TextStyle(fontSize: 50),
                ),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              top: 300,
              right: 60 + _food2Slide.value / 2,
              child: Opacity(
                opacity: ((200 - _food2Slide.value) / 300).clamp(0.0, 1.0),
                child: const Text(
                  '🥗',
                  style: TextStyle(fontSize: 55),
                ),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              bottom: 300,
              left: 80 + _food1Slide.value / 3,
              child: Opacity(
                opacity: ((_food1Slide.value + 200) / 250).clamp(0.0, 1.0),
                child: const Text(
                  '🍱',
                  style: TextStyle(fontSize: 45),
                ),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _foodController,
          builder: (context, child) {
            return Positioned(
              bottom: 250,
              right: 70 + _food2Slide.value / 3,
              child: Opacity(
                opacity: ((200 - _food2Slide.value) / 250).clamp(0.0, 1.0),
                child: const Text(
                  '🥤',
                  style: TextStyle(fontSize: 50),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
