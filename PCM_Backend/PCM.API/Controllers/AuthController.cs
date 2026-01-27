using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PCM.API.Data;
using PCM.API.DTOs;
using PCM.API.Models;
using PCM.API.Services;

namespace PCM.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly ITokenService _tokenService;
    private readonly ApplicationDbContext _context;
    
    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        ITokenService tokenService,
        ApplicationDbContext context)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _tokenService = tokenService;
        _context = context;
    }
    
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponseDto>> Login([FromBody] LoginDto dto)
    {
        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
            return Unauthorized(new { message = "Invalid credentials" });
        
        var result = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);
        if (!result.Succeeded)
            return Unauthorized(new { message = "Invalid credentials" });
        
        var roles = await _userManager.GetRolesAsync(user);
        var role = roles.FirstOrDefault() ?? "Member";
        
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == user.Id);
        
        var token = _tokenService.GenerateToken(user.Id, user.Email!, user.FullName ?? "", role);
        
        return Ok(new LoginResponseDto
        {
            Token = token,
            Email = user.Email!,
            FullName = user.FullName ?? "",
            Role = role,
            MemberId = member?.Id, // Nullable - admin doesn't have member
            WalletBalance = member?.WalletBalance ?? 0
        });
    }
    
    [HttpPost("register")]
    public async Task<ActionResult> Register([FromBody] RegisterDto dto)
    {
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
            return BadRequest(new { message = "Email already exists" });
        
        var user = new ApplicationUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FullName = dto.FullName,
            EmailConfirmed = true
        };
        
        var result = await _userManager.CreateAsync(user, dto.Password);
        if (!result.Succeeded)
            return BadRequest(result.Errors);
        
        await _userManager.AddToRoleAsync(user, "Member");
        
        // Create Member profile
        var member = new Member
        {
            FullName = dto.FullName,
            UserId = user.Id,
            WalletBalance = 0,
            Tier = MemberTier.Standard,
            AvatarUrl = $"https://ui-avatars.com/api/?name={Uri.EscapeDataString(dto.FullName)}"
        };
        _context.Members.Add(member);
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Registration successful" });
    }
    
    [Authorize]
    [HttpGet("me")]
    public async Task<ActionResult> GetCurrentUser()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (userId == null)
            return Unauthorized();
        
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
            return NotFound();
        
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        var roles = await _userManager.GetRolesAsync(user);
        
        return Ok(new
        {
            email = user.Email,
            fullName = user.FullName,
            role = roles.FirstOrDefault(),
            member = member
        });
    }
}
