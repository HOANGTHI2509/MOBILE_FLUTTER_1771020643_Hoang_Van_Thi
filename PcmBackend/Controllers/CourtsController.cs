using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CourtsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CourtsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Court>>> GetCourts()
    {
        return await _context.Courts.Where(c => c.IsActive).ToListAsync();
    }
    
    [HttpGet("all")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IEnumerable<Court>>> GetAllCourts()
    {
        return await _context.Courts.ToListAsync();
    }
    
    [HttpPost]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<Court>> CreateCourt([FromBody] Court court)
    {
        _context.Courts.Add(court);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetCourts), new { id = court.Id }, court);
    }
    
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateCourt(int id, [FromBody] Court court)
    {
        if (id != court.Id)
            return BadRequest("ID mismatch");

        var existingCourt = await _context.Courts.FindAsync(id);
        if (existingCourt == null)
            return NotFound();

        existingCourt.Name = court.Name;
        existingCourt.PricePerHour = court.PricePerHour;
        existingCourt.Description = court.Description;
        existingCourt.IsActive = court.IsActive;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.Courts.AnyAsync(c => c.Id == id))
                return NotFound();
            throw;
        }

        return Ok(existingCourt);
    }
    
    [HttpPut("{id}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> ToggleCourtStatus(int id, [FromBody] StatusUpdateDto update)
    {
        var court = await _context.Courts.FindAsync(id);
        if (court == null)
            return NotFound();

        court.IsActive = update.IsActive;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Status updated successfully", isActive = court.IsActive });
    }
}
