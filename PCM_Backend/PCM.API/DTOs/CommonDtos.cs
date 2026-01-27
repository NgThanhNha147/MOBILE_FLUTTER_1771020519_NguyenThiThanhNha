namespace PCM.API.DTOs;

public class LoginDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public int? MemberId { get; set; } // Nullable because admin doesn't have member
    public decimal WalletBalance { get; set; }
}

public class RegisterDto
{
    public string Email { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
}

public class DepositRequestDto
{
    public decimal Amount { get; set; }
    public string? ProofImageUrl { get; set; }
}

public class CreateBookingDto
{
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}

public class ApproveTransactionDto
{
    public int TransactionId { get; set; }
    public bool Approved { get; set; }
}
