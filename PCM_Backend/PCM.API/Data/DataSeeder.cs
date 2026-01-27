using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PCM.API.Models;

namespace PCM.API.Data;

public static class DataSeeder
{
    public static async Task SeedAsync(ApplicationDbContext context, UserManager<ApplicationUser> userManager, RoleManager<IdentityRole> roleManager)
    {
        // Seed Roles
        string[] roleNames = { "Admin", "Treasurer", "Referee", "Member" };
        foreach (var roleName in roleNames)
        {
            if (!await roleManager.RoleExistsAsync(roleName))
            {
                await roleManager.CreateAsync(new IdentityRole(roleName));
            }
        }
        
        // Seed Admin User - Nguyễn Thị Thanh Nhã
        var adminUser = await userManager.FindByEmailAsync("admin@pcm.com");
        if (adminUser == null)
        {
            adminUser = new ApplicationUser
            {
                UserName = "admin@pcm.com",
                Email = "admin@pcm.com",
                FullName = "Nguyễn Thị Thanh Nhã",
                EmailConfirmed = true
            };
            await userManager.CreateAsync(adminUser, "Admin@123");
            await userManager.AddToRoleAsync(adminUser, "Admin");
            
            var adminMember = new Member
            {
                FullName = "Nguyễn Thị Thanh Nhã",
                UserId = adminUser.Id,
                WalletBalance = 10000000,
                Tier = MemberTier.Diamond,
                RankLevel = 2500,
                AvatarUrl = "https://ui-avatars.com/api/?name=Nguyen+Thi+Thanh+Nha"
            };
            context.Members.Add(adminMember);
        }
        
        // Seed Treasurer
        var treasurerUser = await userManager.FindByEmailAsync("treasurer@pcm.com");
        if (treasurerUser == null)
        {
            treasurerUser = new ApplicationUser
            {
                UserName = "treasurer@pcm.com",
                Email = "treasurer@pcm.com",
                FullName = "Trần Văn Tài",
                EmailConfirmed = true
            };
            await userManager.CreateAsync(treasurerUser, "Treasurer@123");
            await userManager.AddToRoleAsync(treasurerUser, "Treasurer");
            
            var treasurerMember = new Member
            {
                FullName = "Trần Văn Tài",
                UserId = treasurerUser.Id,
                WalletBalance = 5000000,
                Tier = MemberTier.Gold
            };
            context.Members.Add(treasurerMember);
        }
        
        // Seed Referee
        var refereeUser = await userManager.FindByEmailAsync("referee@pcm.com");
        if (refereeUser == null)
        {
            refereeUser = new ApplicationUser
            {
                UserName = "referee@pcm.com",
                Email = "referee@pcm.com",
                FullName = "Lê Thị Hoa",
                EmailConfirmed = true
            };
            await userManager.CreateAsync(refereeUser, "Referee@123");
            await userManager.AddToRoleAsync(refereeUser, "Referee");
            
            var refereeMember = new Member
            {
                FullName = "Lê Thị Hoa",
                UserId = refereeUser.Id,
                WalletBalance = 3000000,
                Tier = MemberTier.Silver
            };
            context.Members.Add(refereeMember);
        }
        
        // Seed 20 Members
        string[] memberNames = {
            "Phạm Văn Nam", "Hoàng Thị Lan", "Đỗ Minh Tuấn", "Vũ Thị Mai",
            "Bùi Văn Hùng", "Ngô Thị Thu", "Đặng Văn Long", "Trịnh Thị Hồng",
            "Lý Văn Đức", "Mai Thị Nga", "Võ Văn Cường", "Phan Thị Linh",
            "Dương Văn Khoa", "Lê Thị Trang", "Hồ Văn Phong", "Chu Thị Hằng",
            "Tạ Văn Sơn", "Đinh Thị Yến", "Cao Văn Tú", "Ninh Thị Hà"
        };
        
        var random = new Random(519); // Seed với số cuối MSSV
        
        for (int i = 0; i < memberNames.Length; i++)
        {
            var email = $"member{i + 1}@pcm.com";
            var user = await userManager.FindByEmailAsync(email);
            if (user == null)
            {
                user = new ApplicationUser
                {
                    UserName = email,
                    Email = email,
                    FullName = memberNames[i],
                    EmailConfirmed = true
                };
                await userManager.CreateAsync(user, $"Member{i + 1}@123");
                await userManager.AddToRoleAsync(user, "Member");
                
                var walletBalance = random.Next(2000000, 10000000);
                var tier = walletBalance switch
                {
                    > 8000000 => MemberTier.Diamond,
                    > 5000000 => MemberTier.Gold,
                    > 3000000 => MemberTier.Silver,
                    _ => MemberTier.Standard
                };
                
                var member = new Member
                {
                    FullName = memberNames[i],
                    UserId = user.Id,
                    WalletBalance = walletBalance,
                    Tier = tier,
                    RankLevel = random.Next(1000, 2000),
                    TotalSpent = walletBalance * 0.5m,
                    AvatarUrl = $"https://ui-avatars.com/api/?name={Uri.EscapeDataString(memberNames[i])}"
                };
                context.Members.Add(member);
            }
        }
        
        await context.SaveChangesAsync();
        
        // Seed Courts
        if (!context.Courts.Any())
        {
            var courts = new[]
            {
                new Court { Name = "Sân 1", IsActive = true, PricePerHour = 150000, Description = "Sân chính, ánh sáng tốt" },
                new Court { Name = "Sân 2", IsActive = true, PricePerHour = 150000, Description = "Sân phụ" },
                new Court { Name = "Sân 3", IsActive = true, PricePerHour = 120000, Description = "Sân tập luyện" },
                new Court { Name = "Sân VIP", IsActive = true, PricePerHour = 200000, Description = "Sân VIP có điều hòa" }
            };
            context.Courts.AddRange(courts);
            await context.SaveChangesAsync();
        }
        
        // Seed Tournaments
        if (!context.Tournaments.Any())
        {
            var tournaments = new[]
            {
                new Tournament
                {
                    Name = "Summer Open 2026",
                    StartDate = new DateTime(2026, 1, 1),
                    EndDate = new DateTime(2026, 1, 15),
                    Format = TournamentFormat.Knockout,
                    EntryFee = 500000,
                    PrizePool = 10000000,
                    Status = TournamentStatus.Finished
                },
                new Tournament
                {
                    Name = "Winter Cup 2026",
                    StartDate = new DateTime(2026, 2, 1),
                    EndDate = new DateTime(2026, 2, 28),
                    Format = TournamentFormat.RoundRobin,
                    EntryFee = 300000,
                    PrizePool = 5000000,
                    Status = TournamentStatus.Registering
                }
            };
            context.Tournaments.AddRange(tournaments);
            await context.SaveChangesAsync();
        }
        
        // Seed News
        if (!context.News.Any())
        {
            var news = new[]
            {
                new News
                {
                    Title = "Chào mừng đến với CLB Vợt Thủ Phố Núi",
                    Content = "CLB chúng tôi hoạt động với tinh thần Vui - Khỏe - Có Thưởng. Hãy tham gia ngay!",
                    IsPinned = true,
                    ImageUrl = "https://picsum.photos/800/400?random=1"
                },
                new News
                {
                    Title = "Giải đấu Winter Cup 2026 đang mở đăng ký",
                    Content = "Phí tham gia: 300.000đ, tổng giải thưởng 5.000.000đ. Đăng ký ngay!",
                    IsPinned = true,
                    ImageUrl = "https://picsum.photos/800/400?random=2"
                },
                new News
                {
                    Title = "Kết quả Summer Open 2026",
                    Content = "Xin chúc mừng đội vô địch! Các đội đã có những trận đấu rất hay.",
                    IsPinned = false,
                    CreatedDate = new DateTime(2026, 1, 20)
                }
            };
            context.News.AddRange(news);
            await context.SaveChangesAsync();
        }
    }
}
