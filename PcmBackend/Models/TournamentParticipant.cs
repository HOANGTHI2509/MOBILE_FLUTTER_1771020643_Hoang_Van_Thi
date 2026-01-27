using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

[Table("643_TournamentParticipants")]
public class TournamentParticipant
{
    [Key]
    public int Id { get; set; }
    
    public int TournamentId { get; set; }
    [ForeignKey("TournamentId")]
    public Tournament? Tournament { get; set; }
    
    public int MemberId { get; set; }
    [ForeignKey("MemberId")]
    public Member? Member { get; set; }
    
    public string? TeamName { get; set; }
    
    public bool PaymentStatus { get; set; } = false;
}
