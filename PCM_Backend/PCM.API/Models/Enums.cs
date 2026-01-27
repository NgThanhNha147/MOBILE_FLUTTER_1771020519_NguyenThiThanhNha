namespace PCM.API.Models;

public enum MemberTier
{
    Standard,
    Silver,
    Gold,
    Diamond
}

public enum TransactionType
{
    Deposit,
    Withdraw,
    Payment,
    Refund,
    Reward
}

public enum TransactionStatus
{
    Pending,
    Completed,
    Rejected,
    Failed
}

public enum BookingStatus
{
    Holding,         // User đã chọn slot, đang giữ chỗ 5 phút
    PendingPayment,  // Đã xác nhận, chờ thanh toán (nếu cần)
    Confirmed,       // Đã thanh toán, confirmed
    Cancelled,       // Đã hủy
    Completed        // Đã hoàn thành (sau thời gian chơi)
}

public enum TournamentFormat
{
    RoundRobin,
    Knockout,
    Hybrid
}

public enum TournamentStatus
{
    Open,
    Registering,
    DrawCompleted,
    Ongoing,
    Finished
}

public enum WinningSide
{
    Team1,
    Team2,
    Draw
}

public enum MatchStatus
{
    Scheduled,
    InProgress,
    Finished
}
