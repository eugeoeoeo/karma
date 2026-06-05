import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Production API URL - fallback if .env is not loaded
const String _kProductionApiUrl = 'https://karma-backend-imlc.onrender.com/api';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    // Try to read from .env, fall back to hardcoded production URL
    final baseUrl = dotenv.env['API_URL']?.isNotEmpty == true
        ? dotenv.env['API_URL']!
        : _kProductionApiUrl;

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      // Extended timeouts to handle Render free-tier cold starts (up to 90s)
      connectTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 90),
      sendTimeout: const Duration(seconds: 90),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor - auto-inject JWT and handle token refresh
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefresh();
          if (refreshed) {
            final token = await _storage.read(key: 'access_token');
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) return false;

      final baseUrl = dotenv.env['API_URL']?.isNotEmpty == true
          ? dotenv.env['API_URL']!
          : _kProductionApiUrl;

      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
      )).post(
        '$baseUrl/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await _storage.write(key: 'access_token', value: response.data['data']['accessToken']);
        await _storage.write(key: 'refresh_token', value: response.data['data']['refreshToken']);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) =>
      dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) =>
      dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      dio.patch(path, data: data);

  Future<Response> delete(String path) =>
      dio.delete(path);
}
