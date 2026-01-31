using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Data;
using PcmBackend.Models;
using PcmBackend.Hubs;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class NewsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;

    public NewsController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
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

        // 1. Create Notification for ALL members
        // Warning: Performance impact if thousands of users. For MVP/Small scale this is fine.
        var memberIds = await _context.Members.Select(m => m.Id).ToListAsync();
        var notifications = memberIds.Select(mid => new Notification
        {
            ReceiverId = mid,
            Message = $"Tin mới: {news.Title}",
            Type = NotificationType.Info,
            LinkUrl = $"/news/{news.Id}",
            CreatedDate = DateTime.Now,
            IsRead = false
        }).ToList();

        _context.Notifications.AddRange(notifications);
        await _context.SaveChangesAsync();

        // 2. Broadcast SignalR
        await _hubContext.Clients.All.SendAsync("ReceiveNotification", "Admin", $"Tin mới: {news.Title}");

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
