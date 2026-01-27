import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import 'dio_client.dart';

class SignalRService {
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;

  HubConnection? _hubConnection;
  bool _isConnected = false;

  // Stream controllers for events
  final _notificationController = StreamController<String>.broadcast();
  final _calendarUpdateController = StreamController<void>.broadcast();
  final _walletUpdateController = StreamController<double>.broadcast();

  // Getters for streams
  Stream<String> get onNotification => _notificationController.stream;
  Stream<void> get onCalendarUpdate => _calendarUpdateController.stream;
  Stream<double> get onWalletUpdate => _walletUpdateController.stream;

  SignalRService._internal();

  Future<void> connect() async {
    if (_isConnected) {
      print('🔌 SignalR already connected');
      return;
    }

    try {
      // Get auth token
      final token = await DioClient().getAuthToken();
      if (token == null) {
        print('⚠️ No auth token, skipping SignalR connection');
        return;
      }

      print('🔌 Connecting to SignalR hub: ${ApiConstants.hubUrl}');

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            ApiConstants.hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => token,
              transport: HttpTransportType.WebSockets,
              skipNegotiation: false,
              logMessageContent: true,
            ),
          )
          .withAutomaticReconnect()
          .build();

      // Listen to notifications
      _hubConnection?.on('ReceiveNotification', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final message = arguments[0].toString();
          print('🔔 Notification received: $message');
          _notificationController.add(message);
        }
      });

      // Listen to calendar updates
      _hubConnection?.on('UpdateCalendar', (arguments) {
        print('📅 Calendar update received');
        _calendarUpdateController.add(null);
      });

      // Listen to wallet updates
      _hubConnection?.on('UpdateWallet', (arguments) {
        if (arguments != null && arguments.isNotEmpty) {
          final newBalance = double.tryParse(arguments[0].toString()) ?? 0.0;
          print('💰 Wallet update received: $newBalance');
          _walletUpdateController.add(newBalance);
        }
      });

      // Connection state handlers
      _hubConnection?.onclose(({error}) {
        print('❌ SignalR connection closed: ${error?.toString() ?? ""}');
        _isConnected = false;
      });

      _hubConnection?.onreconnecting(({error}) {
        print('🔄 SignalR reconnecting: ${error?.toString() ?? ""}');
        _isConnected = false;
      });

      _hubConnection?.onreconnected(({connectionId}) {
        print('✅ SignalR reconnected: ${connectionId ?? ""}');
        _isConnected = true;
      });

      // Start connection
      await _hubConnection?.start();
      _isConnected = true;
      print('✅ SignalR connected successfully');
    } catch (e) {
      print('❌ SignalR connection error: $e');
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    if (_hubConnection != null) {
      await _hubConnection?.stop();
      _isConnected = false;
      print('🔌 SignalR disconnected');
    }
  }

  bool get isConnected => _isConnected;

  void dispose() {
    _notificationController.close();
    _calendarUpdateController.close();
    _walletUpdateController.close();
    disconnect();
  }

  // Hub methods (call server methods)
  Future<void> updateCalendar() async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection?.invoke('UpdateCalendar');
        print('📅 UpdateCalendar invoked');
      } catch (e) {
        print('❌ Error invoking UpdateCalendar: $e');
      }
    }
  }

  Future<void> joinMatchGroup(int matchId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection?.invoke('JoinMatchGroup', args: [matchId]);
        print('🎾 Joined match group: $matchId');
      } catch (e) {
        print('❌ Error joining match group: $e');
      }
    }
  }

  Future<void> leaveMatchGroup(int matchId) async {
    if (_hubConnection != null && _isConnected) {
      try {
        await _hubConnection?.invoke('LeaveMatchGroup', args: [matchId]);
        print('🎾 Left match group: $matchId');
      } catch (e) {
        print('❌ Error leaving match group: $e');
      }
    }
  }
}
