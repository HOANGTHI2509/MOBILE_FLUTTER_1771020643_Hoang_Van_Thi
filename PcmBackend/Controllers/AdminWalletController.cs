using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Controllers;

[Route("api/admin/wallet")]
[ApiController]
// [Authorize(Roles = "Admin")] // Uncomment when roles are set up
public class AdminWalletController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public AdminWalletController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet("pending")]
    public async Task<ActionResult<IEnumerable<WalletTransaction>>> GetPendingDeposits()
    {
        return await _context.WalletTransactions
            .Include(t => t.Member)
            .Where(t => t.Status == TransactionStatus.Pending && t.Type == TransactionType.Deposit)
            .OrderByDescending(t => t.CreatedDate)
            .ToListAsync();
    }

    [HttpGet("stats")]
    public async Task<ActionResult<object>> GetRevenueStats()
    {
        var now = DateTime.Now;
        var startOfMonth = new DateTime(now.Year, now.Month, 1);
        
        // Stats for this month
        var monthlyTrans = await _context.WalletTransactions
            .Where(t => t.CreatedDate >= startOfMonth)
            .ToListAsync();
            
        var totalDeposit = monthlyTrans.Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed).Sum(t => t.Amount);
        var totalPayment = monthlyTrans.Where(t => t.Type == TransactionType.Payment && t.Status == TransactionStatus.Completed).Sum(t => Math.Abs(t.Amount));
        var totalRefund = monthlyTrans.Where(t => t.Type == TransactionType.Refund).Sum(t => t.Amount);

        // Weekly Breakdown for Current Month (W1, W2, W3, W4)
        var weeklyStats = monthlyTrans
            .Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed)
            .GroupBy(t => (t.CreatedDate.Day - 1) / 7 + 1) // Simple week calc: 1-7=W1, 8-14=W2...
            .Select(g => new { Week = g.Key, Amount = g.Sum(t => t.Amount) })
            .OrderBy(x => x.Week)
            .ToList();
        
        // Ensure 4 weeks are present
        var finalWeeklyStats = new List<object>();
        for (int i = 1; i <= 4; i++)
        {
            var weekData = weeklyStats.FirstOrDefault(w => w.Week == i);
            finalWeeklyStats.Add(new { Week = i, Amount = weekData?.Amount ?? 0 });
        }
        
        // 6-month chart data (keeping existing logic)
        var chartData = await _context.WalletTransactions
            .Where(t => t.CreatedDate >= now.AddMonths(-5))
            .GroupBy(t => new { t.CreatedDate.Year, t.CreatedDate.Month })
            .Select(g => new 
            {
                Month = $"{g.Key.Month}/{g.Key.Year}",
                Income = g.Where(t => t.Type == TransactionType.Deposit && t.Status == TransactionStatus.Completed).Sum(t => t.Amount),
                Revenue = g.Where(t => t.Type == TransactionType.Payment && t.Status == TransactionStatus.Completed).Sum(t => Math.Abs(t.Amount))
            })
            .ToListAsync();
            
        return Ok(new { 
            CurrentMonth = new { TotalDeposit = totalDeposit, TotalPayment = totalPayment, TotalRefund = totalRefund },
            WeeklyStats = finalWeeklyStats,
            ChartData = chartData
        });
    }

    [HttpPut("approve/{transactionId}")]
    public async Task<IActionResult> ApproveDeposit(int transactionId)
    {
        var transaction = await _context.WalletTransactions.FindAsync(transactionId);
        if (transaction == null) return NotFound();
        
        if (transaction.Status != TransactionStatus.Pending || transaction.Type != TransactionType.Deposit)
            return BadRequest("Invalid transaction state");
            
        var member = await _context.Members.FindAsync(transaction.MemberId);
        if (member == null) return NotFound("Member not found");
        
        // Update balance
        member.WalletBalance += transaction.Amount;
        transaction.Status = TransactionStatus.Completed;
        
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Approved successfully", newBalance = member.WalletBalance });
    }
    
    [HttpPost("reject/{transactionId}")]
    public async Task<IActionResult> RejectDeposit(int transactionId)
    {
        var transaction = await _context.WalletTransactions.FindAsync(transactionId);
        if (transaction == null) return NotFound();
        
        if (transaction.Status != TransactionStatus.Pending) return BadRequest("Not pending");
        
        transaction.Status = TransactionStatus.Failed; // Or Rejected
        await _context.SaveChangesAsync();
        
        return Ok(new { message = "Rejected" });
    }
}
