using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_Members")]
public class Member
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string FullName { get; set; } = string.Empty;
    
    public DateTime JoinDate { get; set; } = DateTime.Now;
    
    public double RankLevel { get; set; } = 1000.0; // DUPR Rank
    
    public bool IsActive { get; set; } = true;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal WalletBalance { get; set; } = 0;
    
    public MemberTier Tier { get; set; } = MemberTier.Standard;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalSpent { get; set; } = 0;
    
    [MaxLength(500)]
    public string? AvatarUrl { get; set; }
    
    // FK to Identity User
    [Required]
    public string UserId { get; set; } = string.Empty;
    
    // Navigation properties
    public virtual ICollection<Booking> Bookings { get; set; } = new List<Booking>();
    public virtual ICollection<WalletTransaction> WalletTransactions { get; set; } = new List<WalletTransaction>();
}
