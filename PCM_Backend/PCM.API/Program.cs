using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using PCM.API.Data;
using PCM.API.Hubs;
using PCM.API.Models;
using PCM.API.Services;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add DbContext with MySQL
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "server=localhost;port=3306;database=pcm_db;user=root;password=;";

builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseMySql(connectionString, ServerVersion.AutoDetect(connectionString)));

// Add Identity
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = false;
    options.Password.RequiredLength = 6;
})
.AddEntityFrameworkStores<ApplicationDbContext>()
.AddDefaultTokenProviders();

// Add JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? "YourSuperSecretKeyThatIsAtLeast32CharactersLong519";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "PCM_API";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "PCM_Mobile";

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey))
    };
});

// Add CORS - SignalR requires AllowCredentials
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", builder =>
    {
        builder.SetIsOriginAllowed(origin =>
               {
                   // Allow localhost, 10.0.2.2 (Android emulator), and 127.0.0.1 with any port
                   var uri = new Uri(origin);
                   return uri.Host == "localhost" || 
                          uri.Host == "10.0.2.2" || 
                          uri.Host == "127.0.0.1";
               })
               .AllowAnyMethod()
               .AllowAnyHeader()
               .AllowCredentials(); // Required for SignalR
    });
});

// Add SignalR
builder.Services.AddSignalR();

// Configure SignalR to use JWT claim for User ID
builder.Services.AddSingleton<IUserIdProvider, CustomUserIdProvider>();

// Add Background Services
builder.Services.AddHostedService<BookingHoldCleanupService>();

// Add Controllers
builder.Services.AddControllers();

// Add Services
builder.Services.AddScoped<ITokenService, TokenService>();

// Add Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Seed Data
using (var scope = app.Services.CreateScope())
{
    var services = scope.ServiceProvider;
    try
    {
        var context = services.GetRequiredService<ApplicationDbContext>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        
        await context.Database.MigrateAsync();
        await DataSeeder.SeedAsync(context, userManager, roleManager);
    }
    catch (Exception ex)
    {
        var logger = services.GetRequiredService<ILogger<Program>>();
        logger.LogError(ex, "An error occurred while seeding the database.");
    }
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<PcmHub>("/pcmhub").RequireCors("AllowAll"); // Apply CORS to SignalR hub

app.Run();
