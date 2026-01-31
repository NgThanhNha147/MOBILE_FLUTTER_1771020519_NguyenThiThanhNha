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
                // OFFICIAL TOURNAMENTS (Admin created)
                new Tournament
                {
                    Name = "Giải Pickleball Mùa Xuân 2026",
                    Description = "Giải đấu lớn với giải thưởng hấp dẫn dành cho các tay vợt xuất sắc",
                    Type = TournamentType.Official,
                    StartDate = DateTime.Now.AddDays(7),
                    EndDate = DateTime.Now.AddDays(9),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 16,
                    EntryFee = 200000,
                    PrizePool = 5000000,
                    CreatorId = null  // Admin created
                },
                new Tournament
                {
                    Name = "Giải Vô Địch Mùa Hè 2026",
                    Description = "Giải đấu chính thức lớn nhất năm với tổng giải thưởng lên đến 20 triệu",
                    Type = TournamentType.Official,
                    StartDate = DateTime.Now.AddDays(14),
                    EndDate = DateTime.Now.AddDays(16),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 32,
                    EntryFee = 300000,
                    PrizePool = 20000000,
                    CreatorId = null
                },
                new Tournament
                {
                    Name = "Giải Giao Hữu Tháng 2",
                    Description = "Giải đấu giao hữu, thi đấu vòng tròn để mọi người được gặp nhau",
                    Type = TournamentType.Official,
                    StartDate = DateTime.Now.AddDays(-10),
                    EndDate = DateTime.Now.AddDays(-8),
                    Format = TournamentFormat.RoundRobin,
                    Status = TournamentStatus.Finished,
                    MaxParticipants = 20,
                    EntryFee = 100000,
                    PrizePool = 2000000,
                    CreatorId = null
                },
                
                // CHALLENGE 1V1 (User created)
                new Tournament
                {
                    Name = "⚔️ Thách đấu từ Nguyễn Văn A",
                    Description = "Ai dám đấu với tôi không? Cược 100k!",
                    Type = TournamentType.Challenge1v1,
                    StartDate = DateTime.Now.AddHours(2),
                    EndDate = DateTime.Now.AddHours(4),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 2,
                    EntryFee = 100000,
                    PrizePool = 160000,  // 80% of 200k
                    CreatorId = 1
                },
                new Tournament
                {
                    Name = "⚔️ Challenge từ Pro Player",
                    Description = "Thử tài với cao thủ, không cược tiền",
                    Type = TournamentType.Challenge1v1,
                    StartDate = DateTime.Now.AddDays(1),
                    EndDate = DateTime.Now.AddDays(1).AddHours(2),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 2,
                    EntryFee = 0,
                    PrizePool = 0,
                    CreatorId = 1
                },
                
                // TEAM BATTLE (User created)
                new Tournament
                {
                    Name = "👥 Đấu đôi cuối tuần",
                    Description = "Giải đấu đôi vui vẻ, kèo nhỏ cho anh em giao lưu",
                    Type = TournamentType.TeamBattle,
                    StartDate = DateTime.Now.AddDays(3),
                    EndDate = DateTime.Now.AddDays(3).AddHours(6),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 8,  // 4 teams x 2 people
                    EntryFee = 150000,
                    PrizePool = 960000,  // 80% of 1.2M
                    CreatorId = 1
                },
                new Tournament
                {
                    Name = "👥 Giải Đấu Team Hè 2026",
                    Description = "Giải đấu theo đội, mỗi team 4 người. Thi đấu vòng tròn và loại trực tiếp",
                    Type = TournamentType.TeamBattle,
                    StartDate = DateTime.Now.AddDays(-2),
                    EndDate = DateTime.Now.AddDays(5),
                    Format = TournamentFormat.Hybrid,
                    Status = TournamentStatus.Ongoing,
                    MaxParticipants = 16,
                    EntryFee = 200000,
                    PrizePool = 2560000,
                    CreatorId = 1
                },
                
                // MINI GAME (Admin created)
                new Tournament
                {
                    Name = "🎮 Mini Game Cuối Tuần",
                    Description = "12 người tham gia, lệ phí 50k, giải thưởng 600k cho người chiến thắng",
                    Type = TournamentType.MiniGame,
                    StartDate = DateTime.Now.AddDays(1),
                    EndDate = DateTime.Now.AddDays(2),
                    Format = TournamentFormat.RoundRobin,
                    Status = TournamentStatus.Open,
                    MaxParticipants = 12,
                    EntryFee = 50000,
                    PrizePool = 600000,
                    CreatorId = null  // Admin created
                },
                new Tournament
                {
                    Name = "🎮 Thử thách giao bóng 50 quả",
                    Description = "Ai giao được 50 quả vào ô chính xác nhất sẽ nhận 500k",
                    Type = TournamentType.MiniGame,
                    StartDate = DateTime.Now,
                    EndDate = DateTime.Now.AddDays(7),
                    Format = TournamentFormat.Knockout,
                    Status = TournamentStatus.Ongoing,
                    MaxParticipants = 12,
                    EntryFee = 50000,
                    PrizePool = 500000,
                    CreatorId = null
                }
            };

            context.Tournaments.AddRange(tournaments);
            context.SaveChanges();
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
