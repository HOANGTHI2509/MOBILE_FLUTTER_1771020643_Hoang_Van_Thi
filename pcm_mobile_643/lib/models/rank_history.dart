class RankHistory {
  final int id;
  final int memberId;
  final double rankLevel;
  final String reason;
  final DateTime createdDate;

  RankHistory({
    required this.id,
    required this.memberId,
    required this.rankLevel,
    required this.createdDate,
    required this.reason,
  });

  factory RankHistory.fromJson(Map<String, dynamic> json) {
    return RankHistory(
      id: json['id'],
      memberId: json['memberId'],
      rankLevel: (json['rankLevel'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      createdDate: DateTime.parse(json['createdDate']),
    );
  }
}
