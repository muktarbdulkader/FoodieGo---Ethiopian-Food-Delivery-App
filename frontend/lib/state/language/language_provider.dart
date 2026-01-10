import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_localizations.dart';

/// Supported languages
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

/// Language Provider - Manages app language state
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
        code: 'en', name: 'English', nativeName: 'English', flag: '🇺🇸'),
    AppLanguage(
        code: 'om',
        name: 'Afaan Oromoo',
        nativeName: 'Afaan Oromoo',
        flag: '🇪🇹'),
    AppLanguage(code: 'am', name: 'Amharic', nativeName: 'አማርኛ', flag: '🇪🇹'),
  ];

  String _languageCode = 'en';
  bool _isInitialized = false;
  AppLocalizations? _localizations;

  String get languageCode => _languageCode;
  bool get isInitialized => _isInitialized;
  AppLocalizations get loc => _localizations ?? AppLocalizations('en');

  AppLanguage get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == _languageCode,
        orElse: () => supportedLanguages.first,
      );

  /// Initialize language from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);

    if (savedLanguage != null &&
        supportedLanguages.any((l) => l.code == savedLanguage)) {
      _languageCode = savedLanguage;
    }

    _localizations = AppLocalizations(_languageCode);
    _isInitialized = true;
    notifyListeners();
  }

  /// Check if language has been selected (for first-time users)
  Future<bool> hasSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_languageKey);
  }

  /// Set language and persist
  Future<void> setLanguage(String code) async {
    if (!supportedLanguages.any((l) => l.code == code)) return;

    _languageCode = code;
    _localizations = AppLocalizations(code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);

    notifyListeners();
  }

  /// Get localized string by key
  String translate(String key) => loc.get(key);
}
