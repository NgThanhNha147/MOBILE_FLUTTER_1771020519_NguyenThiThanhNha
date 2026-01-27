using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using PCM.API.Data;
using PCM.API.DTOs;
using PCM.API.Models;
using PCM.API.Hubs;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class WalletController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;
    
    public WalletController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }
    
    [HttpPost("deposit")]
    public async Task<ActionResult> RequestDeposit([FromBody] DepositRequestDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return NotFound(new { message = "Member not found" });
        
        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = dto.Amount,
            Type = TransactionType.Deposit,
            Status = TransactionStatus.Pending,
            Description = $"Yêu cầu nạp tiền {dto.Amount:N0}đ",
            ProofImageUrl = dto.ProofImageUrl
        };
        
        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Deposit request created. Waiting for approval.", transaction });
    }
    
    [HttpGet("transactions")]
    public async Task<ActionResult> GetMyTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return NotFound();
        
        var query = _context.WalletTransactions
            .Where(t => t.MemberId == member.Id)
            .OrderByDescending(t => t.CreatedDate);
        
        var total = await query.CountAsync();
        var transactions = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
        
        return Ok(new
        {
            total,
            page,
            pageSize,
            data = transactions
        });
    }
    
    [Authorize(Roles = "Admin,Treasurer")]
    [HttpPut("approve/{transactionId}")]
    public async Task<ActionResult> ApproveDeposit(int transactionId, [FromBody] ApproveTransactionDto dto)
    {
        var transaction = await _context.WalletTransactions
            .Include(t => t.Member)
            .FirstOrDefaultAsync(t => t.Id == transactionId);
        
        if (transaction == null)
            return NotFound();
        
        if (transaction.Status != TransactionStatus.Pending)
            return BadRequest(new { message = "Transaction is not pending" });
        
        using var dbTransaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            if (dto.Approved)
            {
                transaction.Status = TransactionStatus.Completed;
                transaction.Member.WalletBalance += transaction.Amount;
                
                // Create notification
                var notification = new Notification
                {
                    ReceiverId = transaction.MemberId,
                    Message = $"Nạp tiền thành công {transaction.Amount:N0}đ vào ví",
                    Type = "Success"
                };
                _context.Notifications.Add(notification);
                
                // Send SignalR notification
                await _hubContext.Clients.User(transaction.Member.UserId)
                    .SendAsync("ReceiveNotification", notification.Message);
                
                // Send wallet balance update
                await _hubContext.Clients.User(transaction.Member.UserId)
                    .SendAsync("UpdateWallet", transaction.Member.WalletBalance);
            }
            else
            {
                transaction.Status = TransactionStatus.Rejected;
                
                var notification = new Notification
                {
                    ReceiverId = transaction.MemberId,
                    Message = $"Yêu cầu nạp tiền {transaction.Amount:N0}đ bị từ chối",
                    Type = "Warning"
                };
                _context.Notifications.Add(notification);
            }
            
            await _context.SaveChangesAsync();
            await dbTransaction.CommitAsync();
            
            return Ok(new { message = "Transaction processed successfully", transaction });
        }
        catch (Exception ex)
        {
            await dbTransaction.RollbackAsync();
            return StatusCode(500, new { message = "Error processing transaction", error = ex.Message });
        }
    }
    
    [Authorize(Roles = "Admin,Treasurer")]
    [HttpGet("pending-transactions")]
    public async Task<ActionResult> GetPendingTransactions()
    {
        var transactions = await _context.WalletTransactions
            .Include(t => t.Member)
            .Where(t => t.Status == TransactionStatus.Pending)
            .OrderByDescending(t => t.CreatedDate)
            .ToListAsync();
        
        return Ok(transactions);
    }
}
