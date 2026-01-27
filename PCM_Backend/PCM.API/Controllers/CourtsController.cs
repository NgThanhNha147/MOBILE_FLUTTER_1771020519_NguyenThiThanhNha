using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class CourtsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public CourtsController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public async Task<ActionResult> GetCourts()
    {
        var courts = await _context.Courts
            .Where(c => c.IsActive)
            .ToListAsync();
        
        return Ok(courts);
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult> GetCourt(int id)
    {
        var court = await _context.Courts.FindAsync(id);
        
        if (court == null)
            return NotFound();
        
        return Ok(court);
    }
}
