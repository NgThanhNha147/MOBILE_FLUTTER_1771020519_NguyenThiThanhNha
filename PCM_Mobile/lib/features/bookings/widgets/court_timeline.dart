import 'package:flutter/material.dart';
import '../../../core/constants/app_theme.dart';
import '../../../models/time_slot.dart';

class CourtTimeline extends StatelessWidget {
  final String courtName;
  final List<TimeSlot> slots;
  final int? currentUserId;
  final Function(TimeSlot) onSlotTap;

  const CourtTimeline({
    super.key,
    required this.courtName,
    required this.slots,
    required this.currentUserId,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            courtName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              return _buildSlot(context, slot);
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSlot(BuildContext context, TimeSlot slot) {
    Color backgroundColor;
    Color borderColor;
    String statusText;
    IconData icon;
    
    // Check if slot is holding
    final isHolding = slot.status == 'Holding';
    final isMyHolding = isHolding && slot.memberId == currentUserId;
    
    if (!slot.isBooked) {
      backgroundColor = AppTheme.successGreen.withOpacity(0.1);
      borderColor = AppTheme.successGreen;
      statusText = 'Trống';
      icon = Icons.check_circle_outline;
    } else if (isMyHolding) {
      backgroundColor = Colors.orange.withOpacity(0.1);
      borderColor = Colors.orange;
      statusText = 'Đang giữ';
      icon = Icons.timer;
    } else if (isHolding) {
      backgroundColor = Colors.orange.withOpacity(0.05);
      borderColor = Colors.orange.shade300;
      statusText = 'Đang giữ';
      icon = Icons.lock_clock;
    } else if (slot.memberId == currentUserId) {
      backgroundColor = AppTheme.primaryBlue.withOpacity(0.1);
      borderColor = AppTheme.primaryBlue;
      statusText = 'Của tôi';
      icon = Icons.person;
    } else {
      backgroundColor = AppTheme.errorRed.withOpacity(0.1);
      borderColor = AppTheme.errorRed;
      statusText = 'Đã đặt';
      icon = Icons.block;
    }

    return GestureDetector(
      onTap: () => onSlotTap(slot),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: borderColor, size: 26),
            const SizedBox(height: 6),
            Text(
              '${slot.hour}:00',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: borderColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusText,
              style: TextStyle(
                color: borderColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
