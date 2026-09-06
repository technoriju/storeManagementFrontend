import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/auth_state.dart';
import '../models/user_model.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/network/api_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(secureStorageProvider),
    ref.read(apiClientProvider).dio, // We will create this provider soon
  );
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _storage;
  final Dio _dio;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  AuthNotifier(this._storage, this._dio) : super(AuthState.initial()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final token = await _storage.getToken(_accessTokenKey);
      final userStr = await _storage.getToken(_userKey);

      if (token != null && userStr != null) {
        final userMap = jsonDecode(userStr);
        final user = UserModel.fromJson(userMap);
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String username, String password,
      {String? deviceId}) async {
    state = AuthState.loading();
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'username': username,
        'password': password,
        'deviceId': deviceId ?? 'unknown',
      });

      final accessToken = response.data['accessToken'];
      final refreshToken = response.data['refreshToken'];
      final user = UserModel.fromJson(response.data['user']);

      await _storage.saveToken(_accessTokenKey, accessToken);
      await _storage.saveToken(_refreshTokenKey, refreshToken);
      await _storage.saveToken(_userKey, jsonEncode(user.toJson()));

      state = AuthState.authenticated(user);
    } on DioException catch (e) {
      String errorMessage = 'Login failed';
      if (e.response?.statusCode == 401) {
        errorMessage = 'Invalid username or password';
      } else if (e.response?.data != null &&
          e.response?.data['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      state = AuthState.error(errorMessage);
      // Give the UI a moment to show the error, then reset to unauthenticated
      await Future.delayed(const Duration(seconds: 2));
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
      await Future.delayed(const Duration(seconds: 2));
      state = AuthState.unauthenticated();
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getToken(_refreshTokenKey);
      if (refreshToken != null) {
        // Attempt to logout on the server
        await _dio
            .post('/api/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (e) {
      // Ignore errors during logout, we will clear local storage anyway
    } finally {
      await _storage.deleteAll();
      state = AuthState.unauthenticated();
    }
  }

  void sessionExpired() {
    _storage.deleteAll();
    state = AuthState.unauthenticated();
  }
}
