class Member643 {
  final String id;
  final String email;
  final String fullName;
  final double walletBalance;
  final String tier;
  final bool isAdmin;

  Member643({
    required this.id,
    required this.email,
    required this.fullName,
    required this.walletBalance,
    required this.tier,
    this.isAdmin = false,
  });

  factory Member643.fromJson(Map<String, dynamic> json) {
    // API có thể trả về 'isAdmin' hoặc 'IsAdmin' tùy naming policy (C# mặc định là PascalCase nhưng often serialize camelCase)
    // C# default JSON serializer thường giữ nguyên PascalCase trừ khi config camelCase. 
    // Check cả 2 cho chắc.
    return Member643(
      id: json['id'] != null ? json['id'].toString() : '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? 'Hội viên 643',
      walletBalance: (json['walletBalance'] ?? 0).toDouble(),
      tier: json['tier'] == 1 ? 'Silver' : (json['tier'] == 2 ? 'Gold' : (json['tier'] == 3 ? 'Diamond' : 'Standard')), 
      isAdmin: json['isAdmin'] == true || json['IsAdmin'] == true,
    );
  }
}