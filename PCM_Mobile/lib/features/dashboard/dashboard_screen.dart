import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // Load initial data
    Future.microtask(() {
      ref.read(bookingProvider.notifier).loadMyBookings();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(bookingProvider.notifier).loadMyBookings();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bookingState = ref.watch(bookingProvider);
    final member = authState.member;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlue.withOpacity(0.1),
            AppTheme.primaryPurple.withOpacity(0.1),
            AppTheme.secondaryPink.withOpacity(0.05),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      Text(
                        'Xin chào,',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member?.fullName ?? 'Guest',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // Wallet Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        gradientColors: [
                          AppTheme.primaryBlue.withOpacity(0.2),
                          AppTheme.primaryPurple.withOpacity(0.2),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getTierColor(member?.tier).withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getTierColor(member?.tier),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: _getTierColor(member?.tier),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getTierName(member?.tier),
                                        style: TextStyle(
                                          color: _getTierColor(member?.tier),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Số dư ví',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AnimatedCounter(
                              value: member?.walletBalance ?? 0,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              suffix: ' VNĐ',
                              decimals: 0,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    icon: Icons.add_circle_outline,
                                    label: 'Nạp tiền',
                                    onTap: () => context.push('/wallet/deposit'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildQuickActionButton(
                                    context,
                                    icon: Icons.history,
                                    label: 'Lịch sử',
                                    onTap: () => context.push('/wallet'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quick Actions Grid
                      Text(
                        'Thao tác nhanh',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              icon: Icons.calendar_today,
                              title: 'Đặt sân',
                              color: AppTheme.primaryBlue,
                              onTap: () => context.push('/bookings'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              icon: Icons.emoji_events,
                              title: 'Giải đấu',
                              color: AppTheme.accentOrange,
                              onTap: () => context.push('/tournaments'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionCard(
                              context,
                              icon: Icons.people,
                              title: 'Thành viên',
                              color: AppTheme.secondaryTeal,
                              onTap: () => context.push('/members'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionCard(
                              context,
                              icon: Icons.notifications,
                              title: 'Thông báo',
                              color: AppTheme.secondaryPink,
                              onTap: () => context.push('/notifications'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // My Bookings
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Lịch đặt sân',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/bookings'),
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (bookingState.isLoading)
                        ...List.generate(
                          3,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ShimmerLoading(
                              width: double.infinity,
                              height: 100,
                              borderRadius: 16,
                            ),
                          ),
                        )
                      else if (bookingState.myBookings.isEmpty)
                        GlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có lịch đặt sân',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => context.push('/bookings'),
                                  child: const Text('Đặt sân ngay'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...bookingState.myBookings.take(3).map(
                              (booking) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.sports_tennis,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              booking.courtName ?? 'Sân ${booking.courtId}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_formatTime(booking.startTime)} - ${_formatTime(booking.endTime)}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${booking.totalPrice.toStringAsFixed(0)} VNĐ',
                                              style: const TextStyle(
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getStatusColor(booking.status),
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(booking.status),
                                          style: TextStyle(
                                            color: _getStatusColor(booking.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      gradientColors: [
        color.withOpacity(0.15),
        color.withOpacity(0.05),
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(dynamic tier) {
    if (tier == null) return AppTheme.bronzeTier;
    final tierIndex = tier.index ?? 0;
    switch (tierIndex) {
      case 0:
        return AppTheme.bronzeTier;
      case 1:
        return AppTheme.silverTier;
      case 2:
        return AppTheme.goldTier;
      case 3:
        return AppTheme.platinumTier;
      default:
        return AppTheme.bronzeTier;
    }
  }

  String _getTierName(dynamic tier) {
    if (tier == null) return 'Bronze';
    final tierIndex = tier.index ?? 0;
    switch (tierIndex) {
      case 0:
        return 'Bronze';
      case 1:
        return 'Silver';
      case 2:
        return 'Gold';
      case 3:
        return 'Platinum';
      default:
        return 'Bronze';
    }
  }

  Color _getStatusColor(dynamic status) {
    final statusIndex = status.index ?? 0;
    switch (statusIndex) {
      case 0:
        return AppTheme.successGreen;
      case 1:
        return Colors.grey;
      case 2:
        return AppTheme.errorRed;
      default:
        return AppTheme.successGreen;
    }
  }

  String _getStatusText(dynamic status) {
    final statusIndex = status.index ?? 0;
    switch (statusIndex) {
      case 0:
        return 'Active';
      case 1:
        return 'Completed';
      case 2:
        return 'Cancelled';
      default:
        return 'Active';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
