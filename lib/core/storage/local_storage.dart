import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _dashboardKey = 'dashboard_cache';
  static const _recommendationsKey = 'recommendations_cache';

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, access);
    await prefs.setString(_refreshKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove('username');
    await prefs.remove('email');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveUserInfo(String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('email', email);
  }

  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? '',
      'email':    prefs.getString('email')    ?? '',
    };
  }

  static Future<void> cacheDashboard(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dashboardKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getCachedDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dashboardKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> cacheRecommendations(List<dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recommendationsKey, jsonEncode(data));
  }

  static Future<List<dynamic>?> getCachedRecommendations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recommendationsKey);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }
}

