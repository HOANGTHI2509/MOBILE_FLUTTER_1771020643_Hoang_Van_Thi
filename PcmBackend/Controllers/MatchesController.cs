using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class MatchesController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MatchesController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Match>>> GetMatches(int? tournamentId)
    {
        var query = _context.Matches.AsQueryable();
        if (tournamentId.HasValue)
        {
            query = query.Where(m => m.TournamentId == tournamentId);
        }
        return await query.ToListAsync();
    }

    [HttpPost("{id}/result")]
    [Authorize(Roles = "Admin,Referee")]
    public async Task<IActionResult> UpdateResult(int id, [FromBody] MatchResultDto result)
    {
        var match = await _context.Matches.FindAsync(id);
        if (match == null) return NotFound();

        match.Score1 = result.Score1;
        match.Score2 = result.Score2;
        match.Details = result.Details;
        match.WinningSide = result.Score1 > result.Score2 ? WinningSide.Team1 : 
                           (result.Score2 > result.Score1 ? WinningSide.Team2 : WinningSide.None);
        match.Status = MatchStatus.Finished;

        await _context.SaveChangesAsync();
        
        // TODO: Call SignalR here to notify clients
        
        return Ok(new { message = "Match result updated" });
    }
}

public class MatchResultDto 
{
    public int Score1 { get; set; }
    public int Score2 { get; set; }
    public string? Details { get; set; }
}
