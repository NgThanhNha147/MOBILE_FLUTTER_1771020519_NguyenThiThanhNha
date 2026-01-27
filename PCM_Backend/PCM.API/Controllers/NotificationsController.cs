using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class NotificationsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    
    public NotificationsController(ApplicationDbContext context)
    {
        _context = context;
    }
    
    [HttpGet]
    public async Task<ActionResult> GetMyNotifications([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return NotFound();
        
        var query = _context.Notifications
            .Where(n => n.ReceiverId == member.Id)
            .OrderByDescending(n => n.CreatedDate);
        
        var total = await query.CountAsync();
        var unreadCount = await query.CountAsync(n => !n.IsRead);
        
        var notifications = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        
        return Ok(new
        {
            total,
            unreadCount,
            page,
            pageSize,
            data = notifications
        });
    }
    
    [HttpPut("{id}/mark-read")]
    public async Task<ActionResult> MarkAsRead(int id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return NotFound();
        
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.ReceiverId == member.Id);
        
        if (notification == null)
            return NotFound();
        
        notification.IsRead = true;
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Notification marked as read" });
    }
}
