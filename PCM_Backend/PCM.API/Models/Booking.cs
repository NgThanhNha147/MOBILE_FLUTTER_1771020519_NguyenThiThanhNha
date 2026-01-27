using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_Bookings")]
public class Booking
{
    [Key]
    public int Id { get; set; }
    
    public int CourtId { get; set; }
    
    public int MemberId { get; set; }
    
    public DateTime StartTime { get; set; }
    
    public DateTime EndTime { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalPrice { get; set; }
    
    public int? TransactionId { get; set; }
    
    public bool IsRecurring { get; set; } = false;
    
    [MaxLength(200)]
    public string? RecurrenceRule { get; set; }
    
    public int? ParentBookingId { get; set; }
    
    public BookingStatus Status { get; set; } = BookingStatus.PendingPayment;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    public DateTime? HoldExpiresAt { get; set; }
    
    // Navigation
    [ForeignKey(nameof(CourtId))]
    public virtual Court Court { get; set; } = null!;
    
    [ForeignKey(nameof(MemberId))]
    public virtual Member Member { get; set; } = null!;
}
