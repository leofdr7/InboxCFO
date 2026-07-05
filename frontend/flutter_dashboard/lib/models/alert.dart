enum AlertSeverity { info, warning, critical, unknown }

class Alert {
  const Alert({
    required this.alertDate,
    required this.severity,
    required this.message,
    this.id,
  });

  final String? id;
  final DateTime alertDate;
  final AlertSeverity severity;
  final String message;

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id']?.toString(),
      alertDate: DateTime.parse(json['alert_date'] as String),
      severity: _parseSeverity(json['severity'] as String?),
      message: json['message'] as String? ?? '',
    );
  }

  static AlertSeverity _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'info':
        return AlertSeverity.info;
      case 'warning':
        return AlertSeverity.warning;
      case 'critical':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.unknown;
    }
  }

  bool get isActive =>
      severity == AlertSeverity.warning ||
      severity == AlertSeverity.critical;
}
