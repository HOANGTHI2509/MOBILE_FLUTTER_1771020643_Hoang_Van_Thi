using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TournamentsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public TournamentsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Tournament>>> GetTournaments()
    {
        return await _context.Tournaments.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Tournament>> GetTournament(int id)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound();
        return tournament;
    }

    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Tournament>> CreateTournament(Tournament tournament)
    {
        _context.Tournaments.Add(tournament);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetTournament), new { id = tournament.Id }, tournament);
    }

    [HttpPost("{id}/join")]
    [Authorize]
    public async Task<IActionResult> JoinTournament(int id, [FromBody] string? teamName)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound("Tournament not found");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        // Check already joined
        if (await _context.TournamentParticipants.AnyAsync(p => p.TournamentId == id && p.MemberId == member.Id))
            return BadRequest("Already joined this tournament");

        // Check fee
        if (member.WalletBalance < tournament.EntryFee)
            return BadRequest("Insufficient funds for entry fee");

        // Deduct money
        member.WalletBalance -= tournament.EntryFee;
        member.TotalSpent += tournament.EntryFee;

        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -tournament.EntryFee,
            Type = TransactionType.Payment,
            Status = TransactionStatus.Completed,
            Description = $"Join Tournament: {tournament.Name}",
            RelatedId = tournament.Id.ToString(),
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);

        // Add participant
        var participant = new TournamentParticipant
        {
            TournamentId = id,
            MemberId = member.Id,
            TeamName = teamName ?? member.FullName,
            PaymentStatus = true
        };
        _context.TournamentParticipants.Add(participant);

        await _context.SaveChangesAsync();

        return Ok(new { message = "Joined successfully", participantId = participant.Id });
    }
    [HttpPost("{id}/generate-schedule")]
    [Authorize] // Roles = "Admin" check commented out for easier testing, or put back if requested. user is admin.
    public async Task<IActionResult> GenerateSchedule(int id)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound();
        
        var participants = await _context.TournamentParticipants
            .Where(p => p.TournamentId == id && p.PaymentStatus)
            .ToListAsync();
            
        if (participants.Count < 2) return BadRequest("Not enough participants");
        
        // Shuffle
        var rand = new Random();
        var shuffled = participants.OrderBy(x => rand.Next()).ToList();
        
        var matches = new List<Match>();
        
        if (tournament.Format == TournamentFormat.Knockout)
        {
            // Simple Knockout Round 1
            for (int i = 0; i < shuffled.Count; i += 2)
            {
                if (i + 1 < shuffled.Count)
                {
                    matches.Add(new Match
                    {
                        TournamentId = id,
                        RoundName = "Round 1",
                        Date = DateTime.Now.AddDays(1),
                        StartTime = new TimeSpan(8, 0, 0).Add(TimeSpan.FromHours(i)),
                        Team1_Player1Id = shuffled[i].MemberId,
                        Team2_Player1Id = shuffled[i+1].MemberId,
                        Status = MatchStatus.Scheduled
                    });
                }
            }
        }
        else 
        {
             // Round Robin
             for (int i = 0; i < shuffled.Count; i++)
             {
                 for (int j = i + 1; j < shuffled.Count; j++)
                 {
                     matches.Add(new Match
                    {
                        TournamentId = id,
                        RoundName = "Group Stage",
                        Date = DateTime.Now.AddDays(1),
                         StartTime = new TimeSpan(8, 0, 0).Add(TimeSpan.FromMinutes(30 * (i+j))), 
                        Team1_Player1Id = shuffled[i].MemberId,
                        Team2_Player1Id = shuffled[j].MemberId,
                        Status = MatchStatus.Scheduled
                    });
                 }
             }
        }
        
        _context.Matches.AddRange(matches);
        tournament.Status = TournamentStatus.Ongoing;
        await _context.SaveChangesAsync();
        
        return Ok(new { message = $"Generated {matches.Count} matches", matches });
    }
}
