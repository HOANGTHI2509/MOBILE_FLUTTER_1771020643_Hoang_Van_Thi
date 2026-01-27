using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class NewsController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public NewsController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<News>>> GetNews()
    {
        return await _context.News.OrderByDescending(n => n.CreatedDate).ToListAsync();
    }

    [HttpPost]
    // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<News>> CreateNews(News news)
    {
        news.CreatedDate = DateTime.Now;
        _context.News.Add(news);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetNews), new { id = news.Id }, news);
    }
    
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNews(int id)
    {
        var news = await _context.News.FindAsync(id);
        if (news == null) return NotFound();
        
        _context.News.Remove(news);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
