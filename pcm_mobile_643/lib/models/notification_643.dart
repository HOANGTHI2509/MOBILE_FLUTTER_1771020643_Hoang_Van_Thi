enum NotificationType { Info, Success, Warning, Error }

class Notification643 {
  final int id;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdDate;

  Notification643({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdDate,
  });

  factory Notification643.fromJson(Map<String, dynamic> json) {
    return Notification643(
      id: json['id'],
      message: json['message'],
      type: NotificationType.values[json['type'] ?? 0],
      isRead: json['isRead'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
