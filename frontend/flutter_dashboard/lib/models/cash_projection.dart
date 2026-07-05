class CashProjection {
  const CashProjection({
    required this.projectionDate,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedBalance,
    this.riskLevel,
    this.id,
  });

  final String? id;
  final DateTime projectionDate;
  final double projectedIncome;
  final double projectedExpenses;
  final double projectedBalance;
  final String? riskLevel;

  factory CashProjection.fromJson(Map<String, dynamic> json) {
    return CashProjection(
      id: json['id']?.toString(),
      projectionDate: DateTime.parse(json['projection_date'] as String),
      projectedIncome: _toDouble(json['projected_income']),
      projectedExpenses: _toDouble(json['projected_expenses']),
      projectedBalance: _toDouble(json['projected_balance']),
      riskLevel: json['risk_level'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
