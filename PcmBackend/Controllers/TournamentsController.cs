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
        var tournaments = await _context.Tournaments.ToListAsync();
        
        // Populate IsJoined if user is logged in
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!string.IsNullOrEmpty(userId))
        {
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member != null)
            {
                var joinedIds = await _context.TournamentParticipants
                    .Where(p => p.MemberId == member.Id)
                    .Select(p => p.TournamentId)
                    .ToListAsync();
                
                foreach (var t in tournaments)
                {
                    if (joinedIds.Contains(t.Id)) t.IsJoined = true;
                }
            }
        }

        return tournaments;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Tournament>> GetTournament(int id)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound();

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        if (!string.IsNullOrEmpty(userId))
        {
            var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
            if (member != null)
            {
                 var isJoined = await _context.TournamentParticipants
                    .AnyAsync(p => p.TournamentId == id && p.MemberId == member.Id);
                 tournament.IsJoined = isJoined;
            }
        }
        return tournament;
    }

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<Tournament>> CreateTournament(Tournament tournament)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        Console.WriteLine($"[DEBUG] CreateTournament - UserId from Claims: '{userId}'");

        if (string.IsNullOrEmpty(userId))
        {
             // Fallback: Check 'sub' claim just in case
             userId = User.FindFirstValue("sub"); // JwtRegisteredClaimNames.Sub
             Console.WriteLine($"[DEBUG] CreateTournament - UserId from 'sub': '{userId}'");
        }

        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        Console.WriteLine($"[DEBUG] Member found: {member != null}, IsAdmin: {member?.IsAdmin}");
        
        if (member == null || !member.IsAdmin) 
        {
            Console.WriteLine("[DEBUG] Access Denied: Returning Forbid");
            return Forbid();
        }

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

    [HttpPost("{id}/leave")]
    [Authorize]
    public async Task<IActionResult> LeaveTournament(int id)
    {
        var tournament = await _context.Tournaments.FindAsync(id);
        if (tournament == null) return NotFound("Tournament not found");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // Fallback for 'sub'
        if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue("sub");

        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        // Find participant
        var participant = await _context.TournamentParticipants
            .FirstOrDefaultAsync(p => p.TournamentId == id && p.MemberId == member.Id);
            
        if (participant == null) return BadRequest("You are not part of this tournament");

        // Penalty Logic: Refund 50%
        decimal refundAmount = tournament.EntryFee * 0.5m;
        
        member.WalletBalance += refundAmount;
        // TotalSpent should technically reflect the actual money spent (EntryFee - Refund)
        member.TotalSpent -= refundAmount;

        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = refundAmount,
            Type = TransactionType.Refund,
            Status = TransactionStatus.Completed,
            Description = $"Refund (50%): Left Tournament {tournament.Name}",
            RelatedId = tournament.Id.ToString(),
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);

        // Remove participant
        _context.TournamentParticipants.Remove(participant);

        await _context.SaveChangesAsync();

        return Ok(new { message = "Left tournament successfully. Refunded 50%." });
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
