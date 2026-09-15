import 'package:shared_preferences/shared_preferences.dart';

/// ⚠️ Change this once. Every user logs in with their personnel number + this password.
const String kCommonPassword = 'friends@info';

class AuthService {
  static const _kUserKey = 'auth_user';
  static const _kDarkKey = 'dark_mode';

  static Future<String?> currentUser() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kUserKey);
  }

  static Future<bool> login(String personnelNo, String password) async {
    if (personnelNo.trim().isEmpty) return false;
    if (password != kCommonPassword) return false;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kUserKey, personnelNo.trim().toUpperCase());
    return true;
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUserKey);
  }

  static Future<bool> isDarkMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kDarkKey) ?? false;
  }

  static Future<void> setDarkMode(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDarkKey, value);
  }
}
