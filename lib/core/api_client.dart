import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Global cache store to be shared across ApiClient instances
  static final _cacheStore = MemCacheStore();
  static final _cacheOptions = CacheOptions(
    store: _cacheStore,
    policy: CachePolicy.refreshForceCache, // Tries to fetch from network, falls back to cache on error
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
    priority: CachePriority.normal,
  );

  // Use 10.0.2.2 for Android Emulator to hit localhost
  // Use localhost for iOS Simulator
  // static const String baseUrl = 'https://tipsytheoryy.com/api/v1/';
  // If 10.0.2.2 fails, try the actual machine IP or ensure Django is running on 0.0.0.0
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1/';

  ApiClient() : dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Handle token refresh logic here if needed
        }
        return handler.next(e);
      },
    ));

    // Add cache interceptor
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));

    // Add logging in debug mode
    dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
