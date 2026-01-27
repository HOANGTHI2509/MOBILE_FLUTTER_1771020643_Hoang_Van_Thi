using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;
using System.Security.Claims;

namespace PcmBackend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] // Yêu cầu đăng nhập để sử dụng
public class MembersController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public MembersController(ApplicationDbContext context)
    {
        _context = context;
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
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] bool isActive)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        member.IsActive = isActive;
        await _context.SaveChangesAsync();
        return Ok(new { message = $"Member status updated to {isActive}" });
    }

    // [Admin] Update Rank/Tier
    [HttpPut("{id}/rank")]
    // [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateRank(int id, [FromBody] UpdateRankDto request)
    {
        var member = await _context.Members.FindAsync(id);
        if (member == null) return NotFound();

        if (request.RankLevel.HasValue) member.RankLevel = request.RankLevel.Value;
        if (request.Tier.HasValue) member.Tier = request.Tier.Value;

        await _context.SaveChangesAsync();
        return Ok(new { message = "Member rank/tier updated" });
    }
}

public class UpdateRankDto
{
    public double? RankLevel { get; set; }
    public MembershipTier? Tier { get; set; }
}