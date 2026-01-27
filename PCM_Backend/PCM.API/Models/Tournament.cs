using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_Tournaments")]
public class Tournament
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    public DateTime StartDate { get; set; }
    
    public DateTime EndDate { get; set; }
    
    public TournamentFormat Format { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal EntryFee { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal PrizePool { get; set; }
    
    public TournamentStatus Status { get; set; } = TournamentStatus.Open;
    
    public string? Settings { get; set; } // JSON
    
    // Navigation
    public virtual ICollection<TournamentParticipant> Participants { get; set; } = new List<TournamentParticipant>();
    public virtual ICollection<Match> Matches { get; set; } = new List<Match>();
}
