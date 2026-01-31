import 'package:dio/dio.dart';
import '../../models/wallet_transaction.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

class WalletService {
  final dio = DioClient().dio;

  Future<void> requestDeposit({
    required double amount,
    required String proofImageUrl,
  }) async {
    try {
      await dio.post(
        ApiConstants.requestDeposit,
        data: {'amount': amount, 'proofImageUrl': proofImageUrl},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<WalletTransaction>> getMyTransactions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.getMyTransactions,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      // Backend returns { total, page, pageSize, data: [...] }
      final responseData = response.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final List<dynamic> data = responseData['data'];
        return data.map((json) => WalletTransaction.fromJson(json)).toList();
      }

      // Fallback if backend returns list directly
      final List<dynamic> data = response.data;
      return data.map((json) => WalletTransaction.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
      return 'Lỗi: ${error.response!.statusMessage}';
    } else {
      return 'Không thể kết nối đến server';
    }
  }
}
