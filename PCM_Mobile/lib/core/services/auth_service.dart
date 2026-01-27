import 'package:dio/dio.dart';
import '../../models/user.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

class AuthService {
  final dio = DioClient().dio;
  final storage = DioClient().storage;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      print('📦 Login response: ${response.data}');
      final loginResponse = LoginResponse.fromJson(response.data);

      // Save token
      await DioClient().setAuthToken(loginResponse.token);

      // Get full user and member data
      final meResponse = await dio.get(ApiConstants.getMe);
      print('📦 Me response: ${meResponse.data}');
      
      return meResponse.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      print('💥 Error: $e');
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await dio.post(
        ApiConstants.register,
        data: {'email': email, 'password': password, 'fullName': fullName},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await dio.get(ApiConstants.getMe);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await DioClient().clearAuthToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await DioClient().getAuthToken();
    return token != null;
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      if (data is Map && data.containsKey('title')) {
        return data['title'];
      }
      return 'Lỗi: ${error.response!.statusMessage}';
    } else {
      return 'Không thể kết nối đến server';
    }
  }
}
