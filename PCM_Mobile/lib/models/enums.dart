// SYNCED WITH BACKEND - PCM.API.Models.Enums.cs
// DO NOT MODIFY ENUM ORDER - Must match backend integer values

enum MemberTier { 
  standard,  // 0
  silver,    // 1
  gold,      // 2
  diamond    // 3
}

enum TransactionType {
  deposit,   // 0
  withdraw,  // 1
  payment,   // 2
  refund,    // 3
  reward     // 4
}

enum TransactionStatus { 
  pending,   // 0
  completed, // 1
  rejected,  // 2
  failed     // 3
}

enum BookingStatus { 
  holding,        // 0 - Đang giữ chỗ 5 phút
  pendingPayment, // 1 - Chờ thanh toán
  confirmed,      // 2 - Đã xác nhận
  cancelled,      // 3 - Đã hủy
  completed       // 4 - Hoàn thành
}

enum TournamentFormat { 
  roundRobin,     // 0
  knockout,       // 1
  hybrid          // 2
}

enum TournamentStatus { 
  open,           // 0
  registering,    // 1
  drawCompleted,  // 2
  ongoing,        // 3
  finished        // 4
}

enum WinningSide { none, team1, team2 }

enum MatchStatus { scheduled, inProgress, finished }

// Extensions for display names
extension MemberTierExtension on MemberTier {
  String get displayName {
    switch (this) {
      case MemberTier.standard:
        return 'Standard';
      case MemberTier.silver:
        return 'Silver';
      case MemberTier.gold:
        return 'Gold';
      case MemberTier.diamond:
        return 'Diamond';
    }
  }
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.deposit:
        return 'Nạp tiền';
      case TransactionType.withdraw:
        return 'Rút tiền';
      case TransactionType.payment:
        return 'Thanh toán';
      case TransactionType.refund:
        return 'Hoàn tiền';
      case TransactionType.reward:
        return 'Tiền thưởng';
    }
  }
}

extension TransactionStatusExtension on TransactionStatus {
  String get displayName {
    switch (this) {
      case TransactionStatus.pending:
        return 'Chờ xử lý';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.rejected:
        return 'Từ chối';
      case TransactionStatus.failed:
        return 'Thất bại';
    }
  }
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.holding:
        return 'Đang giữ chỗ';
      case BookingStatus.pendingPayment:
        return 'Chờ thanh toán';
      case BookingStatus.confirmed:
        return 'Đã xác nhận';
      case BookingStatus.cancelled:
        return 'Đã hủy';
      case BookingStatus.completed:
        return 'Hoàn thành';
    }
  }
}

extension TournamentFormatExtension on TournamentFormat {
  String get displayName {
    switch (this) {
      case TournamentFormat.roundRobin:
        return 'Vòng tròn';
      case TournamentFormat.knockout:
        return 'Loại trực tiếp';
      case TournamentFormat.hybrid:
        return 'Kết hợp';
    }
  }
}

extension TournamentStatusExtension on TournamentStatus {
  String get displayName {
    switch (this) {
      case TournamentStatus.open:
        return 'Mở đăng ký';
      case TournamentStatus.registering:
        return 'Đang đăng ký';
      case TournamentStatus.drawCompleted:
        return 'Đã bốc thăm';
      case TournamentStatus.ongoing:
        return 'Đang diễn ra';
      case TournamentStatus.finished:
        return 'Đã kết thúc';
    }
  }
}

extension WinningSideExtension on WinningSide {
  String get displayName {
    switch (this) {
      case WinningSide.none:
        return 'Chưa xác định';
      case WinningSide.team1:
        return 'Đội 1';
      case WinningSide.team2:
        return 'Đội 2';
    }
  }
}

extension MatchStatusExtension on MatchStatus {
  String get displayName {
    switch (this) {
      case MatchStatus.scheduled:
        return 'Đã lên lịch';
      case MatchStatus.inProgress:
        return 'Đang diễn ra';
      case MatchStatus.finished:
        return 'Đã kết thúc';
    }
  }
}
