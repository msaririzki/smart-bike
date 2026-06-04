import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'user_name';
  static const _emailKey = 'user_email';
  static const _weightKey = 'user_weight';

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> get userName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<String?> get userEmail async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> get userWeight async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weightKey);
  }

  Future<void> saveSession({
    required String token,
    required String name,
    required String email,
    String? weight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await _writeWeight(prefs, weight);
  }

  Future<void> updateUser({
    required String name,
    required String email,
    String? weight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await _writeWeight(prefs, weight);
  }

  Future<void> _writeWeight(SharedPreferences prefs, String? weight) async {
    if (weight != null) {
      await prefs.setString(_weightKey, weight);
    } else {
      await prefs.remove(_weightKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_weightKey);
  }
}
