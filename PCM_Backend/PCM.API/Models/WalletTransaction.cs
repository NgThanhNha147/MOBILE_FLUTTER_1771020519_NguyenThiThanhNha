using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_WalletTransactions")]
public class WalletTransaction
{
    [Key]
    public int Id { get; set; }
    
    public int MemberId { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    
    public TransactionType Type { get; set; }
    
    public TransactionStatus Status { get; set; } = TransactionStatus.Pending;
    
    [MaxLength(100)]
    public string? RelatedId { get; set; }
    
    [MaxLength(500)]
    public string Description { get; set; } = string.Empty;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    [MaxLength(500)]
    public string? ProofImageUrl { get; set; }
    
    // Navigation
    [ForeignKey(nameof(MemberId))]
    public virtual Member Member { get; set; } = null!;
}
