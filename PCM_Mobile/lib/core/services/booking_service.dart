import 'package:dio/dio.dart';
import '../../models/booking.dart';
import '../../models/court.dart';
import '../../models/time_slot.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

class BookingService {
  final dio = DioClient().dio;

  Future<List<Court>> getCourts() async {
    try {
      final response = await dio.get(ApiConstants.getCourts);
      final List<dynamic> data = response.data;
      return data.map((json) => Court.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Booking>> getCalendar({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.getCalendar,
        queryParameters: {
          'from': startDate.toIso8601String(),
          'to': endDate.toIso8601String(),
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => Booking.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
    String? recurrenceRule,
    int retryCount = 0,
  }) async {
    try {
      await dio.post(
        ApiConstants.createBooking,
        data: {
          'courtId': courtId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'recurrenceRule': recurrenceRule,
        },
      );
    } on DioException catch (e) {
      // Retry logic for server errors only
      if ((e.response?.statusCode == 500 || e.response?.statusCode == 503) && retryCount < 2) {
        await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
        return createBooking(
          courtId: courtId,
          startTime: startTime,
          endTime: endTime,
          recurrenceRule: recurrenceRule,
          retryCount: retryCount + 1,
        );
      }
      throw _handleError(e);
    }
  }

  Future<List<Booking>> getMyBookings() async {
    try {
      final response = await dio.get(ApiConstants.getMyBookings);
      final List<dynamic> data = response.data;
      return data.map((json) => Booking.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    try {
      await dio.post('${ApiConstants.cancelBooking}/cancel/$bookingId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<CancelPreview> getCancelPreview(int bookingId) async {
    try {
      final response = await dio.get('${ApiConstants.baseUrl}/api/bookings/cancel-preview/$bookingId');
      return CancelPreview.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TimeSlot>> getDailySlots(DateTime date, {int? courtId}) async {
    try {
      final response = await dio.get(
        '${ApiConstants.baseUrl}/api/bookings/slots',
        queryParameters: {
          'date': date.toIso8601String(),
          if (courtId != null) 'courtId': courtId,
        },
      );
      
      final List<dynamic> data = response.data;
      return data.map((json) => TimeSlot.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> editBooking({
    required int bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    try {
      await dio.put(
        '${ApiConstants.baseUrl}/api/bookings/edit/$bookingId',
        data: {
          'newStartTime': newStartTime.toIso8601String(),
          'newEndTime': newEndTime.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> rescheduleBooking({
    required int bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    try {
      await dio.post(
        '${ApiConstants.baseUrl}/api/bookings/reschedule/$bookingId',
        data: {
          'newStartTime': newStartTime.toIso8601String(),
          'newEndTime': newEndTime.toIso8601String(),
        },
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> holdBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/bookings/hold',
        data: {
          'courtId': courtId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
      );
      
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> confirmBooking(int bookingId) async {
    try {
      await dio.post('${ApiConstants.baseUrl}/bookings/confirm/$bookingId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> cancelHoldBooking(int bookingId) async {
    try {
      await dio.post('${ApiConstants.baseUrl}/bookings/cancel/$bookingId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> createRecurringBooking({
    required int courtId,
    required DateTime startDate,
    required DateTime endDate,
    required String startTime, // "09:00"
    required String endTime,   // "10:00"
    required String recurrencePattern, // "Weekly;Mon,Wed,Fri"
    required int occurrencesCount,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.baseUrl}/bookings/recurring',
        data: {
          'courtId': courtId,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'startTime': startTime,
          'endTime': endTime,
          'recurrencePattern': recurrencePattern,
          'occurrencesCount': occurrencesCount,
        },
      );
      
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      
      // Parse standardized ApiResponse
      if (data is Map) {
        final errorCode = data['errorCode'] as String?;
        final message = data['message'] as String?;
        
        // Translate error codes to Vietnamese
        switch (errorCode) {
          case 'INSUFFICIENT_BALANCE':
            return 'Ví không đủ tiền. Vui lòng nạp thêm!';
          case 'TIME_SLOT_CONFLICT':
            return 'Khung giờ này đã có người đặt. Vui lòng chọn giờ khác!';
          case 'INVALID_START_TIME':
            return 'Không thể đặt sân trong quá khứ!';
          case 'BOOKING_TOO_LONG':
            return 'Không thể đặt quá 5 giờ liên tục!';
          case 'BOOKING_TOO_SHORT':
            return 'Phải đặt tối thiểu 1 giờ!';
          case 'COURT_INACTIVE':
            return 'Sân đang bảo trì. Vui lòng chọn sân khác!';
          case 'COURT_NOT_FOUND':
            return 'Không tìm thấy sân!';
          case 'NOT_MEMBER':
            return 'Chỉ thành viên mới có thể đặt sân!';
          case 'CANCEL_TOO_LATE':
            return 'Không thể hủy trong vòng 6 giờ trước giờ chơi!';
          case 'ALREADY_CANCELLED':
            return 'Booking đã được hủy trước đó!';
          case 'EDIT_TIME_EXPIRED':
            return 'Chỉ có thể sửa trong vòng 5 phút sau khi đặt!';
          case 'RESCHEDULE_TOO_LATE':
            return 'Chỉ có thể đổi lịch trước 24h!';
          case 'BOOKING_NOT_FOUND':
            return 'Không tìm thấy booking!';
          case 'HOLD_EXPIRED':
            return 'Hết thời gian giữ chỗ (5 phút). Vui lòng đặt lại!';
          case 'INVALID_STATUS':
            return 'Trạng thái booking không hợp lệ!';
          case 'HOLD_FAILED':
            return 'Không thể giữ chỗ. Vui lòng thử lại!';
          case 'CONFIRM_FAILED':
            return 'Không thể xác nhận. Vui lòng thử lại!';
          case 'VIP_REQUIRED':
            return 'Chỉ thành viên VIP (Gold/Diamond) mới được đặt lịch định kỳ!';
          case 'INVALID_PATTERN':
            return 'Định dạng lặp lịch không hợp lệ!';
          case 'NO_SLOTS_GENERATED':
            return 'Không tạo được slot nào với quy tắc này!';
          case 'RECURRING_FAILED':
            return 'Không thể tạo lịch định kỳ. Vui lòng thử lại!';
          default:
            return message ?? 'Có lỗi xảy ra';
        }
      }
      
      return 'Lỗi: ${error.response!.statusMessage}';
    } else if (error.type == DioExceptionType.connectionTimeout || 
               error.type == DioExceptionType.receiveTimeout) {
      return 'Kết nối timeout. Vui lòng kiểm tra mạng!';
    } else {
      return 'Không thể kết nối đến server. Kiểm tra mạng!';
    }
  }
}
