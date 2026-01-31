import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../models/enums.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(bookingProvider.notifier).loadMyBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(bookingProvider.notifier).loadMyBookings();
  }

  List<Booking> _filterBookings(List<Booking> bookings, BookingStatus status) {
    final now = DateTime.now();

    switch (status) {
      case BookingStatus.confirmed:
        // Upcoming bookings
        return bookings
            .where(
              (b) =>
                  (b.status == BookingStatus.confirmed ||
                      b.status == BookingStatus.holding) &&
                  b.startTime.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

      case BookingStatus.completed:
        // Completed bookings (past)
        return bookings
            .where(
              (b) =>
                  b.status == BookingStatus.confirmed &&
                  b.endTime.isBefore(now),
            )
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

      case BookingStatus.cancelled:
        // Cancelled bookings
        return bookings
            .where((b) => b.status == BookingStatus.cancelled)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final allBookings = bookingState.myBookings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử booking'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sắp tới'),
            Tab(text: 'Đã chơi'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Upcoming
            _buildBookingList(
              _filterBookings(allBookings, BookingStatus.confirmed),
              'Chưa có booking sắp tới',
              Icons.calendar_today_outlined,
            ),
            // Completed
            _buildBookingList(
              _filterBookings(allBookings, BookingStatus.completed),
              'Chưa có booking nào đã chơi',
              Icons.check_circle_outline,
            ),
            // Cancelled
            _buildBookingList(
              _filterBookings(allBookings, BookingStatus.cancelled),
              'Chưa có booking bị hủy',
              Icons.cancel_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(
    List<Booking> bookings,
    String emptyMessage,
    IconData emptyIcon,
  ) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: emptyIcon,
        title: emptyMessage,
        message: 'Các booking của bạn sẽ xuất hiện ở đây.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(booking.status);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Court name + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.courtName ?? 'Sân ${booking.courtId}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd/MM/yyyy').format(booking.startTime)} • '
                '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${booking.totalPrice.toStringAsFixed(0)}đ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),

          // Recurring indicator
          if (booking.recurrenceRule != null &&
              booking.recurrenceRule!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.repeat,
                  size: 18,
                  color: AppTheme.secondaryTeal,
                ),
                const SizedBox(width: 8),
                Text(
                  'Booking định kỳ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return const Color(0xFF4CAF50); // Green - confirmed
      case BookingStatus.holding:
        return const Color(0xFFFF9800); // Orange - holding
      case BookingStatus.cancelled:
        return const Color(0xFFF44336); // Red - cancelled
      case BookingStatus.completed:
        return const Color(0xFF2196F3); // Blue - completed
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.holding:
        return 'Đang giữ chỗ';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
      default:
        return 'Không rõ';
    }
  }
}
