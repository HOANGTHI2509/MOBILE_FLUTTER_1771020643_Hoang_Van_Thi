enum MatchStatus { Scheduled, InProgress, Finished }
enum WinningSide { None, Team1, Team2 }

class Match643 {
  final int id;
  final String roundName;
  final DateTime date;
  final int score1;
  final int score2;
  final MatchStatus status;
  final WinningSide winningSide;
  final String? details;

  Match643({
    required this.id,
    required this.roundName,
    required this.date,
    required this.score1,
    required this.score2,
    required this.status,
    required this.winningSide,
    this.details,
  });

  factory Match643.fromJson(Map<String, dynamic> json) {
    return Match643(
      id: json['id'],
      roundName: json['roundName'],
      date: DateTime.parse(json['date']),
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      status: MatchStatus.values[json['status'] ?? 0],
      winningSide: WinningSide.values[json['winningSide'] ?? 0],
      details: json['details'],
    );
  }
}
