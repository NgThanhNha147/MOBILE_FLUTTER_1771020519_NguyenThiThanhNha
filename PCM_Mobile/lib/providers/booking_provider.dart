import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/booking_service.dart';
import '../core/services/signalr_service.dart';
import '../models/booking.dart';
import '../models/court.dart';
import '../models/time_slot.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

class BookingState {
  final List<Court> courts;
  final List<Booking> bookings;
  final List<Booking> myBookings;
  final bool isLoading;
  final String? error;

  BookingState({
    this.courts = const [],
    this.bookings = const [],
    this.myBookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingState copyWith({
    List<Court>? courts,
    List<Booking>? bookings,
    List<Booking>? myBookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingState(
      courts: courts ?? this.courts,
      bookings: bookings ?? this.bookings,
      myBookings: myBookings ?? this.myBookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final BookingService _bookingService;
  final SignalRService _signalRService = SignalRService();
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  BookingNotifier(this._bookingService) : super(BookingState()) {
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    // Listen to calendar updates from SignalR
    _signalRService.onCalendarUpdate.listen((_) {
      print('📅 Calendar update received via SignalR, reloading...');
      // Reload calendar with current date range
      if (_currentStartDate != null && _currentEndDate != null) {
        loadCalendar(startDate: _currentStartDate!, endDate: _currentEndDate!);
      }
    });
  }

  Future<void> loadCourts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final courts = await _bookingService.getCourts();
      state = state.copyWith(courts: courts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadCalendar({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Save current date range for SignalR refresh
    _currentStartDate = startDate;
    _currentEndDate = endDate;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final bookings = await _bookingService.getCalendar(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMyBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final myBookings = await _bookingService.getMyBookings();
      state = state.copyWith(myBookings: myBookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
    String? recurrenceRule,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.createBooking(
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
        recurrenceRule: recurrenceRule,
      );

      // Reload calendar with CURRENT date range (not just current month)
      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      } else {
        // Fallback to current month if no date range set
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        await loadCalendar(startDate: monthStart, endDate: monthEnd);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.cancelBooking(bookingId);

      // Reload both my bookings and calendar
      await loadMyBookings();

      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      } else {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        await loadCalendar(startDate: monthStart, endDate: monthEnd);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<CancelPreview> getCancelPreview(int bookingId) async {
    try {
      return await _bookingService.getCancelPreview(bookingId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TimeSlot>> getDailySlots(DateTime date, {int? courtId}) async {
    try {
      return await _bookingService.getDailySlots(date, courtId: courtId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> editBooking({
    required int bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.editBooking(
        bookingId: bookingId,
        newStartTime: newStartTime,
        newEndTime: newEndTime,
      );

      // Reload calendar
      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> rescheduleBooking({
    required int bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.rescheduleBooking(
        bookingId: bookingId,
        newStartTime: newStartTime,
        newEndTime: newEndTime,
      );

      // Reload calendar
      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<Map<String, dynamic>> holdBooking({
    required int courtId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final holdData = await _bookingService.holdBooking(
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
      );

      state = state.copyWith(isLoading: false);
      return holdData;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> confirmBooking(int bookingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.confirmBooking(bookingId);

      // Reload calendar
      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> cancelHoldBooking(int bookingId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _bookingService.cancelHoldBooking(bookingId);

      // Reload calendar
      if (_currentStartDate != null && _currentEndDate != null) {
        await loadCalendar(
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((
  ref,
) {
  return BookingNotifier(ref.watch(bookingServiceProvider));
});
