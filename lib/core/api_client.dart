import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/io.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Global cache store to be shared across ApiClient instances
  static final _cacheStore = MemCacheStore();
  
  void clearCache() {
    _cacheStore.clean();
  }
  static final _cacheOptions = CacheOptions(
    store: _cacheStore,
    policy: CachePolicy.refreshForceCache, // Tries to fetch from network, falls back to cache on error
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
    priority: CachePriority.normal,
  );

  // Use 10.0.2.2 for Android Emulator to hit localhost
  // Use localhost for iOS Simulator
  static const String _prodUrl = 'https://api.tipsytheoryy.com/api/v1/';
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? _prodUrl;

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

    // 🛡️ SECURITY PHASE 1: Incremental Pinning (Logging Mode)
    // We re-enable the verification logic but keep it in "Warning" mode to ensure stability.
    final List<int> allowedHash = [
      0x1c, 0x9f, 0x53, 0xc8, 0xb2, 0x86, 0x2d, 0xb2, 0x3d, 0x65, 0x3a, 0xb6, 0xa8, 0x84, 0x41, 0x21,
      0x93, 0xef, 0x96, 0x67, 0x20, 0x8d, 0xaa, 0x1a, 0x20, 0x00, 0xee, 0x13, 0x75, 0x16, 0x8a, 0xcb
    ];

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          if (host.contains('tipsytheoryy.com')) {
            final hash = sha256.convert(cert.der).bytes;
            bool match = true;
            for (int i = 0; i < allowedHash.length; i++) {
              if (hash[i] != allowedHash[i]) {
                match = false;
                break;
              }
            }
            if (match) {
              debugPrint("🛡️ SSL PINNING: MATCH for $host");
              return true;
            }
            
            // 🛡️ PRODUCTION LOCK: Strictly reject any fingerprint mismatch
            debugPrint("🚨 SSL PINNING FAILURE: Potential MitM Attack for $host");
            return false;
          }
          return true;
        };
        return client;
      },
    );
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
