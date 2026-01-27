using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PCM.API.Models;

[Table("519_Matches")]
public class Match
{
    [Key]
    public int Id { get; set; }
    
    public int? TournamentId { get; set; }
    
    [MaxLength(100)]
    public string RoundName { get; set; } = string.Empty;
    
    public DateTime Date { get; set; }
    
    public DateTime StartTime { get; set; }
    
    // Team 1
    public int Team1_Player1Id { get; set; }
    public int? Team1_Player2Id { get; set; }
    
    // Team 2
    public int Team2_Player1Id { get; set; }
    public int? Team2_Player2Id { get; set; }
    
    // Results
    public int? Score1 { get; set; }
    public int? Score2 { get; set; }
    
    [MaxLength(500)]
    public string? Details { get; set; } // JSON: "11-9, 5-11, 11-8"
    
    public WinningSide? WinningSide { get; set; }
    
    public bool IsRanked { get; set; } = true;
    
    public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
    
    // Navigation
    [ForeignKey(nameof(TournamentId))]
    public virtual Tournament? Tournament { get; set; }
}
