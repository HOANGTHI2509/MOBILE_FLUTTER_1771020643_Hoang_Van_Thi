using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class WalletController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public WalletController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("transactions")]
    public async Task<ActionResult<IEnumerable<WalletTransaction>>> GetTransactions()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound();

        return await _context.WalletTransactions
            .Where(t => t.MemberId == member.Id)
            .OrderByDescending(t => t.CreatedDate)
            .ToListAsync();
    }
}
