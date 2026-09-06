import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/providers/auth_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage: storage, ref: ref);
});

class ApiClient {
  late final Dio _dio;
  final SecureStorageService storage;
  final ProviderRef ref;

  ApiClient({
    required this.storage,
    required this.ref,
    String baseUrl = 'https://api.example.com',
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    _dio.interceptors.addAll([
      _NetworkStatusInterceptor(),
      _AuthInterceptor(storage, _dio, ref),
      _LoggingInterceptor(),
      _ErrorInterceptor(),
    ]);
  }

  Dio get dio => _dio;
}

class _NetworkStatusInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: Implement network connectivity check here
    super.onRequest(options, handler);
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorageService storage;
  final Dio dio;
  final ProviderRef ref;

  bool _isRefreshing = false;
  final List<Map<String, dynamic>> _failedRequests = [];

  _AuthInterceptor(this.storage, this.dio, this.ref);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // Don't add token for auth endpoints
    if (options.path.contains('/auth/')) {
      return handler.next(options);
    }

    final token = await storage.getToken('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains('/auth/')) {
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          final refreshToken = await storage.getToken('refresh_token');
          if (refreshToken == null) {
            _logout();
            return handler.next(err);
          }

          // Create a new Dio instance for the refresh request to avoid interceptor loops
          final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
          final response = await refreshDio.post('/api/auth/refresh', data: {
            'refreshToken': refreshToken,
          });

          final newAccessToken = response.data['accessToken'];
          final newRefreshToken = response.data['refreshToken'];

          await storage.saveToken('access_token', newAccessToken);
          await storage.saveToken('refresh_token', newRefreshToken);

          // Retry the original request
          err.requestOptions.headers['Authorization'] =
              'Bearer $newAccessToken';

          _isRefreshing = false;

          // Process queued failed requests
          for (var request in _failedRequests) {
            request['options'].headers['Authorization'] =
                'Bearer $newAccessToken';
            dio.fetch(request['options']).then(
                  (res) => request['handler'].resolve(res),
                  onError: (e) => request['handler'].reject(e),
                );
          }
          _failedRequests.clear();

          final retryResponse = await dio.fetch(err.requestOptions);
          return handler.resolve(retryResponse);
        } catch (e) {
          _isRefreshing = false;
          _failedRequests.clear();
          _logout();
          return handler.next(err);
        }
      } else {
        // Queue this request
        _failedRequests
            .add({'options': err.requestOptions, 'handler': handler});
        return; // Don't call handler yet
      }
    }

    super.onError(err, handler);
  }

  void _logout() {
    ref.read(authProvider.notifier).sessionExpired();
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('--> ${options.method} ${options.uri}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint('<-- Error ${err.message}');
    }
    super.onError(err, handler);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      debugPrint('Timeout error occurred');
    } else if (err.type == DioExceptionType.connectionError) {
      debugPrint('Network connection error');
    }
    super.onError(err, handler);
  }
}
