import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PersistentCache {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<Map<String, dynamic>?> getMap(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getMapList(String key) async {
    final prefs = await _prefs;
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> setMap(String key, Map<String, dynamic> value) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<void> setMapList(String key, List<Map<String, dynamic>> value) async {
    final prefs = await _prefs;
    await prefs.setString(key, jsonEncode(value));
  }

  static Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }
}

