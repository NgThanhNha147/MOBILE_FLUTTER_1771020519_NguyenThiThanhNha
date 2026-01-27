import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/constants/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = _getMockNotifications();
    
    final groupedNotifications = <String, List<Map<String, dynamic>>>{};
    for (final notif in notifications) {
      final dateKey = DateFormat('dd/MM/yyyy').format(notif['date']);
      groupedNotifications.putIfAbsent(dateKey, () => []).add(notif);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Thông báo'),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.1)],
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.secondaryPink.withOpacity(0.1), AppTheme.primaryPurple.withOpacity(0.1)],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20),
          itemCount: groupedNotifications.length,
          itemBuilder: (context, index) {
            final dateKey = groupedNotifications.keys.elementAt(index);
            final items = groupedNotifications[dateKey]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(dateKey, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
                ),
                ...items.map((notif) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    gradientColors: notif['isRead']
                        ? []
                        : [AppTheme.primaryBlue.withOpacity(0.05), AppTheme.primaryPurple.withOpacity(0.05)],
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: _getNotificationTypeGradient(notif['type']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getNotificationTypeIcon(notif['type']), color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(notif['title'], style: TextStyle(fontWeight: notif['isRead'] ? FontWeight.normal : FontWeight.bold, fontSize: 16)),
                                  ),
                                  if (!notif['isRead'])
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(notif['message'], style: TextStyle(color: Colors.grey[600], fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(DateFormat('HH:mm').format(notif['date']), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData _getNotificationTypeIcon(String type) {
    switch (type) {
      case 'booking':
        return Icons.calendar_today;
      case 'tournament':
        return Icons.emoji_events;
      case 'wallet':
        return Icons.payments;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  LinearGradient _getNotificationTypeGradient(String type) {
    switch (type) {
      case 'booking':
        return const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.secondaryTeal]);
      case 'tournament':
        return const LinearGradient(colors: [AppTheme.accentOrange, AppTheme.secondaryPink]);
      case 'wallet':
        return const LinearGradient(colors: [AppTheme.successGreen, Color(0xFF81C784)]);
      case 'system':
        return const LinearGradient(colors: [AppTheme.primaryPurple, AppTheme.secondaryPink]);
      default:
        return AppTheme.primaryGradient;
    }
  }

  List<Map<String, dynamic>> _getMockNotifications() {
    final now = DateTime.now();
    return [
      {
        'id': 1,
        'type': 'booking',
        'title': 'Đặt sân thành công',
        'message': 'Bạn đã đặt sân 1 vào ngày 15/12/2024 lúc 08:00',
        'date': now,
        'isRead': false,
      },
      {
        'id': 2,
        'type': 'wallet',
        'title': 'Nạp tiền thành công',
        'message': 'Tài khoản của bạn đã được nạp 500.000 VNĐ',
        'date': now.subtract(const Duration(hours: 2)),
        'isRead': false,
      },
      {
        'id': 3,
        'type': 'tournament',
        'title': 'Giải đấu sắp diễn ra',
        'message': 'Giải Pickleball Mùa Xuân 2024 sẽ bắt đầu vào 20/12/2024',
        'date': now.subtract(const Duration(days: 1)),
        'isRead': true,
      },
      {
        'id': 4,
        'type': 'system',
        'title': 'Cập nhật hệ thống',
        'message': 'Hệ thống sẽ bảo trì vào 0h ngày 18/12/2024',
        'date': now.subtract(const Duration(days: 1)),
        'isRead': true,
      },
    ];
  }
}
