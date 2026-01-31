import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/auth_service.dart';
import '../core/services/signalr_service.dart';
import '../models/user.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final Member? member;
  final bool isLoading;
  final bool isCheckingAuth; // NEW: Prevent redirect during auth check
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.member,
    this.isLoading = false,
    this.isCheckingAuth = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    Member? member,
    bool? isLoading,
    bool? isCheckingAuth,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      member: member ?? this.member,
      isLoading: isLoading ?? this.isLoading,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final SignalRService _signalRService = SignalRService();

  AuthNotifier(this._authService) : super(AuthState()) {
    checkAuthStatus();
    _setupSignalRListeners();
  }

  void _setupSignalRListeners() {
    // Listen to wallet updates from SignalR
    _signalRService.onWalletUpdate.listen((newBalance) {
      print('💰 Wallet balance updated via SignalR: $newBalance');
      updateWalletBalance(newBalance);
    });

    // Listen to notifications
    _signalRService.onNotification.listen((message) {
      print('🔔 Notification: $message');
      // Can add a snackbar or notification UI here
    });
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(isCheckingAuth: true);
    final isLoggedIn = await _authService.isLoggedIn();

    if (isLoggedIn) {
      try {
        print('🔍 Checking auth status...');
        final userData = await _authService.getMe();
        print('📦 GetMe response: $userData');

        // Backend returns: { email, fullName, role, member }
        // NOT: { user: {...}, member: {...} }
        final user = User(
          id: userData['email'], // Using email as ID
          email: userData['email'],
          fullName: userData['fullName'],
          role: userData['role'],
          createdDate: DateTime.now(),
        );

        // Parse member (may be null for admin)
        final Member? member = userData['member'] != null
            ? Member.fromJson(userData['member'])
            : null;

        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          member: member,
          isCheckingAuth: false,
        );

        // Connect to SignalR after successful auth
        await _signalRService.connect();
        print(
          '✅ Session restored: ${user.email}, role=${user.role}, isAdmin=${user.isAdmin}',
        );
      } catch (e, stackTrace) {
        print('❌ Session invalid or expired: $e');
        print('📍 Stack trace: $stackTrace');
        // Clear invalid token
        state = state.copyWith(isAuthenticated: false, isCheckingAuth: false);
        await _authService.logout();
      }
    } else {
      print('ℹ️ No saved session found');
      state = state.copyWith(isCheckingAuth: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final meData = await _authService.login(email, password);
      print('🔑 Me data: $meData');

      final user = User(
        id: meData['email'], // Using email as ID since backend doesn't return userId
        email: meData['email'],
        fullName: meData['fullName'],
        role: meData['role'], // Add role from response
        createdDate: DateTime.now(), // Backend doesn't return this
      );

      final member = meData['member'] != null
          ? Member.fromJson(meData['member'])
          : null;

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        member: member,
        isLoading: false,
      );

      // Connect to SignalR after login
      await _signalRService.connect();

      print(
        '✅ Auth state updated: isAuthenticated=${state.isAuthenticated}, user=${user.email}, role=${user.role}, isAdmin=${user.isAdmin}, member=${member?.fullName ?? "null"}',
      );
    } catch (e) {
      print('❌ Login error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _signalRService.disconnect();
    await _authService.logout();
    state = AuthState();
  }

  void updateWalletBalance(double newBalance) {
    if (state.member != null) {
      final updatedMember = Member(
        id: state.member!.id,
        userId: state.member!.userId,
        fullName: state.member!.fullName,
        avatarUrl: state.member!.avatarUrl,
        joinDate: state.member!.joinDate,
        walletBalance: newBalance,
        tier: state.member!.tier,
        rankLevel: state.member!.rankLevel,
        totalSpent: state.member!.totalSpent,
        isActive: state.member!.isActive,
      );
      state = state.copyWith(member: updatedMember);
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
