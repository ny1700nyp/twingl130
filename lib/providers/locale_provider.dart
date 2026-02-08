import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kAppLocaleKey = 'app_locale';

/// Provides the app locale with persistence via [SharedPreferences].
/// When [locale] is null, the app uses the system default.
class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  /// Load saved language code from [SharedPreferences] (call on app start).
  Future<void> fetchLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kAppLocaleKey);
    _locale = code != null && code.isNotEmpty ? Locale(code) : null;
    notifyListeners();
  }

  /// Set the app locale and persist the language code.
  Future<void> setLocale(Locale locale) async {
    if (_locale?.languageCode == locale.languageCode) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAppLocaleKey, locale.languageCode);
    notifyListeners();
  }

  /// Clear saved locale (revert to system default).
  Future<void> clearLocale() async {
    if (_locale == null) return;
    _locale = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAppLocaleKey);
    notifyListeners();
  }
}
