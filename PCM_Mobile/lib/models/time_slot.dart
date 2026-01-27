class TimeSlot {
  final int courtId;
  final String courtName;
  final int hour;
  final String time;
  final bool isBooked;
  final int? bookingId;
  final int? memberId;
  final String? memberName;
  final String? status;

  TimeSlot({
    required this.courtId,
    required this.courtName,
    required this.hour,
    required this.time,
    required this.isBooked,
    this.bookingId,
    this.memberId,
    this.memberName,
    this.status,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      courtId: json['courtId'] as int,
      courtName: json['courtName'] as String,
      hour: json['hour'] as int,
      time: json['time'] as String,
      isBooked: json['isBooked'] as bool,
      bookingId: json['bookingId'] as int?,
      memberId: json['memberId'] as int?,
      memberName: json['memberName'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courtId': courtId,
      'courtName': courtName,
      'hour': hour,
      'time': time,
      'isBooked': isBooked,
      'bookingId': bookingId,
      'memberId': memberId,
      'memberName': memberName,
      'status': status,
    };
  }
}

class CancelPreview {
  final bool canCancel;
  final double refundPercentage;
  final double refundAmount;
  final String message;
  final double hoursUntilStart;

  CancelPreview({
    required this.canCancel,
    required this.refundPercentage,
    required this.refundAmount,
    required this.message,
    required this.hoursUntilStart,
  });

  factory CancelPreview.fromJson(Map<String, dynamic> json) {
    return CancelPreview(
      canCancel: json['canCancel'] as bool,
      refundPercentage: (json['refundPercentage'] as num).toDouble(),
      refundAmount: (json['refundAmount'] as num).toDouble(),
      message: json['message'] as String,
      hoursUntilStart: (json['hoursUntilStart'] as num).toDouble(),
    );
  }
}
