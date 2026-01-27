import 'enums.dart';

class Booking {
  final int id;
  final int courtId;
  final int memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final String? recurrenceRule;
  final DateTime createdDate;
  final String? courtName;
  final String? memberName;

  Booking({
    required this.id,
    required this.courtId,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.recurrenceRule,
    required this.createdDate,
    this.courtName,
    this.memberName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // SAFE ENUM PARSING: Handle out-of-range enum values
    BookingStatus parseStatus(dynamic value) {
      if (value is int && value >= 0 && value < BookingStatus.values.length) {
        return BookingStatus.values[value];
      }
      return BookingStatus.pendingPayment; // Default fallback
    }

    return Booking(
      id: json['id'],
      courtId: json['courtId'],
      memberId: json['memberId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: parseStatus(json['status']),
      recurrenceRule: json['recurrenceRule'],
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate']) 
          : DateTime.now(),
      courtName: json['courtName'],
      memberName: json['memberName'],
    );
  }
}
