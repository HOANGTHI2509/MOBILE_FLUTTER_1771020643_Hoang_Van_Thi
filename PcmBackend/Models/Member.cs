using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum MembershipTier { Standard, Silver, Gold, Diamond }

[Table("643_Members")]
public class Member
{
    [Key]
    public int Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty; // Added Email lookup
    public DateTime JoinDate { get; set; } = DateTime.Now;
    public double RankLevel { get; set; } = 0.0;
    public bool IsActive { get; set; } = true;
    public bool IsAdmin { get; set; } = false;

    public string UserId { get; set; } = string.Empty; // FK đến AspNetUsers

    [Column(TypeName = "decimal(18,2)")]
    public decimal WalletBalance { get; set; } = 0;
    
    public MembershipTier Tier { get; set; } = MembershipTier.Standard;
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal TotalSpent { get; set; } = 0;
    
    public string? AvatarUrl { get; set; }
}