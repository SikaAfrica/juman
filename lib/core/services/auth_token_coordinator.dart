import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenCoordinator {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _tokenExpiryKey = 'token_expiry';
  
  static const _tokenLifetime = 86400;
  
  static Future<void> persistTokens({
    required String accessToken,
    required String? refreshToken,
  }) async {
    final expiry = DateTime.now().add(const Duration(seconds: _tokenLifetime));
    
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    await _storage.write(
      key: _tokenExpiryKey,
      value: expiry.toIso8601String(),
    );
  }
  
  static Future<String?> readAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  static Future<String?> readRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  static Future<bool> isAccessTokenExpired() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return true;
    
    final expiry = DateTime.parse(expiryStr);
    return DateTime.now().isAfter(expiry);
  }
  
  static Future<String?> refreshAccessToken() async {
    final refreshToken = await readRefreshToken();
    if (refreshToken == null) return null;
    return null;
  }
  
  static Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  static Future<bool> isAuthenticated() async {
    final token = await readAccessToken();
    if (token == null) return false;
    
    final isExpired = await isAccessTokenExpired();
    return !isExpired;
  }
}
