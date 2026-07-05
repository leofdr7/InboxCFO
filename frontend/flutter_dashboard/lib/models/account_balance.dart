class AccountBalance {
  const AccountBalance({
    required this.currentBalance,
    required this.updatedAt,
    this.id,
  });

  final String? id;
  final double currentBalance;
  final DateTime updatedAt;

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: json['id']?.toString(),
      currentBalance: _toDouble(json['current_balance']),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
