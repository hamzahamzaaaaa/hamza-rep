import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

// Web-compatible database service using SharedPreferences
// For web, we use localStorage instead of SQLite
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static SharedPreferences? _prefs;
  static const String _prefix = 'duration_';

  DatabaseService._init();

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveDuration(String id, int seconds) async {
    if (kIsWeb) {
      // Web: Use SharedPreferences (localStorage)
      await _initPrefs();
      await _prefs!.setInt('$_prefix$id', seconds);
    } else {
      // Mobile/Desktop: Would use SQLite if needed
      // For now, also use SharedPreferences for consistency
      await _initPrefs();
      await _prefs!.setInt('$_prefix$id', seconds);
    }
  }

  Future<int?> getDuration(String id) async {
    await _initPrefs();
    return _prefs!.getInt('$_prefix$id');
  }

  Future<void> close() async {
    // Nothing to close for SharedPreferences
  }
}
