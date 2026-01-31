using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum TournamentFormat { RoundRobin, Knockout, Hybrid }
public enum TournamentStatus { Open, Registering, DrawCompleted, Ongoing, Finished }

[Table("643_Tournaments")]
public class Tournament
{
    [Key]
    public int Id { get; set; }
    
    [Required]
    public string Name { get; set; } = string.Empty;
    
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    
    public TournamentFormat Format { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal EntryFee { get; set; }
    
    [Column(TypeName = "decimal(18,2)")]
    public decimal PrizePool { get; set; }
    
    public TournamentStatus Status { get; set; } = TournamentStatus.Open;
    
    public string? Settings { get; set; } // JSON

    [NotMapped]
    public bool IsJoined { get; set; }
}
