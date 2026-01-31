using System.ComponentModel.DataAnnotations;
using PCM.API.Models;

namespace PCM.API.DTOs;

// DTO for tournament list
public class TournamentDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Type { get; set; }  // 0=Official, 1=Challenge1v1, 2=TeamBattle, 3=MiniGame
    public int Format { get; set; }  // 0=RoundRobin, 1=Knockout, 2=Hybrid
    public int Status { get; set; }  // 0=Open, 1=Registering, 2=DrawCompleted, 3=Ongoing, 4=Finished
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int MaxParticipants { get; set; }
    public int CurrentParticipants { get; set; }
    public decimal EntryFee { get; set; }
    public decimal PrizePool { get; set; }
    public int? CreatorId { get; set; }
    public string CreatorName { get; set; } = string.Empty;
    public List<object> Participants { get; set; } = new();
}

// DTO for tournament detail
public class TournamentDetailDto : TournamentDto
{
    public List<object> Matches { get; set; } = new();
}

// DTO for creating tournament
public class CreateTournamentRequest
{
    [Required(ErrorMessage = "Tournament name is required")]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [MaxLength(500)]
    public string? Description { get; set; }
    
    [Required]
    public TournamentType Type { get; set; }  // Must be Challenge1v1 or TeamBattle
    
    [Required]
    public TournamentFormat Format { get; set; }
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    [Range(2, 32, ErrorMessage = "Max participants must be between 2 and 32")]
    public int MaxParticipants { get; set; }
    
    [Range(0, double.MaxValue, ErrorMessage = "Entry fee must be non-negative")]
    public decimal EntryFee { get; set; }
}
