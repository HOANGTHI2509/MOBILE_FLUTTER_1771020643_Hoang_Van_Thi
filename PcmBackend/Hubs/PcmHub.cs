using Microsoft.AspNetCore.SignalR;

namespace PcmBackend.Hubs;

public class PcmHub : Hub
{
    // Client gọi hàm này để tham gia nhóm trận đấu (để nhận cập nhật điểm số realtime)
    public async Task JoinMatchGroup(string matchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Match_{matchId}");
    }

    // Server dùng hàm này để gửi noti (demo)
    public async Task SendNotification(string userId, string message)
    {
        await Clients.User(userId).SendAsync("ReceiveNotification", message);
    }
}
