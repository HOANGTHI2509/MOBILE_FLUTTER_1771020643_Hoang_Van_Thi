using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using PcmBackend.Hubs;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] // Yêu cầu đăng nhập để sử dụng
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<PcmHub> _hubContext;

    public MembersController(ApplicationDbContext context, IHubContext<PcmHub> hubContext)
    {
        _context = context;
        _hubContext = hubContext;
    }

    // ... (Existing Methods)

    // [Admin] Approve Deposit
    [HttpPost("{transactionId}/approve-deposit")]
    public async Task<IActionResult> ApproveDeposit(int transactionId)
    {
        var transaction = await _context.WalletTransactions.Include(t => t.Member).FirstOrDefaultAsync(t => t.Id == transactionId);
        if (transaction == null) return NotFound("Transaction not found");

        if (transaction.Status == TransactionStatus.Completed) return BadRequest("Already completed");
        if (transaction.Type != TransactionType.Deposit) return BadRequest("Not a deposit transaction");

        // Update Wallet
        transaction.Status = TransactionStatus.Completed;
        transaction.Member.WalletBalance += transaction.Amount;
        
        await _context.SaveChangesAsync();

        // Notify User
        // Note: member.UserId must match the SignalR UserIdentifier used by the client connection
        await _hubContext.Clients.User(transaction.Member.UserId).SendAsync("ReceiveNotification", $"Nạp tiền thành công! +{transaction.Amount:N0}đ");

        return Ok(new { message = "Deposit approved", newBalance = transaction.Member.WalletBalance });
    }


    // Lấy thông tin cá nhân và số dư ví
    [HttpGet("profile")]
    public async Task<ActionResult> GetProfile()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userEmail = User.FindFirstValue(ClaimTypes.Email) ?? "unknown@pcm.com";
        
        // Tìm hoặc TẠO MỚI member nếu chưa tồn tại
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);

        if (member == null) 
        {
            // Auto-create member record for authenticated user
            member = new Member
            {
                UserId = userId,
                FullName = userEmail.Split('@')[0],
                Email = userEmail,
                JoinDate = DateTime.Now,
                IsActive = true,
                IsAdmin = userEmail.ToLower().Contains("admin"), // Auto-detect admin
                Tier = MembershipTier.Standard,
                WalletBalance = 0,
                TotalSpent = 0,
                RankLevel = 2.5
            };
            _context.Members.Add(member);
            await _context.SaveChangesAsync();
        }
        
        return Ok(member);
    }

    // Gửi yêu cầu nạp tiền (Trạng thái Pending)
    [HttpPost("deposit")]
    public async Task<IActionResult> Deposit([FromForm] DepositDto request)
    {
        if (request.Amount <= 0) return BadRequest("Số tiền phải lớn hơn 0.");

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        var userEmail = User.FindFirstValue(ClaimTypes.Email) ?? "unknown@pcm.com";
        
        // Tìm hoặc TẠO MỚI member nếu chưa tồn tại
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        
        if (member == null) 
        {
            // Auto-create member record for authenticated user
            member = new Member
            {
                UserId = userId,
                FullName = userEmail.Split('@')[0], // Use email prefix as name
                Email = userEmail,
                JoinDate = DateTime.Now,
                IsActive = true,
                IsAdmin = false,
                Tier = MembershipTier.Standard,
                WalletBalance = 0,
                TotalSpent = 0,
                RankLevel = 2.5
            };
            _context.Members.Add(member);
            await _context.SaveChangesAsync();
        }

        string? imageUrl = null;
        if (request.Image != null)
        {
            var uploads = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads");
            if (!Directory.Exists(uploads)) Directory.CreateDirectory(uploads);
            
            var fileName = $"{Guid.NewGuid()}{Path.GetExtension(request.Image.FileName)}";
            var filePath = Path.Combine(uploads, fileName);
            
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await request.Image.CopyToAsync(stream);
            }
            imageUrl = $"/uploads/{fileName}";
        }

        var transaction = new WalletTransaction
        {
            MemberId = member.Id,
            Amount = request.Amount,
            Type = TransactionType.Deposit,
            Status = TransactionStatus.Pending,
            Description = $"Nạp tiền: {request.Amount:N0}đ",
            ProofImageUrl = imageUrl,
            CreatedDate = DateTime.Now
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Yêu cầu nạp tiền đã được gửi.", id = transaction.Id });
    }

    public class DepositDto 
    {
        public decimal Amount { get; set; }
        public IFormFile? Image { get; set; }
    }
    // [Admin] Lấy danh sách hội viên (có lọc)
    [HttpGet]
    // [Authorize(Roles = "Admin")]
    public async Task<ActionResult<IEnumerable<Member>>> GetMembers([FromQuery] string? search, [FromQuery] MembershipTier? tier)
    {
        var query = _context.Members.AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(m => m.FullName.Contains(search) || m.Email.Contains(search) || m.UserId.Contains(search));
        }

        if (tier.HasValue)
        {
            query = query.Where(m => m.Tier == tier.Value);
        }

        return await query.ToListAsync();
    }

    // [Admin] Lock/Unlock
    [HttpPut("{id}/status")]
    // [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] StatusUpdateDto update)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        member.IsActive = update.IsActive;
        await _context.SaveChangesAsync();
        return Ok(new { message = $"Member status updated to {update.IsActive}" });
    }

    // [Admin] Update Rank/Tier
    [HttpPut("{id}/rank")]
    // [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateRank(int id, [FromBody] UpdateRankDto request)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        bool rankChanged = false;
        double oldRank = member.RankLevel;

        if (request.RankLevel.HasValue && request.RankLevel.Value != member.RankLevel) 
        {
            member.RankLevel = request.RankLevel.Value;
            rankChanged = true;
        }
        if (request.Tier.HasValue) member.Tier = request.Tier.Value;

        if (rankChanged)
        {
             var history = new RankHistory 
             {
                 MemberId = member.Id,
                 RankLevel = member.RankLevel,
                 Reason = "Admin Update",
                 CreatedDate = DateTime.Now
             };
             _context.RankHistories.Add(history);
        }

        await _context.SaveChangesAsync();
        return Ok(new { message = "Member rank/tier updated" });
    }

    // Get Rank History (For Chart)
    [HttpGet("rank-history")]
    public async Task<ActionResult<IEnumerable<RankHistory>>> GetRankHistory()
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        // Find member first
        var member = await _context.Members.FirstOrDefaultAsync(m => m.UserId == userId);
        if (member == null) return NotFound("Member not found");

        var history = await _context.RankHistories
            .Where(h => h.MemberId == member.Id)
            .OrderBy(h => h.CreatedDate)
            .ToListAsync();

        return Ok(history);
    }
}

public class UpdateRankDto
{
    public double? RankLevel { get; set; }
    public MembershipTier? Tier { get; set; }
}