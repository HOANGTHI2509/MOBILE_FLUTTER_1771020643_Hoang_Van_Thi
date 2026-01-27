class Court643 {
  final int id;
  final String name;
  final bool isActive;
  final String? description;
  final double pricePerHour;

  Court643({
    required this.id,
    required this.name,
    required this.isActive,
    this.description,
    required this.pricePerHour,
  });

  factory Court643.fromJson(Map<String, dynamic> json) {
    return Court643(
      id: json['id'],
      name: json['name'],
      isActive: json['isActive'],
      description: json['description'],
      pricePerHour: (json['pricePerHour'] ?? 0).toDouble(),
    );
  }
}
