import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Supported languages for audio notifications
enum NotificationLanguage {
  english,
  amharic,
  oromo,
}

/// Extension to get language codes
extension NotificationLanguageExtension on NotificationLanguage {
  String get code {
    switch (this) {
      case NotificationLanguage.english:
        return 'en';
      case NotificationLanguage.amharic:
        return 'am';
      case NotificationLanguage.oromo:
        return 'om';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationLanguage.english:
        return 'English';
      case NotificationLanguage.amharic:
        return 'Amharic';
      case NotificationLanguage.oromo:
        return 'Oromo';
    }
  }
}

/// Cross-platform audio service for playing notification sounds
/// Supports English, Amharic, and Oromo languages
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;

  /// Audio file paths for different languages and events
  /// Using WAV format for maximum compatibility across Android and Web
  static const Map<String, String> _audioAssets = {
    // English notifications
    'waiter_call_en': 'sounds/waiter_call_en.wav',
    'new_order_en': 'sounds/new_order_en.wav',
    'order_ready_en': 'sounds/order_ready_en.wav',
    // Amharic notifications
    'waiter_call_am': 'sounds/waiter_call_am.wav',
    'new_order_am': 'sounds/new_order_am.wav',
    'order_ready_am': 'sounds/order_ready_am.wav',
    // Oromo notifications
    'waiter_call_om': 'sounds/waiter_call_om.wav',
    'new_order_om': 'sounds/new_order_om.wav',
    'order_ready_om': 'sounds/order_ready_om.wav',
    // Generic sounds (fallback)
    'notification': 'sounds/notification.wav',
    'bell': 'sounds/bell.wav',
  };

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set audio player release mode
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      _isInitialized = true;
      debugPrint('[AudioService] Initialized successfully');
    } catch (e) {
      debugPrint('[AudioService] Initialization error: $e');
    }
  }

  /// Play waiter call sound in specified language
  ///
  /// [language] - The language for the notification (English, Amharic, Oromo)
  /// [tableNumber] - Optional table number to include in announcement
  Future<void> playWaiterCall(NotificationLanguage language,
      {String? tableNumber}) async {
    final assetPath =
        _audioAssets['waiter_call_${language.code}'] ?? _audioAssets['bell']!;

    await _playAsset(assetPath);

    // Log the call details
    debugPrint('[AudioService] Waiter call played in ${language.displayName}' +
        (tableNumber != null ? ' for Table $tableNumber' : ''));
  }

  /// Play new order notification in specified language
  ///
  /// [language] - The language for the notification
  /// [orderNumber] - Optional order number to announce
  Future<void> playNewOrderNotification(NotificationLanguage language,
      {String? orderNumber}) async {
    final assetPath = _audioAssets['new_order_${language.code}'] ??
        _audioAssets['notification']!;

    await _playAsset(assetPath);

    debugPrint(
        '[AudioService] New order notification played in ${language.displayName}' +
            (orderNumber != null ? ' for Order #$orderNumber' : ''));
  }

  /// Play order ready notification in specified language
  ///
  /// [language] - The language for the notification
  Future<void> playOrderReadyNotification(NotificationLanguage language) async {
    final assetPath = _audioAssets['order_ready_${language.code}'] ??
        _audioAssets['notification']!;

    await _playAsset(assetPath);

    debugPrint(
        '[AudioService] Order ready notification played in ${language.displayName}');
  }

  /// Play a generic notification sound
  Future<void> playNotification() async {
    await _playAsset(_audioAssets['notification']!);
  }

  /// Play a bell sound
  Future<void> playBell() async {
    await _playAsset(_audioAssets['bell']!);
  }

  /// Play sound from asset path
  Future<void> _playAsset(String assetPath) async {
    try {
      if (kIsWeb) {
        await _playWebAudio(assetPath);
      } else {
        // Mobile/Desktop - use audioplayers
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (e) {
      debugPrint('[AudioService] Error playing audio: $e');
      // Fallback to system beep or vibration
      _fallbackNotification();
    }
  }

  /// Play audio on web platform
  /// Uses HTML5 Audio API through JavaScript interop
  Future<void> _playWebAudio(String assetPath) async {
    // For web, we'll use the audioplayers package which handles web internally
    // This is a simpler approach that works cross-platform
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('[AudioService] Web audio error: $e');
    }
  }

  /// Fallback notification when audio fails
  void _fallbackNotification() {
    // Could trigger vibration or visual notification here
    debugPrint('[AudioService] Using fallback notification');
  }

  /// Play a test sound to verify audio is working
  Future<void> playTestSound(NotificationLanguage language) async {
    await playWaiterCall(language, tableNumber: '1');
  }

  /// Get available audio assets for a language
  List<String> getAvailableSounds(NotificationLanguage language) {
    final code = language.code;
    return [
      'waiter_call_$code',
      'new_order_$code',
      'order_ready_$code',
    ];
  }

  /// Dispose audio resources
  void dispose() {
    _audioPlayer.dispose();
    _isInitialized = false;
  }
}

/// Utility class for creating audio messages
class AudioMessageBuilder {
  /// Build a waiter call message in the specified language
  static String buildWaiterCallMessage(
      NotificationLanguage language, String tableNumber) {
    switch (language) {
      case NotificationLanguage.amharic:
        return 'ጠረጴዛ $tableNumber ጠበቃ ይፈልጋል'; // Table X needs a waiter
      case NotificationLanguage.oromo:
        return 'Meshaa $tableNumber taphaataa barbaada'; // Table X needs a waiter
      case NotificationLanguage.english:
        return 'Table $tableNumber is calling for a waiter';
    }
  }

  /// Build a new order message in the specified language
  static String buildNewOrderMessage(
      NotificationLanguage language, String orderNumber) {
    switch (language) {
      case NotificationLanguage.amharic:
        return 'አዲስ ትዕዛዝ $orderNumber ደርሷል'; // New order X has arrived
      case NotificationLanguage.oromo:
        return 'Ajaja haaraa $orderNumber galmeera'; // New order X has arrived
      case NotificationLanguage.english:
        return 'New order $orderNumber received';
    }
  }

  /// Build an order ready message in the specified language
  static String buildOrderReadyMessage(
      NotificationLanguage language, String orderNumber) {
    switch (language) {
      case NotificationLanguage.amharic:
        return 'ትዕዛዝ $orderNumber ዝግጁ ነው'; // Order X is ready
      case NotificationLanguage.oromo:
        return 'Ajaja $orderNumber qophaa\'ee jira'; // Order X is ready
      case NotificationLanguage.english:
        return 'Order $orderNumber is ready';
    }
  }
}
