using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public MembersController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public async Task<ActionResult> GetMembers([FromQuery] string? search, [FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var query = _context.Members.AsQueryable();
        
        if (!string.IsNullOrWhiteSpace(search))
        {
            query = query.Where(m => m.FullName.Contains(search));
        }
        
        var total = await query.CountAsync();
        var members = await query
            .OrderByDescending(m => m.RankLevel)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(m => new
            {
                m.Id,
                m.FullName,
                m.RankLevel,
                m.Tier,
                m.WalletBalance,
                m.AvatarUrl,
                m.JoinDate
            })
            .ToListAsync();
        
        return Ok(new
        {
            total,
            page,
            pageSize,
            data = members
        });
    }
    
    [HttpGet("{id}/profile")]
    public async Task<ActionResult> GetMemberProfile(int id)
    {
        var member = await _context.Members
            .Include(m => m.Bookings.Take(10))
            .FirstOrDefaultAsync(m => m.Id == id);
        
        if (member == null)
            return NotFound();
        
        // Get match history
        var matches = await _context.Matches
            .Where(m => m.Team1_Player1Id == id || m.Team1_Player2Id == id 
                     || m.Team2_Player1Id == id || m.Team2_Player2Id == id)
            .Where(m => m.Status == Models.MatchStatus.Finished)
            .OrderByDescending(m => m.Date)
            .Take(10)
            .ToListAsync();
        
        return Ok(new
        {
            member,
            recentMatches = matches
        });
    }
}
