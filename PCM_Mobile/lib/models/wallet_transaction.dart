import 'enums.dart';

class WalletTransaction {
  final int id;
  final int memberId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? description;
  final String? proofImageUrl;
  final String? relatedId;
  final DateTime createdDate;
  final DateTime? approvedDate;
  final String? approvedBy;

  WalletTransaction({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    this.proofImageUrl,
    this.relatedId,
    required this.createdDate,
    this.approvedDate,
    this.approvedBy,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      memberId: json['memberId'],
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type']],
      status: TransactionStatus.values[json['status']],
      description: json['description'],
      proofImageUrl: json['proofImageUrl'],
      relatedId: json['relatedId'],
      createdDate: DateTime.parse(json['createdDate']),
      approvedDate: json['approvedDate'] != null
          ? DateTime.parse(json['approvedDate'])
          : null,
      approvedBy: json['approvedBy'],
    );
  }
}
