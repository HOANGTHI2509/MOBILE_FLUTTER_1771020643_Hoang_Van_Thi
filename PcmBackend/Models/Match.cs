using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PcmBackend.Models;

public enum WinningSide { None, Team1, Team2 }
public enum MatchStatus { Scheduled, InProgress, Finished }

[Table("643_Matches")]
public class Match
{
    [Key]
    public int Id { get; set; }
    
    public int? TournamentId { get; set; }
    [ForeignKey("TournamentId")]
    public Tournament? Tournament { get; set; }
    
    public string RoundName { get; set; } = string.Empty;
    
    public DateTime Date { get; set; }
    public TimeSpan StartTime { get; set; }
    
    // Participants
    public int? Team1_Player1Id { get; set; }
    public int? Team1_Player2Id { get; set; }
    public int? Team2_Player1Id { get; set; }
    public int? Team2_Player2Id { get; set; }
    
    // Result
    public int Score1 { get; set; }
    public int Score2 { get; set; }
    
    public string? Details { get; set; } // Set scores e.g., "11-9, 5-11, 11-8"
    
    public WinningSide WinningSide { get; set; } = WinningSide.None;
    
    public bool IsRanked { get; set; } = false;
    
    public MatchStatus Status { get; set; } = MatchStatus.Scheduled;
}
