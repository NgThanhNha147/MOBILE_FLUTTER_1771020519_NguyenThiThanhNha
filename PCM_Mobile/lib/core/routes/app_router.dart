import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/wallet/wallet_screen.dart';
import '../../features/wallet/deposit_screen.dart';
import '../../features/bookings/bookings_screen.dart';
import '../../features/bookings/create_booking_screen.dart';
import '../../../features/tournaments/tournaments_screen.dart';
import '../../features/members/members_screen.dart';
import '../../features/members/member_profile_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../widgets/main_layout.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      print('🔄 Router redirect: location=${state.matchedLocation}, isAuth=$isAuthenticated, isAuthRoute=$isAuthRoute');

      // Redirect to login if not authenticated
      if (!isAuthenticated && !isAuthRoute) {
        print('➡️  Redirecting to login (not authenticated)');
        return '/auth/login';
      }

      // Redirect to dashboard if authenticated and trying to access auth routes
      if (isAuthenticated && isAuthRoute) {
        print('➡️  Redirecting to dashboard (already authenticated)');
        return '/';
      }

      print('✔️  No redirect needed');
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/auth/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // Main App Routes with Shell
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          // Dashboard
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),

          // Wallet Routes
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const WalletScreen(),
              transitionsBuilder: _slideTransition,
            ),
            routes: [
              GoRoute(
                path: 'deposit',
                name: 'deposit',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const DepositScreen(),
                  transitionsBuilder: _slideUpTransition,
                ),
              ),
            ],
          ),

          // Bookings Routes
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const BookingsScreen(),
              transitionsBuilder: _slideTransition,
            ),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-booking',
                pageBuilder: (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const CreateBookingScreen(),
                  transitionsBuilder: _slideUpTransition,
                ),
              ),
            ],
          ),

          // Tournaments Routes
          GoRoute(
            path: '/tournaments',
            name: 'tournaments',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const TournamentsScreen(),
              transitionsBuilder: _slideTransition,
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'tournament-detail',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: TournamentDetailScreen(tournamentId: id),
                    transitionsBuilder: _scaleTransition,
                  );
                },
              ),
            ],
          ),

          // Members Routes
          GoRoute(
            path: '/members',
            name: 'members',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const MembersScreen(),
              transitionsBuilder: _slideTransition,
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'member-profile',
                pageBuilder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return CustomTransitionPage(
                    key: state.pageKey,
                    child: MemberProfileScreen(memberId: id),
                    transitionsBuilder: _scaleTransition,
                  );
                },
              ),
            ],
          ),

          // Notifications
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationsScreen(),
              transitionsBuilder: _slideTransition,
            ),
          ),
        ],
      ),
    ],
  );
});

// Custom Page Transitions
Widget _fadeTransition(context, animation, secondaryAnimation, child) {
  return FadeTransition(
    opacity: CurveTween(curve: Curves.easeInOutCubic).animate(animation),
    child: child,
  );
}

Widget _slideTransition(context, animation, secondaryAnimation, child) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  final tween = Tween(
    begin: begin,
    end: end,
  ).chain(CurveTween(curve: Curves.easeInOutCubic));
  final offsetAnimation = animation.drive(tween);

  return SlideTransition(
    position: offsetAnimation,
    child: FadeTransition(opacity: animation, child: child),
  );
}

Widget _slideUpTransition(context, animation, secondaryAnimation, child) {
  const begin = Offset(0.0, 1.0);
  const end = Offset.zero;
  final tween = Tween(
    begin: begin,
    end: end,
  ).chain(CurveTween(curve: Curves.easeOutCubic));
  final offsetAnimation = animation.drive(tween);

  return SlideTransition(
    position: offsetAnimation,
    child: FadeTransition(
      opacity: CurveTween(curve: Curves.easeIn).animate(animation),
      child: child,
    ),
  );
}

Widget _scaleTransition(context, animation, secondaryAnimation, child) {
  return ScaleTransition(
    scale: CurveTween(curve: Curves.easeInOutBack).animate(animation),
    child: FadeTransition(opacity: animation, child: child),
  );
}
