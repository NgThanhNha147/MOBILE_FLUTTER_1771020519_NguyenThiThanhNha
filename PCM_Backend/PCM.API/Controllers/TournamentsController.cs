using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;
using PCM.API.DTOs;
using PCM.API.Models;

namespace PCM.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TournamentsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<TournamentsController> _logger;

    public TournamentsController(
        ApplicationDbContext context,
        ILogger<TournamentsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    // GET: api/tournaments
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<TournamentDto>>>> GetTournaments(
        [FromQuery] int? type = null,
        [FromQuery] int? status = null)
    {
        try
        {
            var query = _context.Tournaments
                .Include(t => t.Participants)
                .AsQueryable();

            // Filter by type
            if (type.HasValue && Enum.IsDefined(typeof(TournamentType), type.Value))
            {
                query = query.Where(t => (int)t.Type == type.Value);
            }

            // Filter by status
            if (status.HasValue && Enum.IsDefined(typeof(TournamentStatus), status.Value))
            {
                query = query.Where(t => (int)t.Status == status.Value);
            }

            var tournaments = await query
                .OrderByDescending(t => t.StartDate)
                .Select(t => new TournamentDto
                {
                    Id = t.Id,
                    Name = t.Name,
                    Description = t.Description,
                    Type = (int)t.Type,
                    Format = (int)t.Format,
                    Status = (int)t.Status,
                    StartDate = t.StartDate,
                    EndDate = t.EndDate,
                    MaxParticipants = t.MaxParticipants,
                    CurrentParticipants = t.Participants.Count,
                    EntryFee = t.EntryFee,
                    PrizePool = t.PrizePool,
                    CreatorId = t.CreatorId,
                    CreatorName = t.CreatorId.HasValue ? "User" : "Admin",
                    Participants = new List<object>()
                })
                .ToListAsync();

            return ApiResponse<List<TournamentDto>>.SuccessResponse(
                "Tournaments retrieved successfully",
                tournaments);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tournaments");
            return StatusCode(500, ApiResponse<List<TournamentDto>>.ErrorResponse(
                "Error getting tournaments",
                "GET_TOURNAMENTS_ERROR"));
        }
    }

    // GET: api/tournaments/{id}
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<TournamentDetailDto>>> GetTournament(int id)
    {
        try
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                .Include(t => t.Matches)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
            {
                return NotFound(ApiResponse<TournamentDetailDto>.ErrorResponse(
                    "Tournament not found",
                    "TOURNAMENT_NOT_FOUND"));
            }

            var dto = new TournamentDetailDto
            {
                Id = tournament.Id,
                Name = tournament.Name,
                Description = tournament.Description,
                Type = (int)tournament.Type,
                Format = (int)tournament.Format,
                Status = (int)tournament.Status,
                StartDate = tournament.StartDate,
                EndDate = tournament.EndDate,
                MaxParticipants = tournament.MaxParticipants,
                CurrentParticipants = tournament.Participants.Count,
                EntryFee = tournament.EntryFee,
                PrizePool = tournament.PrizePool,
                CreatorId = tournament.CreatorId,
                CreatorName = tournament.CreatorId.HasValue ? "User" : "Admin",
                Participants = new List<object>(),
                Matches = new List<object>()
            };

            return ApiResponse<TournamentDetailDto>.SuccessResponse(
                "Tournament retrieved successfully",
                dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting tournament {Id}", id);
            return StatusCode(500, ApiResponse<TournamentDetailDto>.ErrorResponse(
                "Error getting tournament",
                "GET_TOURNAMENT_ERROR"));
        }
    }

    // POST: api/tournaments
    [HttpPost]
    public async Task<ActionResult<ApiResponse<TournamentDto>>> CreateTournament(
        [FromBody] CreateTournamentRequest request)
    {
        try
        {
            // Validate tournament type - only Challenge1v1 and TeamBattle can be created by users
            if (request.Type != TournamentType.Challenge1v1 &&
                request.Type != TournamentType.TeamBattle)
            {
                return BadRequest(ApiResponse<TournamentDto>.ErrorResponse(
                    "Only Challenge1v1 and TeamBattle tournaments can be created by users",
                    "INVALID_TOURNAMENT_TYPE"));
            }

            // Validate dates
            if (request.EndDate <= request.StartDate)
            {
                return BadRequest(ApiResponse<TournamentDto>.ErrorResponse(
                    "End date must be after start date",
                    "INVALID_DATES"));
            }

            // Validate max participants
            if (request.Type == TournamentType.Challenge1v1 && request.MaxParticipants != 2)
            {
                return BadRequest(ApiResponse<TournamentDto>.ErrorResponse(
                    "Challenge 1v1 must have exactly 2 participants",
                    "INVALID_MAX_PARTICIPANTS"));
            }

            // Calculate prize pool (80% of total entry fees)
            var prizePool = request.EntryFee * request.MaxParticipants * 0.8m;

            var tournament = new Tournament
            {
                Name = request.Name,
                Description = request.Description,
                Type = request.Type,
                Format = request.Format,
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                MaxParticipants = request.MaxParticipants,
                EntryFee = request.EntryFee,
                PrizePool = prizePool,
                Status = TournamentStatus.Open,
                CreatorId = 1 // TODO: Get from authenticated user
            };

            _context.Tournaments.Add(tournament);
            await _context.SaveChangesAsync();

            var dto = new TournamentDto
            {
                Id = tournament.Id,
                Name = tournament.Name,
                Description = tournament.Description,
                Type = (int)tournament.Type,
                Format = (int)tournament.Format,
                Status = (int)tournament.Status,
                StartDate = tournament.StartDate,
                EndDate = tournament.EndDate,
                MaxParticipants = tournament.MaxParticipants,
                CurrentParticipants = 0,
                EntryFee = tournament.EntryFee,
                PrizePool = tournament.PrizePool,
                CreatorId = tournament.CreatorId,
                CreatorName = "User",
                Participants = new List<object>()
            };

            _logger.LogInformation("Tournament created: {TournamentId} - {TournamentName}", tournament.Id, tournament.Name);

            return CreatedAtAction(
                nameof(GetTournament),
                new { id = tournament.Id },
                ApiResponse<TournamentDto>.SuccessResponse("Tournament created successfully", dto));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating tournament");
            return StatusCode(500, ApiResponse<TournamentDto>.ErrorResponse(
                "Error creating tournament",
                "CREATE_TOURNAMENT_ERROR"));
        }
    }

    // POST: api/tournaments/{id}/join
    [HttpPost("{id}/join")]
    public async Task<ActionResult<ApiResponse<string>>> JoinTournament(int id)
    {
        try
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
            {
                return NotFound(ApiResponse<string>.ErrorResponse(
                    "Tournament not found",
                    "TOURNAMENT_NOT_FOUND"));
            }

            if (tournament.Status != TournamentStatus.Open)
            {
                return BadRequest(ApiResponse<string>.ErrorResponse(
                    "Tournament is not open for registration",
                    "TOURNAMENT_NOT_OPEN"));
            }

            if (tournament.Participants.Count >= tournament.MaxParticipants)
            {
                return BadRequest(ApiResponse<string>.ErrorResponse(
                    "Tournament is full",
                    "TOURNAMENT_FULL"));
            }

            // TODO: Check if user already joined
            // TODO: Add participant with real user ID from authentication
            // TODO: Handle payment if EntryFee > 0

            _logger.LogInformation("User joined tournament: {TournamentId}", id);

            return ApiResponse<string>.SuccessResponse(
                "Joined tournament successfully",
                "Success");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error joining tournament {Id}", id);
            return StatusCode(500, ApiResponse<string>.ErrorResponse(
                "Error joining tournament",
                "JOIN_TOURNAMENT_ERROR"));
        }
    }

    // DELETE: api/tournaments/{id}
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<string>>> DeleteTournament(int id)
    {
        try
        {
            var tournament = await _context.Tournaments
                .Include(t => t.Participants)
                .FirstOrDefaultAsync(t => t.Id == id);

            if (tournament == null)
            {
                return NotFound(ApiResponse<string>.ErrorResponse(
                    "Tournament not found",
                    "TOURNAMENT_NOT_FOUND"));
            }

            // Only allow deleting if no participants or creator owns it
            if (tournament.Participants.Any())
            {
                return BadRequest(ApiResponse<string>.ErrorResponse(
                    "Cannot delete tournament with participants",
                    "TOURNAMENT_HAS_PARTICIPANTS"));
            }

            // TODO: Check if current user is creator or admin

            _context.Tournaments.Remove(tournament);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Tournament deleted: {TournamentId}", id);

            return ApiResponse<string>.SuccessResponse(
                "Tournament deleted successfully",
                "Success");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting tournament {Id}", id);
            return StatusCode(500, ApiResponse<string>.ErrorResponse(
                "Error deleting tournament",
                "DELETE_TOURNAMENT_ERROR"));
        }
    }
}
