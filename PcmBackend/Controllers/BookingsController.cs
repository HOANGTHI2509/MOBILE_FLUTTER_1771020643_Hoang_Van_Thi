using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Data;
using PcmBackend.Models;
using PcmBackend.Hubs;
using System.Security.Claims;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class BookingsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;

    public BookingsController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    // GET: api/bookings/calendar?from=...&to=...
    [HttpGet("calendar")]
    public async Task<ActionResult<IEnumerable<Booking>>> GetCalendar(DateTime from, DateTime to)
    {
        return await _context.Bookings
            .Include(b => b.Court)
            .Include(b => b.Member)
            .Where(b => b.StartTime >= from && b.EndTime <= to && b.Status != BookingStatus.Cancelled)
            .ToListAsync();
    }

    // POST: api/bookings
    [HttpPost]
    public async Task<ActionResult<Booking>> CreateBooking(Booking booking)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");
        
        // 1. Check availability
        var conflict = await _context.Bookings.AnyAsync(b => 
            b.CourtId == booking.CourtId && 
            b.Status != BookingStatus.Cancelled &&
            ((booking.StartTime >= b.StartTime && booking.StartTime < b.EndTime) ||
             (booking.EndTime > b.StartTime && booking.EndTime <= b.EndTime) ||
             (booking.StartTime <= b.StartTime && booking.EndTime >= b.EndTime)));
             
        if (conflict) return BadRequest("Court is already booked for this time slot.");
        
        // 2. Calculate price
        var court = await _context.Courts.FirstOrDefaultAsync(c => c.Id == booking.CourtId);
        if (court == null) return BadRequest("Invalid court");
        
        var durationHours = (decimal)(booking.EndTime - booking.StartTime).TotalHours;
        var totalPrice = durationHours * court.PricePerHour;
        
        // 3. Check wallet
        if (member.WalletBalance < totalPrice) return BadRequest("Insufficient wallet balance.");
        
        // 4. Process Payment
        member.WalletBalance -= totalPrice;
        member.TotalSpent += totalPrice;
        
        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -totalPrice,
            Type = TransactionType.Payment,
            Status = TransactionStatus.Completed,
            Description = $"Booking Court {court.Name}",
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync(); // Save to get Transaction Id
        
        // 5. Create Booking
        booking.MemberId = member.Id;
        booking.TotalPrice = totalPrice;
        booking.TransactionId = transaction.Id;
        booking.Status = BookingStatus.Confirmed;
        
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();
        
        transaction.RelatedId = booking.Id.ToString();
        await _context.SaveChangesAsync();
        
        // SignalR: Notify all clients
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");

        return CreatedAtAction(nameof(GetCalendar), new { from = booking.StartTime, to = booking.EndTime }, booking);
    }
    [HttpPost("recurring")]
    public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        // Validate
        if (request.EndDate <= request.StartDate) return BadRequest("End date must be after start date");
        
        var court = await _context.Courts.FindAsync(request.CourtId);
        if (court == null) return NotFound("Court not found");

        var bookingsToCreate = new List<Booking>();
        decimal totalPrice = 0;

        // Loop dates
        for (var date = request.StartDate.Date; date <= request.EndDate.Date; date = date.AddDays(1))
        {
            if (request.DaysOfWeek.Contains(date.DayOfWeek))
            {
                var start = date.Add(request.StartTime);
                var end = date.Add(request.EndTime);
                
                // Check conflict
                bool conflict = await _context.Bookings.AnyAsync(b => 
                    b.CourtId == request.CourtId && 
                    b.Status != BookingStatus.Cancelled &&
                    ((start >= b.StartTime && start < b.EndTime) ||
                     (end > b.StartTime && end <= b.EndTime) ||
                     (start <= b.StartTime && end >= b.EndTime)));
                
                if (conflict) return BadRequest($"Conflict found on {date.ToShortDateString()}");

                decimal price = (decimal)(request.EndTime - request.StartTime).TotalHours * court.PricePerHour;
                totalPrice += price;
                
                bookingsToCreate.Add(new Booking
                {
                    CourtId = request.CourtId,
                    MemberId = member.Id,
                    StartTime = start,
                    EndTime = end,
                    TotalPrice = price,
                    IsRecurring = true,
                    RecurrenceRule = string.Join(",", request.DaysOfWeek),
                    Status = BookingStatus.Confirmed,
                    CreatedDate = DateTime.Now
                });
            }
        }

        if (bookingsToCreate.Count == 0) return BadRequest("No bookings created based on rules");

        // Wallet check
        if (member.WalletBalance < totalPrice) return BadRequest($"Insufficient balance. Need {totalPrice:N0}, have {member.WalletBalance:N0}");

        // Pay
        member.WalletBalance -= totalPrice;
        member.TotalSpent += totalPrice;

        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -totalPrice,
            Type = TransactionType.Payment,
            Status = TransactionStatus.Completed,
            Description = $"Recurring Booking for {bookingsToCreate.Count} slots",
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        // Save Bookings
        foreach (var b in bookingsToCreate)
        {
            b.TransactionId = transaction.Id;
            _context.Bookings.Add(b);
        }
        await _context.SaveChangesAsync();

        // SignalR: Notify all clients
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");

        return Ok(new { message = "Recurring booking success", count = bookingsToCreate.Count });
    }

    [HttpPost("cancel/{id}")]
    public async Task<IActionResult> CancelBooking(int id)
    {
        var booking = await _context.Bookings.Include(b => b.Member).FirstOrDefaultAsync(b => b.Id == id);
        if (booking == null) return NotFound();

        if (booking.Status == BookingStatus.Cancelled) return BadRequest("Already cancelled");

        // Policy: 50% refund (50% penalty)
        var refundAmount = booking.TotalPrice * 0.5m;

        // Refund 50% to wallet
        booking.Status = BookingStatus.Cancelled;
        booking.Member.WalletBalance += refundAmount;

        var transaction = new WalletTransaction
        {
            MemberId = booking.MemberId,
            Amount = refundAmount,
            Type = TransactionType.Refund,
            Status = TransactionStatus.Completed,
            Description = $"Hoàn tiền hủy sân (50% - Phí hủy: {booking.TotalPrice * 0.5m:N0}đ)",
            RelatedId = booking.Id.ToString(),
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);
        
        await _context.SaveChangesAsync();
        
        // SignalR: Notify all clients
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");
        
        return Ok(new { 
            message = "Đã hủy sân thành công", 
            refundAmount = refundAmount,
            penalty = booking.TotalPrice * 0.5m,
            newBalance = booking.Member.WalletBalance 
        });
    }
}

public class RecurringBookingDto
{
    public int CourtId { get; set; }
    public TimeSpan StartTime { get; set; }
    public TimeSpan EndTime { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public List<DayOfWeek> DaysOfWeek { get; set; } = new();
}
