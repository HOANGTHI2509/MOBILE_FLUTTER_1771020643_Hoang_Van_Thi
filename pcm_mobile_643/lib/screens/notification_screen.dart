import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/notification_643.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            tooltip: "Đánh dấu tất cả đã đọc",
            onPressed: notifications.isEmpty ? null : () {
               provider.markAllAsRead();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
             tooltip: "Xóa tất cả",
            onPressed: notifications.isEmpty ? null : () {
              provider.clearAll();
            },
          )
        ],
      ),
      body: notifications.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                const Text("Không có thông báo nào", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final n = notifications[i];
              return ListTile(
                tileColor: n.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: n.isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                  child: Icon(
                    _getIcon(n.type),
                    color: n.isRead ? Colors.grey : Colors.blue,
                    size: 20
                  ),
                ),
                title: Text(n.message, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(DateFormat('HH:mm dd/MM/yyyy').format(n.createdDate), style: const TextStyle(fontSize: 12)),
                onTap: () {
                  provider.markAsRead(n.id);
                },
              );
            },
          ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.Success: return Icons.check_circle;
      case NotificationType.Warning: return Icons.warning;
      case NotificationType.Error: return Icons.error;
      default: return Icons.info;
    }
  }
}
