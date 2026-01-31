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

public enum TournamentType
{
    Official,      // Giải đấu chính thức do CLB tổ chức
    Challenge1v1,  // Kèo thách đấu 1v1 do người chơi tạo
    TeamBattle,    // Đấu đội/nhóm
    MiniGame       // Mini game, thử thách nhỏ
}

public enum TournamentFormat
{
    RoundRobin,
    Knockout,
    Hybrid
}

public enum TournamentStatus
{
    Open,          // Mở đăng ký
    Registering,   // Đang đăng ký
    DrawCompleted, // Đã bốc thăm
    Ongoing,       // Đang diễn ra
    Finished       // Đã kết thúc
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
