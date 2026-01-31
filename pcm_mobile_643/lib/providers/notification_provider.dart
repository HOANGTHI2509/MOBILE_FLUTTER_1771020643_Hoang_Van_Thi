import 'package:flutter/material.dart';
import '../models/notification_643.dart';

class NotificationProvider extends ChangeNotifier {
  final List<Notification643> _notifications = [];

  List<Notification643> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(String message, {NotificationType type = NotificationType.Info}) {
    final notification = Notification643(
      id: DateTime.now().millisecondsSinceEpoch,
      message: message,
      type: type,
      isRead: false,
      createdDate: DateTime.now(),
    );
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = Notification643(
        id: old.id,
        message: old.message,
        type: old.type,
        isRead: true,
        createdDate: old.createdDate,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
        final old = _notifications[i];
        _notifications[i] = Notification643(
        id: old.id,
        message: old.message,
        type: old.type,
        isRead: true,
        createdDate: old.createdDate,
      );
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
