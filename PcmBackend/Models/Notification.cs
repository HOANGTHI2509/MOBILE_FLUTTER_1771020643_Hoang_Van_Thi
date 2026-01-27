using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum NotificationType { Info, Success, Warning, Error }

[Table("643_Notifications")]
public class Notification
{
    [Key]
    public int Id { get; set; }
    
    public int ReceiverId { get; set; }
    [ForeignKey("ReceiverId")]
    public Member? Receiver { get; set; }
    
    [Required]
    public string Message { get; set; } = string.Empty;
    
    public NotificationType Type { get; set; } = NotificationType.Info;
    
    public string? LinkUrl { get; set; }
    
    public bool IsRead { get; set; } = false;
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
}
