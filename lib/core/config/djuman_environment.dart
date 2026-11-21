import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Environment { development, staging, production }

class DjumanEnvironment {
  static Environment _currentEnvironment = Environment.development;
  static String _apiBaseUrlOverride = '';
  
  static const String _devApiUrl = 'http://127.0.0.1:8000';
  static const String _stagingApiUrl = 'https://staging-api.sika.app';
  static const String _prodApiUrl = 'https://api.sika.app';
  
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final envString = prefs.getString('environment') ?? 'development';
    _currentEnvironment = Environment.values.firstWhere(
      (e) => e.name == envString,
      orElse: () => Environment.development,
    );
    _apiBaseUrlOverride = prefs.getString('api_base_url') ?? '';
  }
  
  static Environment get currentEnvironment => _currentEnvironment;
  
  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    
    switch (_currentEnvironment) {
      case Environment.development:
        if (kIsWeb) return _devApiUrl;
        return _devApiUrl;
      case Environment.staging:
        return _stagingApiUrl;
      case Environment.production:
        return _prodApiUrl;
    }
  }
  
  static Future<void> setEnvironment(Environment env) async {
    final prefs = await SharedPreferences.getInstance();
    _currentEnvironment = env;
    await prefs.setString('environment', env.name);
  }
  
  static Future<void> setApiBaseUrlOverride(String url) async {
    final prefs = await SharedPreferences.getInstance();
    _apiBaseUrlOverride = url;
    await prefs.setString('api_base_url', url);
  }
  
  static bool get isDevelopment => _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;
  static bool get isProduction => _currentEnvironment == Environment.production;
}
