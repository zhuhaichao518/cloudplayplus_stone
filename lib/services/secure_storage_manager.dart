import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageManager {
  static FlutterSecureStorage? _storage;

  static void init() {
    _storage ??= const FlutterSecureStorage();
  }

  // Setters
  static Future<void> setBool(String key, bool value) async {
    await _storage?.write(key: key, value: value.toString());
  }

  static Future<void> setInt(String key, int value) async {
    await _storage?.write(key: key, value: value.toString());
  }

  static Future<void> setDouble(String key, double value) async {
    await _storage?.write(key: key, value: value.toString());
  }

  static Future<void> setString(String key, String value) async {
    await _storage?.write(key: key, value: value);
  }

  static Future<void> setStringList(String key, List<String> value) async {
    await _storage?.write(key: key, value: value.join(','));
  }

  // Getters
  static Future<bool?> getBool(String key) async {
    String? value = await _storage?.read(key: key);
    return value != null ? value.toLowerCase() == 'true' : null;
  }

  static Future<int?> getInt(String key) async {
    String? value = await _storage?.read(key: key);
    return value != null ? int.tryParse(value) : null;
  }

  static Future<double?> getDouble(String key) async {
    String? value = await _storage?.read(key: key);
    return value != null ? double.tryParse(value) : null;
  }

  static Future<String?> getString(String key) async {
    return await _storage?.read(key: key);
  }
}
