import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _keyToken = 'device_token';
  static const _keyName = 'device_name';
  static const _keyEmail = 'device_email';

  Future<void> saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
  }

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<String?> get name async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  Future<String?> get email async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  Future<bool> get isLoggedIn async {
    final t = await token;
    return t != null && t.isNotEmpty;
  }
}
