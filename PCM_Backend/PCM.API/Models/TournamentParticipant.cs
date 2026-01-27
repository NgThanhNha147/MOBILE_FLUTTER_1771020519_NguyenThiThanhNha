using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_TournamentParticipants")]
public class TournamentParticipant
{
    [Key]
    public int Id { get; set; }
    
    public int TournamentId { get; set; }
    
    public int MemberId { get; set; }
    
    [MaxLength(200)]
    public string? TeamName { get; set; }
    
    public TransactionStatus PaymentStatus { get; set; } = TransactionStatus.Pending;
    
    public DateTime RegisteredDate { get; set; } = DateTime.Now;
    
    // Navigation
    [ForeignKey(nameof(TournamentId))]
    public virtual Tournament Tournament { get; set; } = null!;
    
    [ForeignKey(nameof(MemberId))]
    public virtual Member Member { get; set; } = null!;
}
