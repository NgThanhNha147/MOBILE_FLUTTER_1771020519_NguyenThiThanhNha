using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NewsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public NewsController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public async Task<ActionResult> GetNews([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var query = _context.News
            .OrderByDescending(n => n.IsPinned)
            .ThenByDescending(n => n.CreatedDate);
        
        var total = await query.CountAsync();
        var news = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        
        return Ok(new
        {
            total,
            page,
            pageSize,
            data = news
        });
    }
    
    [HttpGet("{id}")]
    public async Task<ActionResult> GetNewsById(int id)
    {
        var news = await _context.News.FindAsync(id);
        
        if (news == null)
            return NotFound();
        
        return Ok(news);
    }
}
