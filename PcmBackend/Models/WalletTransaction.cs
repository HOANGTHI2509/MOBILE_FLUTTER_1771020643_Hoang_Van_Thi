using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum TransactionType { Deposit, Withdraw, Payment, Refund, Reward }
public enum TransactionStatus { Pending, Completed, Rejected, Failed }

[Table("643_WalletTransactions")]
public class WalletTransaction
{
    public int Id { get; set; }
    public int MemberId { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }
    
    public TransactionType Type { get; set; }
    public TransactionStatus Status { get; set; }
    public string? RelatedId { get; set; } 
    public string? ProofImageUrl { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedDate { get; set; } = DateTime.Now;
    
    [ForeignKey("MemberId")]
    public virtual Member? Member { get; set; }
}