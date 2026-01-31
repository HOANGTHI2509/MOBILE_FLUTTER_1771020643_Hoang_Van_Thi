using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Models; // Đảm bảo namespace này khớp với các file trong thư mục Models

namespace PcmBackend.Data;

// IdentityDbContext giúp Thi có sẵn các bảng quản lý User (đăng nhập/đăng ký)
public class ApplicationDbContext : IdentityDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    // Khai báo các bảng nghiệp vụ của CLB
    public DbSet<Member> Members { get; set; }
    public DbSet<WalletTransaction> WalletTransactions { get; set; }
    public DbSet<News> News { get; set; }
    public DbSet<TransactionCategory> TransactionCategories { get; set; }
    public DbSet<Court> Courts { get; set; }
    public DbSet<Booking> Bookings { get; set; }
    public DbSet<Tournament> Tournaments { get; set; }
    public DbSet<TournamentParticipant> TournamentParticipants { get; set; }
    public DbSet<Match> Matches { get; set; }
    public DbSet<Notification> Notifications { get; set; }
    public DbSet<RankHistory> RankHistories { get; set; }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        // Cấu hình tiền tố 643 cho các bảng theo yêu cầu đề bài
        builder.Entity<Member>().ToTable("643_Members");
        builder.Entity<WalletTransaction>().ToTable("643_WalletTransactions");
        builder.Entity<News>().ToTable("643_News");
        builder.Entity<TransactionCategory>().ToTable("643_TransactionCategories");
        builder.Entity<Court>().ToTable("643_Courts");
        builder.Entity<Booking>().ToTable("643_Bookings");
        builder.Entity<Tournament>().ToTable("643_Tournaments");
        builder.Entity<TournamentParticipant>().ToTable("643_TournamentParticipants");
        builder.Entity<Match>().ToTable("643_Matches");
        builder.Entity<Notification>().ToTable("643_Notifications");
        builder.Entity<RankHistory>().ToTable("643_RankHistory");

        // Cấu hình kiểu dữ liệu tiền tệ (decimal) để tránh lỗi làm tròn
        builder.Entity<Member>().Property(m => m.WalletBalance).HasPrecision(18, 2);
        builder.Entity<Member>().Property(m => m.TotalSpent).HasPrecision(18, 2);
        builder.Entity<WalletTransaction>().Property(w => w.Amount).HasPrecision(18, 2);
        builder.Entity<Court>().Property(c => c.PricePerHour).HasPrecision(18, 2);
        builder.Entity<Booking>().Property(b => b.TotalPrice).HasPrecision(18, 2);
        builder.Entity<Tournament>().Property(t => t.EntryFee).HasPrecision(18, 2);
        builder.Entity<Tournament>().Property(t => t.PrizePool).HasPrecision(18, 2);
    }
}