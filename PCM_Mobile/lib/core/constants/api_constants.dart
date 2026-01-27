import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // Base URL - Auto-detect platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5283';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5283';
    } else {
      // iOS, macOS, Windows, Linux
      return 'http://localhost:5283';
    }
  }

  // Auth endpoints
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String getMe = '/api/auth/me';

  // Wallet endpoints
  static const String requestDeposit = '/api/wallet/deposit';
  static const String getMyTransactions = '/api/wallet/transactions';
  static const String approveDeposit = '/api/wallet/approve';
  static const String getPendingTransactions =
      '/api/wallet/pending-transactions';

  // Bookings endpoints
  static const String getCalendar = '/api/bookings/calendar';
  static const String createBooking = '/api/bookings';
  static const String cancelBooking = '/api/bookings';
  static const String getMyBookings = '/api/bookings/my-bookings';

  // Courts endpoints
  static const String getCourts = '/api/courts';

  // Members endpoints
  static const String getMembers = '/api/members';
  static const String getMemberProfile = '/api/members';

  // News endpoints
  static const String getNews = '/api/news';

  // Tournaments endpoints
  static const String getTournaments = '/api/tournaments';

  // Notifications endpoints
  static const String getNotifications = '/api/notifications';
  static const String markAsRead = '/api/notifications';

  // SignalR Hub
  static String get hubUrl => '$baseUrl/pcmhub';
}
