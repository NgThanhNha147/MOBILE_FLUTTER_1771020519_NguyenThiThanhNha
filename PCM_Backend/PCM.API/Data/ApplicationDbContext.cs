using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PCM.API.Models;

namespace PCM.API.Data;

public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }
    
    public DbSet<Member> Members { get; set; }
    public DbSet<WalletTransaction> WalletTransactions { get; set; }
    public DbSet<News> News { get; set; }
    public DbSet<Court> Courts { get; set; }
    public DbSet<Booking> Bookings { get; set; }
    public DbSet<Tournament> Tournaments { get; set; }
    public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
    public DbSet<Match> Matches { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        
        // Configure relationships and constraints
        modelBuilder.Entity<Member>()
            .HasIndex(m => m.UserId)
            .IsUnique();
            
        modelBuilder.Entity<Booking>()
            .HasOne(b => b.Court)
            .WithMany(c => c.Bookings)
            .OnDelete(DeleteBehavior.Restrict);
            
        modelBuilder.Entity<Booking>()
            .HasOne(b => b.Member)
            .WithMany(m => m.Bookings)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
