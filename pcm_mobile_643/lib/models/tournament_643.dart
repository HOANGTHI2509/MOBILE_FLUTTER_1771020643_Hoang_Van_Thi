enum TournamentFormat { RoundRobin, Knockout, Hybrid }
enum TournamentStatus { Open, Registering, DrawCompleted, Ongoing, Finished }

class Tournament643 {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final TournamentFormat format;
  final double entryFee;
  final double prizePool;
  final TournamentStatus status;
  final bool isJoined;

  Tournament643({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.format,
    required this.entryFee,
    required this.prizePool,
    required this.status,
    this.isJoined = false,
  });

  factory Tournament643.fromJson(Map<String, dynamic> json) {
    return Tournament643(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      format: TournamentFormat.values[json['format'] ?? 0],
      entryFee: (json['entryFee'] ?? 0).toDouble(),
      prizePool: (json['prizePool'] ?? 0).toDouble(),
      status: TournamentStatus.values[json['status'] ?? 0],
      isJoined: json['isJoined'] ?? false,
    );
  }
}
