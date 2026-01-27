import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/constants/app_theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/time_slot.dart';
import 'widgets/court_timeline.dart';
import 'widgets/hold_confirm_dialog.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _refreshKey = 0; // Add refresh key

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    Future.microtask(() {
      ref.read(bookingProvider.notifier).loadCourts();
      _loadCalendarForMonth(_focusedDay);
    });
  }

  void _loadCalendarForMonth(DateTime date) {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    ref.read(bookingProvider.notifier).loadCalendar(
      startDate: start,
      endDate: end,
    );
  }

  Future<void> _handleRefresh() async {
    await ref.read(bookingProvider.notifier).loadCourts();
    _loadCalendarForMonth(_focusedDay);
    setState(() {
      _refreshKey++; // Force rebuild timeline
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryTeal.withOpacity(0.1),
            AppTheme.primaryBlue.withOpacity(0.1),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Đặt sân',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chọn ngày và giờ để đặt sân',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Calendar Card
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 90)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          leftChevronIcon: const Icon(
                            Icons.chevron_left,
                            color: AppTheme.primaryBlue,
                          ),
                          rightChevronIcon: const Icon(
                            Icons.chevron_right,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: AppTheme.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        eventLoader: (day) {
                          // Return list of events for this day
                          return bookingState.bookings
                              .where((b) =>
                                  isSameDay(b.startTime, day) &&
                                  b.status.index == 0) // Active bookings
                              .toList();
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                          _loadCalendarForMonth(focusedDay);
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLegendItem('Còn trống', AppTheme.successGreen),
                        _buildLegendItem('Đã đặt', AppTheme.errorRed),
                        _buildLegendItem('Của bạn', AppTheme.primaryBlue),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Chính sách hủy sân
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 CHÍNH SÁCH HỦY SÂN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildPolicyItem('✅ Hủy trước 24h', 'Hoàn 100%', AppTheme.successGreen),
                          _buildPolicyItem('⚠️  Hủy 6-24h trước', 'Hoàn 50%', AppTheme.accentOrange),
                          _buildPolicyItem('❌ Hủy < 6h trước', 'Không hoàn', AppTheme.errorRed),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Timeline View Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Lịch đặt sân theo giờ',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          _selectedDay != null 
                            ? DateFormat('dd/MM/yyyy').format(_selectedDay!)
                            : '',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Timeline Slots
                    if (_selectedDay != null)
                      FutureBuilder<List<TimeSlot>>(
                        key: ValueKey('timeline_$_refreshKey'), // Add key for rebuild
                        future: ref.read(bookingProvider.notifier).getDailySlots(_selectedDay!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                                ),
                              ),
                            );
                          }
                          
                          if (snapshot.hasError) {
                            return GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'Lỗi: ${snapshot.error}',
                                  style: const TextStyle(color: AppTheme.errorRed),
                                ),
                              ),
                            );
                          }
                          
                          final slots = snapshot.data ?? [];
                          if (slots.isEmpty) {
                            return GlassCard(
                              padding: const EdgeInsets.all(24),
                              child: Center(
                                child: Text(
                                  'Không có sân khả dụng',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // Group slots by court
                          final Map<int, List<TimeSlot>> courtGroups = {};
                          for (var slot in slots) {
                            courtGroups.putIfAbsent(slot.courtId, () => []).add(slot);
                          }
                          
                          final authState = ref.watch(authProvider);
                          final currentUserId = authState.member?.id;
                          
                          return Column(
                            children: courtGroups.entries.map((entry) {
                              final courtSlots = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(0),
                                  child: CourtTimeline(
                                    courtName: courtSlots.first.courtName,
                                    slots: courtSlots,
                                    currentUserId: currentUserId,
                                    onSlotTap: (slot) => _handleSlotTap(slot, currentUserId),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      )
                    else
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Vui lòng chọn ngày',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyItem(String label, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSlotTap(TimeSlot slot, int? currentUserId) {
    if (!slot.isBooked) {
      // Slot trống - Quick booking
      _showQuickBookingDialog(
        courtId: slot.courtId,
        courtName: slot.courtName,
        hour: slot.hour,
      );
    } else if (slot.memberId == currentUserId) {
      // Slot của user - Show cancel/edit options
      _showMyBookingOptions(slot);
    } else {
      // Slot đã được đặt bởi người khác
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot đã được đặt bởi ${slot.memberName ?? "người khác"}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showQuickBookingDialog({
    required int courtId,
    required String courtName,
    required int hour,
  }) async {
    final startTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      hour,
      0,
    );
    final endTime = startTime.add(const Duration(hours: 1));
    
    // Show loading while holding slot
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
                SizedBox(height: 16),
                Text('Đang giữ chỗ...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      // Step 1: Hold the booking
      final holdData = await ref.read(bookingProvider.notifier).holdBooking(
        courtId: courtId,
        startTime: startTime,
        endTime: endTime,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Step 2: Show confirmation dialog with countdown
        final authState = ref.read(authProvider);
        final currentBalance = authState.member?.walletBalance ?? 0.0;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => HoldConfirmDialog(
            courtName: courtName,
            startTime: startTime,
            endTime: endTime,
            bookingId: holdData['bookingId'] as int,
            expiresAt: DateTime.parse(holdData['expiresAt'] as String),
            totalPrice: (holdData['totalPrice'] as num).toDouble(),
            currentBalance: currentBalance,
            onConfirmed: _handleRefresh, // Refresh on confirm
            onCancelled: _handleRefresh, // Refresh on cancel/expire
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        final errorMessage = e.toString();
        if (errorMessage.contains('TIME_SLOT_CONFLICT') || 
            errorMessage.contains('đã có người đặt')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('❌ Slot đã bị đặt'),
              content: const Text(
                'Ai đó vừa đặt slot này trước bạn. Vui lòng chọn giờ khác!'
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {}); // Refresh calendar
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                  child: const Text('Chọn giờ khác'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showMyBookingOptions(TimeSlot slot) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Quản lý booking',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.primaryBlue),
              title: Text('${slot.courtName} - ${slot.hour}:00'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDay!)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel_outlined, color: AppTheme.errorRed),
              title: const Text('Hủy booking'),
              subtitle: const Text('Xem chính sách hoàn tiền'),
              onTap: () {
                Navigator.pop(context);
                _showCancelDialog(slot.bookingId!);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(int bookingId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final preview = await ref.read(bookingProvider.notifier).getCancelPreview(bookingId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận hủy sân'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview.message),
              const SizedBox(height: 16),
              if (preview.canCancel)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.successGreen),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Hoàn tiền:'),
                      Text(
                        '${preview.refundAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.successGreen,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            if (preview.canCancel)
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  try {
                    await ref.read(bookingProvider.notifier).cancelBooking(bookingId);
                    
                    if (mounted) {
                      await _handleRefresh(); // Refresh timeline data
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Hủy sân thành công!'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: ${e.toString()}'),
                          backgroundColor: AppTheme.errorRed,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                ),
                child: const Text('Xác nhận hủy'),
              ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _BookingForm extends ConsumerStatefulWidget {
  final int courtId;
  final String courtName;
  final DateTime selectedDate;

  const _BookingForm({
    required this.courtId,
    required this.courtName,
    required this.selectedDate,
  });

  @override
  ConsumerState<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends ConsumerState<_BookingForm> {
  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        _startTime = time;
        // Auto adjust end time
        _endTime = TimeOfDay(
          hour: (time.hour + 2) % 24,
          minute: time.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<void> _handleBooking() async {
    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      await ref.read(bookingProvider.notifier).createBooking(
            courtId: widget.courtId,
            startTime: startDateTime,
            endTime: endDateTime,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đặt sân thành công!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đặt sân ${widget.courtName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Text(
          'Ngày: ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildTimeButton(
                label: 'Giờ bắt đầu',
                time: _startTime,
                onTap: _selectStartTime,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeButton(
                label: 'Giờ kết thúc',
                time: _endTime,
                onTap: _selectEndTime,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        GlassButton(
          text: 'Xác nhận đặt sân',
          icon: Icons.check,
          onPressed: _handleBooking,
          isLoading: _isLoading,
          gradientColors: const [
            AppTheme.primaryBlue,
            AppTheme.primaryPurple,
          ],
          height: 56,
        ),
      ],
    );
  }

  Widget _buildTimeButton({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateBookingScreen extends StatelessWidget {
  const CreateBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Create Booking Screen'),
      ),
    );
  }
}
