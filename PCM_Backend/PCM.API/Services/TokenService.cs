using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace PCM.API.Services;

public interface ITokenService
{
    string GenerateToken(string userId, string email, string fullName, string role);
}

public class TokenService : ITokenService
{
    private readonly IConfiguration _configuration;
    
    public TokenService(IConfiguration configuration)
    {
        _configuration = configuration;
    }
    
    public string GenerateToken(string userId, string email, string fullName, string role)
    {
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, userId),
            new Claim(ClaimTypes.Email, email),
            new Claim(ClaimTypes.Name, fullName),
            new Claim(ClaimTypes.Role, role),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };
        
        var jwtKey = _configuration["Jwt:Key"]
            ?? throw new InvalidOperationException("Jwt:Key is not configured.");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        
        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "PCM_API",
            audience: _configuration["Jwt:Audience"] ?? "PCM_Mobile",
            claims: claims,
            expires: DateTime.Now.AddDays(30),
            signingCredentials: creds
        );
        
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
