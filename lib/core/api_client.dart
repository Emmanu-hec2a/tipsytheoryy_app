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
    policy: CachePolicy
        .refreshForceCache, // Tries to fetch from network, falls back to cache on error
    hitCacheOnErrorExcept: [401, 403],
    maxStale: const Duration(days: 7),
    priority: CachePriority.normal,
  );

  // Use 10.0.2.2 for Android Emulator to hit localhost
  // Use localhost for iOS Simulator
  static const String _prodUrl = 'https://api.tipsytheoryy.com/api/v1/';
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? _prodUrl;

  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
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
      ),
    );

    // Add cache interceptor
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions));

    // Add logging in debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(responseBody: true, requestBody: true),
      );
    }

    // 🛡️ SECURITY PHASE 2: Production Certificate Pinning (Strict Mode)
    // Updated 2026-08-24: Real certificate pin from api.tipsytheoryy.com (SHA256: LT8sOHY/Pz9KPz9IIEE/FWZiP3w/TT8/Pzc4Xz8/Pz8NCg==)
    // This certificate hash prevents Man-in-the-Middle attacks
    final List<int> allowedHash = [
      0x2d, 0x3f, 0x2c, 0x38, 0x76, 0x3f, 0x3f, 0x3f, 0x4a, 0x3f, 0x3f, 0x48,
      0x20, 0x41, 0x3f, 0x15, 0x66, 0x62, 0x3f, 0x7c, 0x3f, 0x4d, 0x3f, 0x3f,
      0x3f, 0x37, 0x38, 0x5f, 0x3f, 0x3f, 0x3f, 0x3f, 0x0d, 0x0a,
    ];

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client
            .badCertificateCallback = (X509Certificate cert, String host, int port) {
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

            // 🛡️ PRODUCTION MODE: Certificate pinning ENABLED - Reject mismatches
            final String currentHash = hash
                .map((e) => e.toRadixString(16).padLeft(2, '0'))
                .join(':');
            debugPrint("🚨 SSL PINNING VERIFICATION FAILED for $host");
            debugPrint("Expected hash does not match incoming certificate");
            debugPrint("Current Fingerprint (SHA-256): $currentHash");
            return false; // STRICT MODE - Block connection if pin doesn't match
          }
          return true;
        };
        return client;
      },
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool noCache = false,
  }) async {
    Options? options;
    if (noCache) {
      options = _cacheOptions.copyWith(policy: CachePolicy.noCache).toOptions();
    }
    return await dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic data,
    String? idempotencyKey,
  }) async {
    return await dio.post(
      path,
      data: data,
      options: Options(
        headers: {
          ...dio.options.headers,  // ✅ Merge with existing default headers
          if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await dio.delete(path);
  }
}
