using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace PCM.API.Hubs;

public class CustomUserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
    {
        // Get User ID from JWT token NameIdentifier claim
        return connection.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    }
}
