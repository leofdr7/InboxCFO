enum InvoiceType { income, expense, unknown }

enum InvoiceStatus { pending, paid, overdue, unknown }

class Invoice {
  const Invoice({
    required this.vendorName,
    required this.amount,
    required this.type,
    required this.dueDate,
    required this.status,
    this.currency = 'USD',
    this.category,
    this.id,
  });

  final String? id;
  final String vendorName;
  final double amount;
  final String currency;
  final InvoiceType type;
  final String? category;
  final DateTime dueDate;
  final InvoiceStatus status;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString(),
      vendorName: json['vendor_name'] as String? ?? 'Sin nombre',
      amount: _toDouble(json['amount']),
      currency: json['currency'] as String? ?? 'USD',
      type: _parseType(json['type'] as String?),
      category: json['category'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: _parseStatus(json['status'] as String?),
    );
  }

  static InvoiceType _parseType(String? value) {
    switch (value?.toLowerCase()) {
      case 'income':
        return InvoiceType.income;
      case 'expense':
        return InvoiceType.expense;
      default:
        return InvoiceType.unknown;
    }
  }

  static InvoiceStatus _parseStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return InvoiceStatus.pending;
      case 'paid':
        return InvoiceStatus.paid;
      case 'overdue':
        return InvoiceStatus.overdue;
      default:
        return InvoiceStatus.unknown;
    }
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
