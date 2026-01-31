enum BookingStatus { PendingPayment, Confirmed, Cancelled, Completed }

class Booking643 {
  final int id;
  final int courtId;
  final int memberId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final BookingStatus status;
  final bool isRecurring;

  Booking643({
    required this.id,
    required this.courtId,
    required this.memberId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    this.isRecurring = false,
  });

  factory Booking643.fromJson(Map<String, dynamic> json) {
    return Booking643(
      id: json['id'] ?? 0,
      courtId: json['courtId'] ?? 0,
      memberId: json['memberId'] ?? 0,
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now(),
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: BookingStatus.values[json['status'] ?? 0],
      isRecurring: json['isRecurring'] ?? false,
    );
  }
}
