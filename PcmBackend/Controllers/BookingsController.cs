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

    // POST: api/bookings/hold
    [HttpPost("hold")]
    public async Task<ActionResult<Booking>> HoldBooking(Booking booking)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // Fallback for 'sub'
        if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue("sub");

        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");
        
        // 1. Check availability (Including PendingPayment bookings to prevent race condition)
        var conflict = await _context.Bookings.AnyAsync(b => 
            b.CourtId == booking.CourtId && 
            b.Status != BookingStatus.Cancelled && 
            ((booking.StartTime >= b.StartTime && booking.StartTime < b.EndTime) ||
             (booking.EndTime > b.StartTime && booking.EndTime <= b.EndTime) ||
             (booking.StartTime <= b.StartTime && booking.EndTime >= b.EndTime)));
             
        if (conflict) return BadRequest("Court is already booked or held by someone else.");
        
        // 2. Calculate price
        var court = await _context.Courts.FirstOrDefaultAsync(c => c.Id == booking.CourtId);
        if (court == null) return BadRequest("Invalid court");
        
        var durationHours = (decimal)(booking.EndTime - booking.StartTime).TotalHours;
        var totalPrice = durationHours * court.PricePerHour;
        
        // 3. Create Booking in PendingPayment state
        booking.MemberId = member.Id;
        booking.TotalPrice = totalPrice;
        booking.Status = BookingStatus.PendingPayment;
        booking.CreatedDate = DateTime.Now; // Counts for 5 min expiration
        
        _context.Bookings.Add(booking);
        await _context.SaveChangesAsync();

        // SignalR: Update others to see the held slot (maybe in gray/yellow)
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");
        
        return CreatedAtAction(nameof(GetCalendar), new { from = booking.StartTime, to = booking.EndTime }, booking);
    }

    [HttpPost("confirm/{id}")]
    public async Task<IActionResult> ConfirmBooking(int id)
    {
        var booking = await _context.Bookings.FindAsync(id);
        if (booking == null) return NotFound("Booking not found");

        if (booking.Status == BookingStatus.Confirmed) return Ok(new { message = "Already confirmed" });
        if (booking.Status == BookingStatus.Cancelled) return BadRequest("Booking held time expired");
        if (booking.Status != BookingStatus.PendingPayment) return BadRequest("Invalid booking status");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // Fallback for 'sub'
        if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue("sub");
        
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("User not found");
        
        // Check wallet
        if (member.WalletBalance < booking.TotalPrice) 
            return BadRequest($"Insufficient balance. Need {booking.TotalPrice:N0}");

        // Deduct money
        member.WalletBalance -= booking.TotalPrice;
        member.TotalSpent += booking.TotalPrice;

        // Auto Upgrade Tier
        if (member.TotalSpent >= 30000000) member.Tier = MembershipTier.Diamond;
        else if (member.TotalSpent >= 10000000) member.Tier = MembershipTier.Gold;
        else if (member.TotalSpent >= 2000000) member.Tier = MembershipTier.Silver;

        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = -booking.TotalPrice,
            Type = TransactionType.Payment,
            Status = TransactionStatus.Completed,
            Description = $"Booking Confirmed: Court {booking.CourtId}",
            RelatedId = booking.Id.ToString(),
            CreatedDate = DateTime.Now
        };
        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        // Update Booking
        booking.Status = BookingStatus.Confirmed;
        booking.TransactionId = transaction.Id;
        await _context.SaveChangesAsync();

        // SignalR
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");

        return Ok(new { message = "Booking confirmed and paid successfully", transactionId = transaction.Id });
    }
    [HttpPost("recurring")]
    public async Task<IActionResult> CreateRecurringBooking([FromBody] RecurringBookingDto request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        // Validate
        if (request.EndDate <= request.StartDate) return BadRequest("End date must be after start date");

        // Check VIP
        if (member.Tier != MembershipTier.Gold && member.Tier != MembershipTier.Diamond)
        {
            return BadRequest("Chức năng đặt định kỳ chỉ dành cho thành viên hạng Vàng trở lên!");
        }
        
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

        decimal refundAmount = 0;
        decimal penalty = 0;

        // If PendingPayment (Held but not paid), just cancel, no refund, no penalty
        if (booking.Status == BookingStatus.PendingPayment)
        {
            booking.Status = BookingStatus.Cancelled;
            // No transaction needed implies no money moved
        }
        else if (booking.Status == BookingStatus.Confirmed)
        {
            // Policy: 50% refund (50% penalty)
            refundAmount = booking.TotalPrice * 0.5m;
            penalty = booking.TotalPrice * 0.5m;

            booking.Status = BookingStatus.Cancelled;
            booking.Member.WalletBalance += refundAmount;

            var transaction = new WalletTransaction
            {
                MemberId = booking.MemberId,
                Amount = refundAmount,
                Type = TransactionType.Refund,
                Status = TransactionStatus.Completed,
                Description = $"Hoàn tiền hủy sân (50% - Phí hủy: {penalty:N0}đ)",
                RelatedId = booking.Id.ToString(),
                CreatedDate = DateTime.Now
            };
            _context.WalletTransactions.Add(transaction);
        }

        await _context.SaveChangesAsync();
        
        // SignalR: Notify all clients
        await _hubContext.Clients.All.SendAsync("UpdateCalendar");
        
        return Ok(new { 
            message = "Đã hủy sân thành công", 
            refundAmount = refundAmount,
            penalty = penalty,
            newBalance = booking.Member.WalletBalance 
        });
    }
    [HttpGet("my-history")]
    public async Task<ActionResult<IEnumerable<object>>> GetMyBookingHistory()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // Fallback for 'sub'
        if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue("sub");

        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        var bookings = await _context.Bookings
            .Include(b => b.Court)
            .Where(b => b.MemberId == member.Id && (b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.Cancelled || b.Status == BookingStatus.Completed))
            .OrderByDescending(b => b.StartTime)
            .Select(b => new 
            {
                b.Id,
                b.Court.Name,
                b.StartTime,
                b.EndTime,
                b.TotalPrice,
                b.Status, // Enum: 1=Confirmed, 2=Cancelled, 3=Completed
                b.CreatedDate
            })
            .ToListAsync();

        return Ok(bookings);
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
