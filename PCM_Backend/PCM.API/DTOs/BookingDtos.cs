namespace PCM.API.DTOs;

public class EditBookingDto
{
    public DateTime NewStartTime { get; set; }
    public DateTime NewEndTime { get; set; }
}

public class RescheduleBookingDto
{
    public DateTime NewStartTime { get; set; }
    public DateTime NewEndTime { get; set; }
}

public class CancelPreviewDto
{
    public bool CanCancel { get; set; }
    public decimal RefundPercentage { get; set; }
    public decimal RefundAmount { get; set; }
    public string Message { get; set; } = string.Empty;
    public double HoursUntilStart { get; set; }
}

public class TimeSlotDto
{
    public int CourtId { get; set; }
    public string CourtName { get; set; } = string.Empty;
    public int Hour { get; set; }
    public string Time { get; set; } = string.Empty;
    public bool IsBooked { get; set; }
    public int? BookingId { get; set; }
    public int? MemberId { get; set; }
    public string? MemberName { get; set; }
    public string? Status { get; set; }
}

public class HoldBookingDto
{
    public int CourtId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
}

public class HoldResponseDto
{
    public int BookingId { get; set; }
    public DateTime ExpiresAt { get; set; }
    public decimal TotalPrice { get; set; }
    public int SecondsRemaining { get; set; }
}

public class ConfirmBookingDto
{
    public int BookingId { get; set; }
}

public class RecurringBookingDto
{
    public int CourtId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TimeOnly StartTime { get; set; }
    public TimeOnly EndTime { get; set; }
    public string RecurrencePattern { get; set; } = string.Empty; // e.g., "Weekly;Mon,Wed,Fri"
    public int OccurrencesCount { get; set; }
}
