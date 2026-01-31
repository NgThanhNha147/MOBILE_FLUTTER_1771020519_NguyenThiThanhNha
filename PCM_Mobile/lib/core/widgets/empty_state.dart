import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryBlue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: iconColor ?? AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Pre-made empty states for common scenarios
class EmptyBookingsState extends StatelessWidget {
  final VoidCallback? onBook;

  const EmptyBookingsState({super.key, this.onBook});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'Chưa có booking nào',
      message: 'Bạn chưa đặt sân nào. Hãy bắt đầu đặt sân để chơi pickleball!',
      actionLabel: 'Đặt sân ngay',
      onAction: onBook,
    );
  }
}

class EmptyTransactionsState extends StatelessWidget {
  const EmptyTransactionsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      iconColor: AppTheme.successGreen,
      title: 'Chưa có giao dịch',
      message: 'Bạn chưa có giao dịch nào trong ví. Hãy nạp tiền để bắt đầu!',
    );
  }
}

class EmptyMembersState extends StatelessWidget {
  const EmptyMembersState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.people_outline,
      iconColor: AppTheme.secondaryTeal,
      title: 'Chưa có thành viên',
      message: 'Danh sách thành viên trống. Vui lòng thử lại sau.',
    );
  }
}

class EmptyNotificationsState extends StatelessWidget {
  const EmptyNotificationsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.notifications_none,
      iconColor: AppTheme.warningOrange,
      title: 'Không có thông báo',
      message: 'Bạn đã xem hết tất cả thông báo. Sẽ có thông báo mới sớm thôi!',
    );
  }
}

class EmptySearchState extends StatelessWidget {
  final String? searchQuery;

  const EmptySearchState({super.key, this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      iconColor: Colors.grey,
      title: 'Không tìm thấy kết quả',
      message: searchQuery != null
          ? 'Không tìm thấy kết quả cho "$searchQuery"'
          : 'Không có kết quả phù hợp. Vui lòng thử từ khóa khác.',
    );
  }
}

class NetworkErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorState({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.wifi_off,
      iconColor: AppTheme.errorRed,
      title: 'Mất kết nối',
      message:
          'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet.',
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}
