using Microsoft.EntityFrameworkCore;
using PCM.API.Data;
using PCM.API.Models;
using Microsoft.AspNetCore.SignalR;
using PCM.API.Hubs;

namespace PCM.API.Services;

public class BookingHoldCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<BookingHoldCleanupService> _logger;
    private readonly TimeSpan _interval = TimeSpan.FromMinutes(1); // Run every 1 minute
    private readonly TimeSpan _holdTimeout = TimeSpan.FromMinutes(5); // 5 minutes hold time

    public BookingHoldCleanupService(
        IServiceProvider serviceProvider,
        ILogger<BookingHoldCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Booking Hold Cleanup Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await ProcessExpiredHoldingsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing expired hold bookings");
            }

            await Task.Delay(_interval, stoppingToken);
        }

        _logger.LogInformation("Booking Hold Cleanup Service stopped");
    }

    private async Task ProcessExpiredHoldingsAsync()
    {
        using var scope = _serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var hubContext = scope.ServiceProvider.GetRequiredService<IHubContext<PcmHub>>();

        var now = DateTime.Now;

        // Find all holding bookings where HoldExpiresAt has passed
        var expiredHoldings = await context.Bookings
            .Include(b => b.Member)
            .Include(b => b.Court)
            .Where(b => b.Status == BookingStatus.Holding 
                && b.HoldExpiresAt.HasValue 
                && b.HoldExpiresAt.Value < now)
            .ToListAsync();

        if (expiredHoldings.Any())
        {
            _logger.LogInformation($"Found {expiredHoldings.Count} expired holding bookings to cancel");

            foreach (var booking in expiredHoldings)
            {
                // Cancel the booking
                booking.Status = BookingStatus.Cancelled;

                // Create notification for user
                var notification = new Notification
                {
                    ReceiverId = booking.MemberId,
                    Message = $"Booking {booking.Court.Name} đã bị hủy do không xác nhận trong 5 phút",
                    Type = "Warning",
                    CreatedDate = DateTime.Now
                };
                context.Notifications.Add(notification);

                _logger.LogInformation($"Cancelled expired holding booking ID: {booking.Id}");

                // Notify user via SignalR
                try
                {
                    await hubContext.Clients.User(booking.Member.UserId)
                        .SendAsync("ReceiveNotification", notification.Message);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, $"Failed to send SignalR notification to user {booking.Member.UserId}");
                }
            }

            await context.SaveChangesAsync();

            // Broadcast calendar update to all clients
            await hubContext.Clients.All.SendAsync("UpdateCalendar");

            _logger.LogInformation($"Successfully cancelled {expiredHoldings.Count} expired holding bookings");
        }
    }
}
