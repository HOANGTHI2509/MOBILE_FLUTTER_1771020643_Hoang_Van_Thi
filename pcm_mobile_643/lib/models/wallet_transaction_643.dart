
enum TransactionType { Deposit, Withdraw, Payment, Refund, Reward }
enum TransactionStatus { Pending, Completed, Rejected, Failed }

class WalletTransaction643 {
  final int id;
  final int memberId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String? description;
  final DateTime createdDate;

  WalletTransaction643({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.type,
    required this.status,
    this.description,
    required this.createdDate,
  });

  factory WalletTransaction643.fromJson(Map<String, dynamic> json) {
    return WalletTransaction643(
      id: json['id'],
      memberId: json['memberId'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: TransactionType.values[json['type'] ?? 0],
      status: TransactionStatus.values[json['status'] ?? 0],
      description: json['description'],
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
