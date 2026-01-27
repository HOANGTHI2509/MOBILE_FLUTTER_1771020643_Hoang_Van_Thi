using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Models;

namespace PcmBackend.Data;

public static class SeedData
{
    public static async Task Initialize(IServiceProvider serviceProvider)
    {
        using var context = serviceProvider.GetRequiredService<ApplicationDbContext>();
        using var userManager = serviceProvider.GetRequiredService<UserManager<IdentityUser>>();

        // update database
        await context.Database.MigrateAsync();

        // 0. Seed Users (Admin, Treasurer, Referee)
        string[] roles = { "Admin", "Treasurer", "Referee", "Member" };
        // Note: In this simple setup with IdentityApiEndpoints, we might not have RoleManager set up explicitly in Program.cs
        // But we can create Users.

        // 1. Admin
        var adminUser = await userManager.FindByEmailAsync("admin@pcm.com");
        if (adminUser == null)
        {
            adminUser = new IdentityUser { UserName = "admin@pcm.com", Email = "admin@pcm.com" };
            await userManager.CreateAsync(adminUser, "Pcm@123456");
        }

        // Ensure Admin has a Member record
        var adminMember = await context.Members.FirstOrDefaultAsync(m => m.UserId == adminUser.Id);
        if (adminMember == null)
        {
            adminMember = new Member
            {
                UserId = adminUser.Id,
                FullName = "Administrator",
                Email = "admin@pcm.com",
                JoinDate = DateTime.Now,
                IsActive = true,
                IsAdmin = true, // Quan trọng: Set Admin flag
                Tier = MembershipTier.Diamond,
                WalletBalance = 1000000000,
                TotalSpent = 0
            };
            context.Members.Add(adminMember);
            await context.SaveChangesAsync();
        } else if (!adminMember.IsAdmin) {
            adminMember.IsAdmin = true; // Fix existing
            await context.SaveChangesAsync();
        }

        // 2. Members (20 members) - Only create if less than 5 members exist
        if (await context.Members.CountAsync() < 5)
        {
            var random = new Random();
            for (int i = 1; i <= 20; i++)
            {
                var email = $"member{i}@pcm.com";
                var user = await userManager.FindByEmailAsync(email);
                if (user == null)
                {
                    user = new IdentityUser { UserName = email, Email = email };
                    await userManager.CreateAsync(user, "Pcm@123456");
                }

                // Check if member already exists
                var existingMember = await context.Members.FirstOrDefaultAsync(m => m.UserId == user.Id);
                if (existingMember == null)
                {
                    var member = new Member
                    {
                        UserId = user.Id,
                        FullName = $"Vợt Thủ {i}",
                        Email = email,
                        JoinDate = DateTime.Now.AddMonths(-random.Next(1, 24)),
                        RankLevel = 2.5 + (random.NextDouble() * 3.0), // 2.5 - 5.5
                        IsActive = true,
                        WalletBalance = random.Next(20, 100) * 100000, // 2M - 10M
                        Tier = (MembershipTier)random.Next(0, 4),
                        TotalSpent = random.Next(50, 500) * 10000
                    };
                    context.Members.Add(member);
                }
            }
            await context.SaveChangesAsync();
        }

        // 3. Courts
        if (!context.Courts.Any())
        {
            context.Courts.AddRange(
                new Court { Name = "Sân 1 (Standard)", PricePerHour = 100000, IsActive = true, Description = "Sân tiêu chuẩn" },
                new Court { Name = "Sân 2 (Standard)", PricePerHour = 100000, IsActive = true, Description = "Sân tiêu chuẩn" },
                new Court { Name = "Sân 3 (VIP)", PricePerHour = 200000, IsActive = true, Description = "Sân có mái che, điều hòa" },
                new Court { Name = "Sân 4 (Tập luyện)", PricePerHour = 80000, IsActive = true, Description = "Sân tập máy bắn bóng" }
            );
            await context.SaveChangesAsync();
        }

        // 4. Tournaments
        if (!context.Tournaments.Any())
        {
            context.Tournaments.AddRange(
                new Tournament
                {
                    Name = "Summer Open 2026",
                    StartDate = DateTime.Now.AddMonths(-2),
                    EndDate = DateTime.Now.AddMonths(-2).AddDays(3),
                    Format = TournamentFormat.Knockout,
                    EntryFee = 500000,
                    PrizePool = 10000000,
                    Status = TournamentStatus.Finished
                },
                new Tournament
                {
                    Name = "Winter Cup 2026",
                    StartDate = DateTime.Now.AddMonths(1),
                    EndDate = DateTime.Now.AddMonths(1).AddDays(5),
                    Format = TournamentFormat.RoundRobin,
                    EntryFee = 300000,
                    PrizePool = 20000000,
                    Status = TournamentStatus.Registering
                }
            );
            await context.SaveChangesAsync();
        }
        
        // 5. Transaction Categories
        if (!context.TransactionCategories.Any()) 
        {
             context.TransactionCategories.AddRange(
                new TransactionCategory { Name = "Tiền Nước", Type = TransactionCategoryType.Thu },
                new TransactionCategory { Name = "Tiền Điện", Type = TransactionCategoryType.Chi },
                new TransactionCategory { Name = "Bảo trì sân", Type = TransactionCategoryType.Chi }
             );
             await context.SaveChangesAsync();
        }
    }
}
