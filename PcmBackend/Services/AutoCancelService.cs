using Microsoft.EntityFrameworkCore;
using PcmBackend.Data;
using PcmBackend.Models;

namespace PcmBackend.Services;

public class AutoCancelService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<AutoCancelService> _logger;

    public AutoCancelService(IServiceProvider serviceProvider, ILogger<AutoCancelService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("AutoCancelService is running.");

        while (!stoppingToken.IsCancellationRequested)
        {
            try 
            {
                using (var scope = _serviceProvider.CreateScope())
                {
                    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                    
                    // Tìm các booking PendingPayment quá 5 phút
                    var threshold = DateTime.Now.AddMinutes(-5);
                    var expiredBookings = await context.Bookings
                        .Where(b => b.Status == BookingStatus.PendingPayment && b.CreatedDate < threshold)
                        .ToListAsync(stoppingToken);

                    if (expiredBookings.Any())
                    {
                        foreach (var booking in expiredBookings)
                        {
                            booking.Status = BookingStatus.Cancelled;
                            _logger.LogInformation($"Auto-cancelling expired booking #{booking.Id}");
                        }
                        await context.SaveChangesAsync(stoppingToken);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in AutoCancelService");
            }

            // Chờ 1 phút rồi chạy lại
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
}
