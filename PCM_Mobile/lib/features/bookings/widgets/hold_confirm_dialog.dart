import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/booking_provider.dart';

class HoldConfirmDialog extends ConsumerStatefulWidget {
  final String courtName;
  final DateTime startTime;
  final DateTime endTime;
  final int bookingId;
  final DateTime expiresAt;
  final double totalPrice;
  final double currentBalance;
  final VoidCallback? onConfirmed; // Callback when confirmed
  final VoidCallback? onCancelled; // Callback when cancelled/expired

  const HoldConfirmDialog({
    super.key,
    required this.courtName,
    required this.startTime,
    required this.endTime,
    required this.bookingId,
    required this.expiresAt,
    required this.totalPrice,
    required this.currentBalance,
    this.onConfirmed,
    this.onCancelled,
  });

  @override
  ConsumerState<HoldConfirmDialog> createState() => _HoldConfirmDialogState();
}

class _HoldConfirmDialogState extends ConsumerState<HoldConfirmDialog> {
  late Timer _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startCountdown();
  }

  void _calculateRemainingTime() {
    final remaining = widget.expiresAt.difference(DateTime.now()).inSeconds;
    setState(() {
      _secondsRemaining = remaining > 0 ? remaining : 0;
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          _handleExpired();
        }
      });
    });
  }

  void _handleExpired() {
    if (mounted) {
      Navigator.of(context).pop();
      widget.onCancelled?.call(); // Trigger refresh callback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hết thời gian giữ chỗ! Vui lòng đặt lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmBooking() async {
    try {
      await ref.read(bookingProvider.notifier).confirmBooking(widget.bookingId);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onConfirmed?.call(); // Trigger refresh callback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xác nhận đặt sân thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelHold() async {
    try {
      await ref.read(bookingProvider.notifier).cancelHoldBooking(widget.bookingId);
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onCancelled?.call(); // Trigger refresh callback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy giữ chỗ'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final balanceAfter = widget.currentBalance - widget.totalPrice;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.timer, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Xác nhận đặt sân'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Countdown Timer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _secondsRemaining > 120 
                    ? Colors.green.shade50 
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _secondsRemaining > 120 
                      ? Colors.green 
                      : Colors.red,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    color: _secondsRemaining > 120 
                        ? Colors.green 
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Còn ${_formatTime(_secondsRemaining)} để xác nhận',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining > 120 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Booking Details
            _buildInfoRow('Sân', widget.courtName),
            _buildInfoRow('Ngày', dateFormat.format(widget.startTime)),
            _buildInfoRow('Giờ', '${timeFormat.format(widget.startTime)} - ${timeFormat.format(widget.endTime)}'),
            const Divider(),
            _buildInfoRow('Giá tiền', '${widget.totalPrice.toStringAsFixed(0)}đ', isBold: true),
            _buildInfoRow('Số dư hiện tại', '${widget.currentBalance.toStringAsFixed(0)}đ'),
            _buildInfoRow(
              'Số dư sau khi đặt', 
              '${balanceAfter.toStringAsFixed(0)}đ',
              color: balanceAfter < 0 ? Colors.red : Colors.green,
              isBold: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancelHold,
          child: const Text('Hủy giữ chỗ'),
        ),
        ElevatedButton(
          onPressed: _secondsRemaining > 0 ? _confirmBooking : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Xác nhận đặt sân'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
