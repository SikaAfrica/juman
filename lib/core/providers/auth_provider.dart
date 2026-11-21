import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_token_coordinator.dart';
import '../services/api_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? phone;
  final String? error;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.email,
    this.displayName,
    this.phone,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? displayName,
    String? phone,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      error: error ?? this.error,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final theAuth = await AuthTokenCoordinator.isAuthenticated();
    if (theAuth) {
      await _loadUserInfo();
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final token = await AuthTokenCoordinator.readAccessToken();
      if (token == null || token.isEmpty) return;

      final apiService = ApiService.instance;
      final response = await apiService.get('/auth/me');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        state = state.copyWith(
          displayName: data['display_name']?.toString(),
          email: data['email']?.toString(),
          phone: data['phone']?.toString(),
          userId: data['user_id']?.toString(),
          status: AuthStatus.authenticated,
        );
      }
    } catch (e) {
      // Ignore error during initial load
    }
  }

  Future<void> login(String emailOrPhoneOrUsername, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final apiService = ApiService.instance;
      final response = await apiService.post('/auth/login', data: {
        'email_or_phone_or_username': emailOrPhoneOrUsername,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access_token']?.toString();
        final refreshToken = response.data['refresh_token']?.toString();
        final userId = response.data['user_id']?.toString();
        final userEmail = response.data['email']?.toString();
        final userDisplayName = response.data['display_name']?.toString();
        final userPhone = response.data['phone']?.toString();

        await AuthTokenCoordinator.persistTokens(
          accessToken: accessToken ?? '',
          refreshToken: refreshToken,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: userEmail,
          displayName: userDisplayName,
          phone: userPhone,
        );
        
        await _loadUserInfo();
      } else {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Identifiants incorrects',
        );
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Erreur de connexion: ${e.toString()}',
      );
    }
  }

  Future<void> logout() async {
    await AuthTokenCoordinator.clearSession();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> validateSSO(String ssoToken) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final apiService = ApiService.instance;
      final response = await apiService.post('/auth/validate-sso', data: {
        'sso_token': ssoToken,
      });

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access_token']?.toString();
        final refreshToken = response.data['refresh_token']?.toString();
        final userId = response.data['user_id']?.toString();

        await AuthTokenCoordinator.persistTokens(
          accessToken: accessToken ?? '',
          refreshToken: refreshToken,
        );

        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
        );

        await _loadUserInfo();
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Erreur SSO: ${e.toString()}',
      );
    }
  }
}

final authProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});
