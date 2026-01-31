using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("643_RankHistory")]
public class RankHistory
{
    [Key]
    public int Id { get; set; }
    
    public int MemberId { get; set; }
    [ForeignKey("MemberId")]
    public Member Member { get; set; }

    public double RankLevel { get; set; }
    
    public string Reason { get; set; } = string.Empty; // e.g., "Match result", "Admin adjustment"
    
    public DateTime CreatedDate { get; set; } = DateTime.Now;
}
