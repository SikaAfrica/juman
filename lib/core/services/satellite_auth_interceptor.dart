import 'package:dio/dio.dart';
import 'auth_token_coordinator.dart';

class SatelliteAuthInterceptor extends Interceptor {
  static const List<String> publicPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/validate-sso',
    '/djuman/professionals',
    '/djuman/services',
    '/djuman/categories',
  ];
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = publicPaths.any((p) => options.path.startsWith(p));
    
    if (!isPublic) {
      var token = await AuthTokenCoordinator.readAccessToken();
      
      if (token != null &&
          token.isNotEmpty &&
          await AuthTokenCoordinator.isAccessTokenExpired()) {
        token = await AuthTokenCoordinator.refreshAccessToken();
      }
      
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    handler.next(options);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final newToken = await AuthTokenCoordinator.refreshAccessToken();
      
      if (newToken != null) {
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';
        
        try {
          final response = await Dio().fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          // Refresh failed, continue with error
        }
      }
    }
    
    handler.next(err);
  }
}
