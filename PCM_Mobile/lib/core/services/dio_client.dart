import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  late final Dio dio;
  final storage = const FlutterSecureStorage();

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          seconds: 10,
        ), // Quick actions: login, logout
        receiveTimeout: const Duration(seconds: 15), // Data fetch
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptor for auth token
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 Unauthorized - FIXED: Prevent multiple 401 handling
          if (error.response?.statusCode == 401) {
            final isAlreadyHandling = await storage.read(key: '401_handling');
            if (isAlreadyHandling == null) {
              await storage.write(key: '401_handling', value: 'true');
              await storage.delete(key: 'auth_token');
              // Clear flag after 1 second to allow next 401
              Future.delayed(const Duration(seconds: 1), () {
                storage.delete(key: '401_handling');
              });
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<void> setAuthToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearAuthToken() async {
    await storage.delete(key: 'auth_token');
  }

  Future<String?> getAuthToken() async {
    return await storage.read(key: 'auth_token');
  }
}
