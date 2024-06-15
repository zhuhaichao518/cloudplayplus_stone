import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  // Setters
  static Future<void> setBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  static Future<void> setInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  static Future<void> setDouble(String key, double value) async {
    await _preferences?.setDouble(key, value);
  }

  static Future<void> setString(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _preferences?.setStringList(key, value);
  }

  // Getters
  static bool? getBool(String key) {
    return _preferences?.getBool(key);
  }

  static int? getInt(String key) {
    return _preferences?.getInt(key);
  }

  static double? getDouble(String key) {
    return _preferences?.getDouble(key);
  }

  static String? getString(String key) {
    return _preferences?.getString(key);
  }

  static List<String>? getStringList(String key) {
    return _preferences?.getStringList(key);
  }
}
