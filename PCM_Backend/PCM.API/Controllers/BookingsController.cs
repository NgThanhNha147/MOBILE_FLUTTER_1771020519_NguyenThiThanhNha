using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using System.Data;
using PCM.API.Data;
using PCM.API.DTOs;
using PCM.API.Models;
using PCM.API.Hubs;
using PCM.API.Exceptions;

namespace PCM.API.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;
    
    public BookingsController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }
    
    [HttpGet("calendar")]
    public async Task<ActionResult> GetCalendar([FromQuery] DateTime from, [FromQuery] DateTime to)
    {
        var bookings = await _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.StartTime >= from && b.StartTime <= to)
            .Where(b => b.Status != BookingStatus.Cancelled)
            .Select(b => new
            {
                b.Id,
                b.CourtId,
                courtName = b.Court.Name,
                b.MemberId,
                memberName = b.Member.FullName,
                b.StartTime,
                b.EndTime,
                b.Status,
                b.TotalPrice
            })
            .ToListAsync();
        
        return Ok(bookings);
    }
    
    [HttpPost]
    public async Task<ActionResult> CreateBooking([FromBody] CreateBookingDto dto)
    {
        // ====== VALIDATE INPUT FIRST ======
        if (dto.StartTime < DateTime.Now)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Không thể đặt sân trong quá khứ", 
                "INVALID_START_TIME"));
        
        if (dto.EndTime <= dto.StartTime)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Giờ kết thúc phải sau giờ bắt đầu", 
                "INVALID_TIME_RANGE"));
        
        var hours = (dto.EndTime - dto.StartTime).TotalHours;
        if (hours > 5)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Không thể đặt quá 5 giờ liên tục", 
                "BOOKING_TOO_LONG"));
        
        if (hours < 1)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Phải đặt tối thiểu 1 giờ", 
                "BOOKING_TOO_SHORT"));
        
        // ====== GET USER ======
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Chỉ thành viên mới có thể đặt sân. Vui lòng đăng ký thành viên!", 
                "NOT_MEMBER"));
        
        // ====== CHECK COURT ======
        var court = await _context.Courts.FindAsync(dto.CourtId);
        if (court == null)
            return NotFound(ApiResponse<object>.ErrorResponse(
                "Không tìm thấy sân", 
                "COURT_NOT_FOUND"));
            
        if (!court.IsActive)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Sân đang bảo trì. Vui lòng chọn sân khác!", 
                "COURT_INACTIVE"));
        
        // ====== CALCULATE PRICE ======
        var totalPrice = (decimal)hours * court.PricePerHour;
        
        // ====== CHECK BALANCE ======
        if (member.WalletBalance < totalPrice)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                $"Ví không đủ tiền. Cần {totalPrice:N0}đ, còn {member.WalletBalance:N0}đ. Vui lòng nạp thêm!", 
                "INSUFFICIENT_BALANCE"));
        
        // ====== START TRANSACTION ======
        using var transaction = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        
        try
        {
            // Check overlap INSIDE transaction
            var hasOverlap = await _context.Bookings
                .Where(b => b.CourtId == dto.CourtId 
                    && b.Status != BookingStatus.Cancelled
                    && b.StartTime < dto.EndTime 
                    && b.EndTime > dto.StartTime)
                .AnyAsync();
            
            if (hasOverlap)
            {
                await transaction.RollbackAsync();
                return Conflict(ApiResponse<object>.ErrorResponse(
                    "Khung giờ này đã có người đặt. Vui lòng chọn giờ khác!", 
                    "TIME_SLOT_CONFLICT"));
            }
            
            // Create booking
            var booking = new Booking
            {
                CourtId = dto.CourtId,
                MemberId = member.Id,
                StartTime = dto.StartTime,
                EndTime = dto.EndTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                CreatedDate = DateTime.Now
            };
            _context.Bookings.Add(booking);
            
            // Deduct from wallet
            member.WalletBalance -= totalPrice;
            member.TotalSpent += totalPrice;
            
            // Update tier if needed
            if (member.TotalSpent > 8000000)
                member.Tier = MemberTier.Diamond;
            else if (member.TotalSpent > 5000000)
                member.Tier = MemberTier.Gold;
            else if (member.TotalSpent > 3000000)
                member.Tier = MemberTier.Silver;
            
            // Save booking first to get ID
            await _context.SaveChangesAsync();
            
            // Create wallet transaction with booking ID
            var walletTx = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = -totalPrice,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt sân {court.Name} từ {dto.StartTime:dd/MM/yyyy HH:mm} đến {dto.EndTime:HH:mm}",
                RelatedId = booking.Id.ToString()
            };
            _context.WalletTransactions.Add(walletTx);
            
            // Create notification
            var notification = new Notification
            {
                ReceiverId = member.Id,
                Message = $"Đặt sân thành công! {court.Name} - {dto.StartTime:dd/MM/yyyy HH:mm}",
                Type = "Success"
            };
            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            // Notify all clients about calendar update
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            
            // Send wallet balance update to booking user
            await _hubContext.Clients.User(member.UserId)
                .SendAsync("UpdateWallet", member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                "Đặt sân thành công!", 
                new { booking, newBalance = member.WalletBalance }));
        }
        catch (DbUpdateException dbEx)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi cơ sở dữ liệu. Vui lòng thử lại!", 
                "DATABASE_ERROR"));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi hệ thống không mong đợi. Vui lòng liên hệ admin!", 
                "INTERNAL_ERROR"));
        }
    }
    
    [HttpPost("cancel/{id}")]
    public async Task<ActionResult> CancelBooking(int id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        var isAdmin = User.IsInRole("Admin");
        
        if (member == null && !isAdmin)
            return Unauthorized(ApiResponse<object>.ErrorResponse(
                "Yêu cầu đăng nhập", 
                "UNAUTHORIZED"));
        
        var booking = await _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .FirstOrDefaultAsync(b => b.Id == id);
        
        if (booking == null)
            return NotFound(ApiResponse<object>.ErrorResponse(
                "Không tìm thấy booking", 
                "BOOKING_NOT_FOUND"));
        
        // Permission check: Owner or Admin
        if (!isAdmin && booking.MemberId != member?.Id)
            return Forbid();
        
        if (booking.Status == BookingStatus.Cancelled)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Booking đã được hủy trước đó", 
                "ALREADY_CANCELLED"));
        
        if (booking.Status == BookingStatus.Completed)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Không thể hủy booking đã hoàn thành", 
                "BOOKING_COMPLETED"));
        
        // Calculate refund based on time remaining
        var hoursUntilStart = (booking.StartTime - DateTime.Now).TotalHours;
        
        decimal refundPercentage;
        string refundReason;
        
        if (isAdmin)
        {
            // Admin can cancel anytime with full refund
            refundPercentage = 1.0m;
            refundReason = "Hủy bởi Admin - Hoàn 100%";
        }
        else
        {
            // User cancellation policy
            if (hoursUntilStart < 6)
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    "Không thể hủy trong vòng 6 giờ trước giờ chơi. Vui lòng liên hệ admin!", 
                    "CANCEL_TOO_LATE"));
            else if (hoursUntilStart < 24)
            {
                refundPercentage = 0.5m;
                refundReason = $"Hủy trong vòng {hoursUntilStart:F1}h - Hoàn 50%";
            }
            else
            {
                refundPercentage = 1.0m;
                refundReason = $"Hủy trước {hoursUntilStart:F1}h - Hoàn 100%";
            }
        }
        
        var refundAmount = booking.TotalPrice * refundPercentage;
        
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            booking.Status = BookingStatus.Cancelled;
            booking.Member.WalletBalance += refundAmount;
            
            // Create refund transaction
            var refundTx = new WalletTransaction
            {
                MemberId = booking.MemberId,
                Amount = refundAmount,
                Type = TransactionType.Refund,
                Status = TransactionStatus.Completed,
                Description = $"{refundReason} - {booking.Court.Name}",
                RelatedId = booking.Id.ToString()
            };
            _context.WalletTransactions.Add(refundTx);
            
            // Create notification
            var notification = new Notification
            {
                ReceiverId = booking.MemberId,
                Message = $"Hủy sân thành công. Hoàn {refundAmount:N0}đ ({refundPercentage * 100}%)",
                Type = "Info"
            };
            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            await _hubContext.Clients.User(booking.Member.UserId)
                .SendAsync("UpdateWallet", booking.Member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                $"Hủy sân thành công. Hoàn {refundAmount:N0}đ ({refundPercentage * 100}%)", 
                new { 
                    refundAmount, 
                    refundPercentage = refundPercentage * 100,
                    newBalance = booking.Member.WalletBalance 
                }));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi hệ thống khi hủy booking", 
                "CANCEL_FAILED"));
        }
    }
    
    [HttpGet("cancel-preview/{id}")]
    public async Task<ActionResult> GetCancelPreview(int id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        var isAdmin = User.IsInRole("Admin");
        
        if (member == null && !isAdmin)
            return Unauthorized();
        
        var booking = await _context.Bookings
            .Include(b => b.Court)
            .FirstOrDefaultAsync(b => b.Id == id);
        
        if (booking == null)
            return NotFound(ApiResponse<object>.ErrorResponse("Booking not found", "BOOKING_NOT_FOUND"));
        
        // Check ownership
        if (!isAdmin && booking.MemberId != member?.Id)
            return Forbid();
        
        var hoursUntilStart = (booking.StartTime - DateTime.Now).TotalHours;
        
        decimal refundPercentage;
        bool canCancel;
        string message;
        
        if (isAdmin)
        {
            canCancel = true;
            refundPercentage = 1.0m;
            message = $"Admin có thể hủy bất kỳ lúc nào - Hoàn 100% ({booking.TotalPrice:N0}đ)";
        }
        else if (hoursUntilStart < 6)
        {
            canCancel = false;
            refundPercentage = 0;
            message = "Không thể hủy trong vòng 6 giờ trước giờ chơi";
        }
        else if (hoursUntilStart < 24)
        {
            canCancel = true;
            refundPercentage = 0.5m;
            message = $"Hủy trong vòng 24h - Hoàn 50% ({booking.TotalPrice * 0.5m:N0}đ)";
        }
        else
        {
            canCancel = true;
            refundPercentage = 1.0m;
            message = $"Hủy trước 24h - Hoàn 100% ({booking.TotalPrice:N0}đ)";
        }
        
        return Ok(new CancelPreviewDto
        {
            CanCancel = canCancel,
            RefundPercentage = refundPercentage * 100,
            RefundAmount = booking.TotalPrice * refundPercentage,
            Message = message,
            HoursUntilStart = Math.Floor(hoursUntilStart)
        });
    }
    
    [HttpGet("my-bookings")]
    public async Task<ActionResult> GetMyBookings()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return NotFound();
        
        var bookings = await _context.Bookings
            .Include(b => b.Court)
            .Where(b => b.MemberId == member.Id)
            .OrderByDescending(b => b.StartTime)
            .Take(50)
            .ToListAsync();
        
        return Ok(bookings);
    }
    
    [HttpGet("slots")]
    public async Task<ActionResult> GetDailySlots([FromQuery] DateTime date, [FromQuery] int? courtId)
    {
        var startOfDay = date.Date;
        var endOfDay = date.Date.AddDays(1).AddSeconds(-1);
        
        var bookingsQuery = _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.StartTime >= startOfDay && b.StartTime <= endOfDay)
            .Where(b => b.Status != BookingStatus.Cancelled);
        
        if (courtId.HasValue)
            bookingsQuery = bookingsQuery.Where(b => b.CourtId == courtId.Value);
        
        var bookings = await bookingsQuery.ToListAsync();
        
        // Get all courts or specific court
        var courts = courtId.HasValue
            ? await _context.Courts.Where(c => c.Id == courtId.Value).ToListAsync()
            : await _context.Courts.Where(c => c.IsActive).ToListAsync();
        
        // Generate hourly slots (6am - 10pm = 16 hours)
        var slots = new List<TimeSlotDto>();
        
        foreach (var court in courts)
        {
            for (int hour = 6; hour < 22; hour++)
            {
                var slotStart = new DateTime(date.Year, date.Month, date.Day, hour, 0, 0);
                var slotEnd = slotStart.AddHours(1);
                
                var booking = bookings.FirstOrDefault(b => 
                    b.CourtId == court.Id &&
                    b.StartTime < slotEnd &&
                    b.EndTime > slotStart
                );
                
                slots.Add(new TimeSlotDto
                {
                    CourtId = court.Id,
                    CourtName = court.Name,
                    Hour = hour,
                    Time = $"{hour:D2}:00 - {(hour + 1):D2}:00",
                    IsBooked = booking != null,
                    BookingId = booking?.Id,
                    MemberId = booking?.MemberId,
                    MemberName = booking?.Member.FullName,
                    Status = booking?.Status.ToString()
                });
            }
        }
        
        return Ok(slots);
    }
    
    [HttpPut("edit/{id}")]
    public async Task<ActionResult> EditBooking(int id, [FromBody] EditBookingDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return Unauthorized();
        
        var booking = await _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .FirstOrDefaultAsync(b => b.Id == id && b.MemberId == member.Id);
        
        if (booking == null)
            return NotFound(ApiResponse<object>.ErrorResponse("Booking not found", "BOOKING_NOT_FOUND"));
        
        if (booking.Status == BookingStatus.Cancelled)
            return BadRequest(ApiResponse<object>.ErrorResponse("Cannot edit cancelled booking", "BOOKING_CANCELLED"));
        
        // Allow edit within 5 minutes of creation
        var minutesSinceCreation = (DateTime.Now - booking.CreatedDate).TotalMinutes;
        if (minutesSinceCreation > 5)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Chỉ có thể sửa trong vòng 5 phút sau khi đặt", 
                "EDIT_TIME_EXPIRED"));
        
        // Validate new times
        if (dto.NewStartTime < DateTime.Now)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Không thể đặt trong quá khứ", 
                "INVALID_START_TIME"));
        
        if (dto.NewEndTime <= dto.NewStartTime)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Giờ kết thúc phải sau giờ bắt đầu", 
                "INVALID_TIME_RANGE"));
        
        // Check new slot availability
        var hasOverlap = await _context.Bookings
            .Where(b => b.CourtId == booking.CourtId 
                && b.Id != id
                && b.Status != BookingStatus.Cancelled
                && b.StartTime < dto.NewEndTime 
                && b.EndTime > dto.NewStartTime)
            .AnyAsync();
        
        if (hasOverlap)
            return Conflict(ApiResponse<object>.ErrorResponse(
                "Khung giờ mới đã có người đặt", 
                "TIME_SLOT_CONFLICT"));
        
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            var oldPrice = booking.TotalPrice;
            var hours = (dto.NewEndTime - dto.NewStartTime).TotalHours;
            var newPrice = (decimal)hours * booking.Court.PricePerHour;
            var priceDiff = newPrice - oldPrice;
            
            // Refund or charge difference
            if (priceDiff != 0)
            {
                if (member.WalletBalance + oldPrice < newPrice)
                    return BadRequest(ApiResponse<object>.ErrorResponse(
                        $"Ví không đủ tiền. Cần thêm {priceDiff:N0}đ", 
                        "INSUFFICIENT_BALANCE"));
                
                member.WalletBalance -= priceDiff;
                
                var tx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -priceDiff,
                    Type = priceDiff > 0 ? TransactionType.Payment : TransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    Description = $"Điều chỉnh booking - {(priceDiff > 0 ? "Phụ thu" : "Hoàn")} {Math.Abs(priceDiff):N0}đ",
                    RelatedId = booking.Id.ToString()
                };
                _context.WalletTransactions.Add(tx);
            }
            
            booking.StartTime = dto.NewStartTime;
            booking.EndTime = dto.NewEndTime;
            booking.TotalPrice = newPrice;
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            await _hubContext.Clients.User(member.UserId)
                .SendAsync("UpdateWallet", member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                "Sửa booking thành công", 
                new { booking, newBalance = member.WalletBalance }));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi khi sửa booking", 
                "EDIT_FAILED"));
        }
    }
    
    [HttpPost("reschedule/{id}")]
    public async Task<ActionResult> RescheduleBooking(int id, [FromBody] RescheduleBookingDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return Unauthorized();
        
        var booking = await _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .FirstOrDefaultAsync(b => b.Id == id && b.MemberId == member.Id);
        
        if (booking == null)
            return NotFound(ApiResponse<object>.ErrorResponse("Booking not found", "BOOKING_NOT_FOUND"));
        
        if (booking.Status == BookingStatus.Cancelled)
            return BadRequest(ApiResponse<object>.ErrorResponse("Cannot reschedule cancelled booking", "BOOKING_CANCELLED"));
        
        // Check time until booking (must be > 24h)
        var hoursUntilStart = (booking.StartTime - DateTime.Now).TotalHours;
        if (hoursUntilStart < 24)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Chỉ có thể đổi lịch trước 24h. Để đổi gần hơn, vui lòng liên hệ admin!", 
                "RESCHEDULE_TOO_LATE"));
        
        // Validate new times
        if (dto.NewStartTime < DateTime.Now)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Không thể đặt trong quá khứ", 
                "INVALID_START_TIME"));
        
        if (dto.NewEndTime <= dto.NewStartTime)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Giờ kết thúc phải sau giờ bắt đầu", 
                "INVALID_TIME_RANGE"));
        
        // Check new slot availability
        var hasOverlap = await _context.Bookings
            .Where(b => b.CourtId == booking.CourtId 
                && b.Id != id
                && b.Status != BookingStatus.Cancelled
                && b.StartTime < dto.NewEndTime 
                && b.EndTime > dto.NewStartTime)
            .AnyAsync();
        
        if (hasOverlap)
            return Conflict(ApiResponse<object>.ErrorResponse(
                "Khung giờ mới đã có người đặt", 
                "TIME_SLOT_CONFLICT"));
        
        using var transaction = await _context.Database.BeginTransactionAsync();
        
        try
        {
            var oldPrice = booking.TotalPrice;
            var hours = (dto.NewEndTime - dto.NewStartTime).TotalHours;
            var newPrice = (decimal)hours * booking.Court.PricePerHour;
            
            // Calculate admin fee (10% of original price)
            var adminFee = oldPrice * 0.1m;
            var priceDiff = newPrice - oldPrice + adminFee;
            
            // Check balance
            if (member.WalletBalance < priceDiff)
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    $"Ví không đủ tiền. Cần {priceDiff:N0}đ (giá mới + phí admin 10%)", 
                    "INSUFFICIENT_BALANCE"));
            
            member.WalletBalance -= priceDiff;
            
            // Create admin fee transaction
            if (adminFee > 0)
            {
                var feeTx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -adminFee,
                    Type = TransactionType.Payment,
                    Status = TransactionStatus.Completed,
                    Description = $"Phí đổi lịch (10%) - {booking.Court.Name}",
                    RelatedId = booking.Id.ToString()
                };
                _context.WalletTransactions.Add(feeTx);
            }
            
            // Create price diff transaction if any
            var netPriceDiff = newPrice - oldPrice;
            if (netPriceDiff != 0)
            {
                var tx = new WalletTransaction
                {
                    MemberId = member.Id,
                    Amount = -netPriceDiff,
                    Type = netPriceDiff > 0 ? TransactionType.Payment : TransactionType.Refund,
                    Status = TransactionStatus.Completed,
                    Description = $"Điều chỉnh giá đổi lịch - {(netPriceDiff > 0 ? "Phụ thu" : "Hoàn")} {Math.Abs(netPriceDiff):N0}đ",
                    RelatedId = booking.Id.ToString()
                };
                _context.WalletTransactions.Add(tx);
            }
            
            booking.StartTime = dto.NewStartTime;
            booking.EndTime = dto.NewEndTime;
            booking.TotalPrice = newPrice;
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            await _hubContext.Clients.User(member.UserId)
                .SendAsync("UpdateWallet", member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                $"Đổi lịch thành công. Phí admin: {adminFee:N0}đ", 
                new { booking, adminFee, newBalance = member.WalletBalance }));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi khi đổi lịch", 
                "RESCHEDULE_FAILED"));
        }
    }
    
    [HttpPost("hold")]
    public async Task<ActionResult> HoldBooking([FromBody] HoldBookingDto dto)
    {
        // ====== VALIDATE INPUT ======
        if (dto.StartTime < DateTime.Now)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Không thể giữ chỗ trong quá khứ", 
                "INVALID_START_TIME"));
        
        if (dto.EndTime <= dto.StartTime)
            return UnprocessableEntity(ApiResponse<object>.ErrorResponse(
                "Giờ kết thúc phải sau giờ bắt đầu", 
                "INVALID_TIME_RANGE"));
        
        var hours = (dto.EndTime - dto.StartTime).TotalHours;
        if (hours > 5)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Không thể đặt quá 5 giờ liên tục", 
                "BOOKING_TOO_LONG"));
        
        if (hours < 1)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Phải đặt tối thiểu 1 giờ", 
                "BOOKING_TOO_SHORT"));
        
        // ====== GET USER ======
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Chỉ thành viên mới có thể đặt sân. Vui lòng đăng ký thành viên!", 
                "NOT_MEMBER"));
        
        // ====== CHECK COURT ======
        var court = await _context.Courts.FindAsync(dto.CourtId);
        if (court == null)
            return NotFound(ApiResponse<object>.ErrorResponse(
                "Không tìm thấy sân", 
                "COURT_NOT_FOUND"));
            
        if (!court.IsActive)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Sân đang bảo trì. Vui lòng chọn sân khác!", 
                "COURT_INACTIVE"));
        
        // ====== CALCULATE PRICE ======
        var totalPrice = (decimal)hours * court.PricePerHour;
        
        // ====== PRE-CHECK BALANCE ======
        if (member.WalletBalance < totalPrice)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                $"Ví không đủ tiền. Cần {totalPrice:N0}đ, còn {member.WalletBalance:N0}đ. Vui lòng nạp thêm!", 
                "INSUFFICIENT_BALANCE"));
        
        // ====== START TRANSACTION ======
        using var transaction = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        
        try
        {
            // Check overlap INSIDE transaction
            var hasOverlap = await _context.Bookings
                .Where(b => b.CourtId == dto.CourtId 
                    && (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Holding)
                    && b.StartTime < dto.EndTime 
                    && b.EndTime > dto.StartTime)
                .AnyAsync();
            
            if (hasOverlap)
            {
                await transaction.RollbackAsync();
                return Conflict(ApiResponse<object>.ErrorResponse(
                    "Khung giờ này đã có người đặt hoặc đang được giữ. Vui lòng chọn giờ khác!", 
                    "TIME_SLOT_CONFLICT"));
            }
            
            // Create holding booking (NO PAYMENT YET)
            var holdExpiresAt = DateTime.Now.AddMinutes(5);
            var booking = new Booking
            {
                CourtId = dto.CourtId,
                MemberId = member.Id,
                StartTime = dto.StartTime,
                EndTime = dto.EndTime,
                TotalPrice = totalPrice,
                Status = BookingStatus.Holding,
                CreatedDate = DateTime.Now,
                HoldExpiresAt = holdExpiresAt
            };
            _context.Bookings.Add(booking);
            
            // Create notification
            var notification = new Notification
            {
                ReceiverId = member.Id,
                Message = $"Đang giữ chỗ {court.Name} - {dto.StartTime:dd/MM/yyyy HH:mm}. Vui lòng xác nhận trong 5 phút!",
                Type = "Info"
            };
            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            // Notify calendar update
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            
            var secondsRemaining = (int)(holdExpiresAt - DateTime.Now).TotalSeconds;
            
            return Ok(ApiResponse<HoldResponseDto>.SuccessResponse(
                "Giữ chỗ thành công! Vui lòng xác nhận trong 5 phút.",
                new HoldResponseDto
                {
                    BookingId = booking.Id,
                    ExpiresAt = holdExpiresAt,
                    TotalPrice = totalPrice,
                    SecondsRemaining = secondsRemaining
                }));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi khi giữ chỗ. Vui lòng thử lại!", 
                "HOLD_FAILED"));
        }
    }
    
    [HttpPost("confirm/{id}")]
    public async Task<ActionResult> ConfirmBooking(int id)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Yêu cầu đăng nhập", 
                "NOT_MEMBER"));
        
        using var transaction = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        
        try
        {
            var booking = await _context.Bookings
                .Include(b => b.Court)
                .FirstOrDefaultAsync(b => b.Id == id);
            
            if (booking == null)
                return NotFound(ApiResponse<object>.ErrorResponse(
                    "Không tìm thấy booking", 
                    "BOOKING_NOT_FOUND"));
            
            // Check ownership
            if (booking.MemberId != member.Id)
                return Forbid();
            
            // Check status
            if (booking.Status != BookingStatus.Holding)
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    "Chỉ có thể xác nhận booking đang giữ chỗ", 
                    "INVALID_STATUS"));
            
            // Check expiration
            if (booking.HoldExpiresAt.HasValue && DateTime.Now > booking.HoldExpiresAt.Value)
            {
                booking.Status = BookingStatus.Cancelled;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    "Hết thời gian giữ chỗ (5 phút). Vui lòng đặt lại!", 
                    "HOLD_EXPIRED"));
            }
            
            // Check balance AGAIN (user might have spent money during hold)
            if (member.WalletBalance < booking.TotalPrice)
            {
                booking.Status = BookingStatus.Cancelled;
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                
                return BadRequest(ApiResponse<object>.ErrorResponse(
                    $"Ví không đủ tiền. Cần {booking.TotalPrice:N0}đ, còn {member.WalletBalance:N0}đ. Vui lòng nạp thêm!", 
                    "INSUFFICIENT_BALANCE"));
            }
            
            // Deduct wallet
            member.WalletBalance -= booking.TotalPrice;
            member.TotalSpent += booking.TotalPrice;
            
            // Update tier
            if (member.TotalSpent > 8000000)
                member.Tier = MemberTier.Diamond;
            else if (member.TotalSpent > 5000000)
                member.Tier = MemberTier.Gold;
            else if (member.TotalSpent > 3000000)
                member.Tier = MemberTier.Silver;
            
            // Confirm booking
            booking.Status = BookingStatus.Confirmed;
            booking.HoldExpiresAt = null;
            
            // Create wallet transaction
            var walletTx = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = -booking.TotalPrice,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt sân {booking.Court.Name} từ {booking.StartTime:dd/MM/yyyy HH:mm} đến {booking.EndTime:HH:mm}",
                RelatedId = booking.Id.ToString()
            };
            _context.WalletTransactions.Add(walletTx);
            
            // Create notification
            var notification = new Notification
            {
                ReceiverId = member.Id,
                Message = $"Xác nhận đặt sân thành công! {booking.Court.Name} - {booking.StartTime:dd/MM/yyyy HH:mm}",
                Type = "Success"
            };
            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            // Notify updates
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            await _hubContext.Clients.User(member.UserId)
                .SendAsync("UpdateWallet", member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                "Xác nhận đặt sân thành công!", 
                new { booking, newBalance = member.WalletBalance, newTier = member.Tier }));
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi khi xác nhận booking. Vui lòng thử lại!", 
                "CONFIRM_FAILED"));
        }
    }
    
    [HttpPost("recurring")]
    public async Task<ActionResult> CreateRecurringBooking([FromBody] RecurringBookingDto dto)
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var member = await _context.Members
            .FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Chỉ thành viên mới có thể đặt sân", 
                "NOT_MEMBER"));
        
        // Check VIP tier (Gold or Diamond only)
        if (member.Tier != MemberTier.Gold && member.Tier != MemberTier.Diamond)
            return StatusCode(403, ApiResponse<object>.ErrorResponse(
                "Chỉ thành viên VIP (Gold/Diamond) mới được đặt lịch định kỳ!", 
                "VIP_REQUIRED"));
        
        // Validate dates
        if (dto.StartDate < DateTime.Now.Date)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Ngày bắt đầu không thể trong quá khứ", 
                "INVALID_START_DATE"));
        
        if (dto.EndDate <= dto.StartDate)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Ngày kết thúc phải sau ngày bắt đầu", 
                "INVALID_END_DATE"));
        
        // Validate court
        var court = await _context.Courts.FindAsync(dto.CourtId);
        if (court == null)
            return NotFound(ApiResponse<object>.ErrorResponse(
                "Không tìm thấy sân", 
                "COURT_NOT_FOUND"));
        
        if (!court.IsActive)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Sân đang bảo trì", 
                "COURT_INACTIVE"));
        
        // Parse recurrence pattern (e.g., "Weekly;Mon,Wed,Fri")
        var parts = dto.RecurrencePattern.Split(';');
        if (parts.Length != 2)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Định dạng RecurrencePattern không hợp lệ. VD: 'Weekly;Mon,Wed,Fri'", 
                "INVALID_PATTERN"));
        
        var frequency = parts[0]; // "Weekly" or "Daily"
        var daysStr = parts[1]; // "Mon,Wed,Fri"
        
        if (frequency != "Weekly")
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Hiện chỉ hỗ trợ Weekly recurrence", 
                "UNSUPPORTED_FREQUENCY"));
        
        // Parse day of week
        var dayNames = daysStr.Split(',');
        var targetDays = new List<DayOfWeek>();
        
        foreach (var dayName in dayNames)
        {
            switch (dayName.Trim())
            {
                case "Mon": targetDays.Add(DayOfWeek.Monday); break;
                case "Tue": targetDays.Add(DayOfWeek.Tuesday); break;
                case "Wed": targetDays.Add(DayOfWeek.Wednesday); break;
                case "Thu": targetDays.Add(DayOfWeek.Thursday); break;
                case "Fri": targetDays.Add(DayOfWeek.Friday); break;
                case "Sat": targetDays.Add(DayOfWeek.Saturday); break;
                case "Sun": targetDays.Add(DayOfWeek.Sunday); break;
                default:
                    return BadRequest(ApiResponse<object>.ErrorResponse(
                        $"Tên ngày không hợp lệ: {dayName}", 
                        "INVALID_DAY_NAME"));
            }
        }
        
        // Generate all booking slots
        var bookingSlots = new List<(DateTime start, DateTime end)>();
        var currentDate = dto.StartDate;
        
        while (currentDate <= dto.EndDate && bookingSlots.Count < dto.OccurrencesCount)
        {
            if (targetDays.Contains(currentDate.DayOfWeek))
            {
                var startTime = new DateTime(
                    currentDate.Year,
                    currentDate.Month,
                    currentDate.Day,
                    dto.StartTime.Hour,
                    dto.StartTime.Minute,
                    0
                );
                var endTime = new DateTime(
                    currentDate.Year,
                    currentDate.Month,
                    currentDate.Day,
                    dto.EndTime.Hour,
                    dto.EndTime.Minute,
                    0
                );
                
                bookingSlots.Add((startTime, endTime));
            }
            currentDate = currentDate.AddDays(1);
        }
        
        if (bookingSlots.Count == 0)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                "Không tạo được slot nào với quy tắc này", 
                "NO_SLOTS_GENERATED"));
        
        // Calculate total price
        var hoursPerSlot = (dto.EndTime.ToTimeSpan() - dto.StartTime.ToTimeSpan()).TotalHours;
        var pricePerSlot = (decimal)hoursPerSlot * court.PricePerHour;
        var totalPrice = pricePerSlot * bookingSlots.Count;
        
        // Check balance
        if (member.WalletBalance < totalPrice)
            return BadRequest(ApiResponse<object>.ErrorResponse(
                $"Ví không đủ tiền. Cần {totalPrice:N0}đ cho {bookingSlots.Count} slot, còn {member.WalletBalance:N0}đ", 
                "INSUFFICIENT_BALANCE"));
        
        // Start transaction
        using var transaction = await _context.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        
        try
        {
            // Check ALL slots for overlap
            foreach (var (start, end) in bookingSlots)
            {
                var hasOverlap = await _context.Bookings
                    .Where(b => b.CourtId == dto.CourtId
                        && (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Holding)
                        && b.StartTime < end
                        && b.EndTime > start)
                    .AnyAsync();
                
                if (hasOverlap)
                {
                    await transaction.RollbackAsync();
                    return Conflict(ApiResponse<object>.ErrorResponse(
                        $"Slot {start:dd/MM/yyyy HH:mm} - {end:HH:mm} đã có người đặt. Không thể tạo lịch định kỳ!", 
                        "TIME_SLOT_CONFLICT"));
                }
            }
            
            // Create parent booking (virtual)
            var parentBooking = new Booking
            {
                CourtId = dto.CourtId,
                MemberId = member.Id,
                StartTime = bookingSlots[0].start,
                EndTime = bookingSlots[^1].end,
                TotalPrice = totalPrice,
                Status = BookingStatus.Confirmed,
                IsRecurring = true,
                RecurrenceRule = dto.RecurrencePattern,
                CreatedDate = DateTime.Now
            };
            _context.Bookings.Add(parentBooking);
            await _context.SaveChangesAsync(); // Save to get parent ID
            
            // Create all child bookings
            foreach (var (start, end) in bookingSlots)
            {
                var childBooking = new Booking
                {
                    CourtId = dto.CourtId,
                    MemberId = member.Id,
                    StartTime = start,
                    EndTime = end,
                    TotalPrice = pricePerSlot,
                    Status = BookingStatus.Confirmed,
                    IsRecurring = false,
                    ParentBookingId = parentBooking.Id,
                    CreatedDate = DateTime.Now
                };
                _context.Bookings.Add(childBooking);
            }
            
            // Deduct wallet
            member.WalletBalance -= totalPrice;
            member.TotalSpent += totalPrice;
            
            // Update tier
            if (member.TotalSpent > 8000000)
                member.Tier = MemberTier.Diamond;
            else if (member.TotalSpent > 5000000)
                member.Tier = MemberTier.Gold;
            
            // Create transaction
            var walletTx = new WalletTransaction
            {
                MemberId = member.Id,
                Amount = -totalPrice,
                Type = TransactionType.Payment,
                Status = TransactionStatus.Completed,
                Description = $"Đặt lịch định kỳ {court.Name} - {bookingSlots.Count} buổi",
                RelatedId = parentBooking.Id.ToString()
            };
            _context.WalletTransactions.Add(walletTx);
            
            // Notification
            var notification = new Notification
            {
                ReceiverId = member.Id,
                Message = $"Đặt lịch định kỳ thành công! {bookingSlots.Count} buổi tại {court.Name}",
                Type = "Success"
            };
            _context.Notifications.Add(notification);
            
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            
            // Notify
            await _hubContext.Clients.All.SendAsync("UpdateCalendar");
            await _hubContext.Clients.User(member.UserId)
                .SendAsync("UpdateWallet", member.WalletBalance);
            
            return Ok(ApiResponse<object>.SuccessResponse(
                $"Đặt lịch định kỳ thành công! {bookingSlots.Count} buổi", 
                new 
                { 
                    parentBookingId = parentBooking.Id,
                    totalSlots = bookingSlots.Count,
                    totalPrice,
                    newBalance = member.WalletBalance
                }));
        }
        catch (Exception)
        {
            await transaction.RollbackAsync();
            return StatusCode(500, ApiResponse<object>.ErrorResponse(
                "Lỗi khi tạo lịch định kỳ", 
                "RECURRING_FAILED"));
        }
    }
}

