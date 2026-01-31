import 'package:flutter/material.dart';
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
              color: Colors.black,
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
    // Define clear colors for status
    const Color greenAvailable = Color(0xFF4CAF50); // Bright green
    const Color redBooked = Color(0xFFF44336); // Bright red
    const Color yellowMine = Color(0xFFFFC107); // Bright yellow
    const Color orangeHolding = Color(0xFFFF9800); // Bright orange

    Color backgroundColor;
    Color borderColor;
    String statusText;
    IconData icon;
    bool isInteractive = true;

    // Check slot status with clear priority order
    final isHolding = slot.status == 'Holding';
    final isMySlot = slot.memberId == currentUserId;

    if (!slot.isBooked) {
      // 🟢 CASE 1: Slot completely empty - Available
      backgroundColor = greenAvailable.withOpacity(0.15);
      borderColor = greenAvailable;
      statusText = 'Trống';
      icon = Icons.check_circle_outline;
      isInteractive = true;
    } else if (isHolding && isMySlot) {
      // 🟠 CASE 2: I'm holding this slot (payment pending)
      backgroundColor = orangeHolding.withOpacity(0.15);
      borderColor = orangeHolding;
      statusText = 'Đang giữ (tôi)';
      icon = Icons.schedule;
      isInteractive = false; // Can't tap - already in payment flow
    } else if (isHolding && !isMySlot) {
      // 🟠 CASE 3: Someone else is holding (temporarily locked)
      backgroundColor = orangeHolding.withOpacity(0.08);
      borderColor = orangeHolding.withOpacity(0.6);
      statusText = 'Đang giữ chỗ';
      icon = Icons.lock_clock;
      isInteractive = false; // Can't book - someone else holding
    } else if (isMySlot) {
      // 🟡 CASE 4: My confirmed booking
      backgroundColor = yellowMine.withOpacity(0.15);
      borderColor = yellowMine;
      statusText = 'Của tôi';
      icon = Icons.star;
      isInteractive = true; // Can tap to cancel/manage
    } else {
      // 🔴 CASE 5: Booked by someone else (confirmed)
      backgroundColor = redBooked.withOpacity(0.15);
      borderColor = redBooked;
      statusText = 'Đã đặt';
      icon = Icons.block;
      isInteractive = false; // Can't book - already taken
    }

    return GestureDetector(
      onTap: isInteractive ? () => onSlotTap(slot) : null,
      child: Opacity(
        opacity: isInteractive ? 1.0 : 0.6,
        child: Container(
          width: 90,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isInteractive
                ? [
                    BoxShadow(
                      color: borderColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
