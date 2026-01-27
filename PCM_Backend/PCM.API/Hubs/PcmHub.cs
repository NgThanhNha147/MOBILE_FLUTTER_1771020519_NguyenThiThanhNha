using Microsoft.AspNetCore.SignalR;

namespace PCM.API.Hubs;

public class PcmHub : Hub
{
    public async Task SendNotification(int userId, string message)
    {
        await Clients.User(userId.ToString()).SendAsync("ReceiveNotification", message);
    }
    
    public async Task UpdateCalendar()
    {
        await Clients.All.SendAsync("UpdateCalendar");
    }
    
    public async Task UpdateMatchScore(int matchId, int score1, int score2)
    {
        await Clients.Group($"match_{matchId}").SendAsync("UpdateMatchScore", matchId, score1, score2);
    }
    
    public async Task JoinMatchGroup(int matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"match_{matchId}");
    }
    
    public async Task LeaveMatchGroup(int matchId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"match_{matchId}");
    }
}
