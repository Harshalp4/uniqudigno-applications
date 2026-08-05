import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../security/cert_pinning.dart';
import '../storage/secure_storage.dart';

/// Configured Dio client (Section 2 / Section 4D).
/// - X-App-Source + X-Correlation-ID on every request
/// - Bearer token from secure storage
/// - certificate pinning (leaf SHA-256, configurable fingerprints)
/// - transparent 401 → refresh-token rotation → retry
class DioClient {
  DioClient({String? baseUrl, SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? defaultBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));
    _applyPinning(_dio);
    _dio.interceptors.add(_authInterceptor());

    // Separate client for token refresh so retries don't re-enter the interceptor.
    _refreshDio = Dio(BaseOptions(baseUrl: _dio.options.baseUrl));
    _applyPinning(_refreshDio);
  }

  static const String defaultBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:5000/api/v1');

  static String get deviceInfo => '${Platform.operatingSystem}-bit2sky-partner';

  late final Dio _dio;
  late final Dio _refreshDio;
  final SecureStorageService _storage;
  int _correlation = 0;

  Dio get raw => _dio;

  void _applyPinning(Dio dio) {
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback =
            (cert, host, port) => CertPinning.isTrusted(cert);
        return client;
      };
    }
  }

  Interceptor _authInterceptor() => QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          options.headers['X-App-Source'] =
              'partner';
          options.headers['X-Correlation-ID'] =
              '${DateTime.now().microsecondsSinceEpoch}-${_correlation++}';
          final token = await _storage.accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra['retried'] != true) {
            final refreshed = await _refresh();
            if (refreshed) {
              final req = e.requestOptions..extra['retried'] = true;
              final token = await _storage.accessToken;
              req.headers['Authorization'] = 'Bearer $token';
              try {
                final res = await _dio.fetch(req);
                return handler.resolve(res);
              } catch (err) {
                return handler.next(err as DioException);
              }
            }
          }
          handler.next(e);
        },
      );

  Future<bool> _refresh() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null) return false;
    try {
      final res = await _refreshDio.post('/auth/token/refresh', data: {
        'refreshToken': refreshToken,
        'deviceInfo': deviceInfo,
      });
      final data = res.data is Map && res.data.containsKey('data')
          ? res.data['data']
          : res.data;
      final access = (data['accessToken'] ?? data['access_token']).toString();
      final newRefresh =
          (data['refreshToken'] ?? data['refresh_token']).toString();
      await _storage.saveTokens(access, newRefresh);
      return true;
    } catch (_) {
      await _storage.clear(); // refresh-token reuse/expiry ⇒ force re-auth
      return false;
    }
  }

  /// Unwraps the standard API envelope `{ success, data, ... }` to `data`.
  Future<T> getData<T>(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get(path, queryParameters: query);
    return _unwrap<T>(res.data);
  }

  Future<T> postData<T>(String path, {Object? body}) async {
    final res = await _dio.post(path, data: body);
    return _unwrap<T>(res.data);
  }

  T _unwrap<T>(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'] as T;
    return body as T;
  }

  /// Extracts the API envelope error message (or a fallback) from a DioException.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    }
    return 'Something went wrong. Please try again.';
  }
}
