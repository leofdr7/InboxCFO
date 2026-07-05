import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    super.key,
    required this.alerts,
    this.onDismiss,
  });

  final List<Alert> alerts;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final activeAlerts = alerts
        .where((a) =>
            a.severity == AlertSeverity.critical ||
            a.severity == AlertSeverity.warning)
        .toList();

    if (activeAlerts.isEmpty) return const SizedBox.shrink();

    final topAlert = activeAlerts.first;
    final (bgColor, iconColor, icon) = _styleFor(context, topAlert.severity);
    final timeFormat = DateFormat('HH:mm', 'es');

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _severityLabel(topAlert.severity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topAlert.message,
                    style: TextStyle(color: iconColor.withValues(alpha: 0.9)),
                  ),
                  if (activeAlerts.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${activeAlerts.length - 1} alerta(s) más',
                        style: TextStyle(
                          fontSize: 12,
                          color: iconColor.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              timeFormat.format(topAlert.alertDate),
              style: TextStyle(fontSize: 12, color: iconColor.withValues(alpha: 0.7)),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: iconColor, size: 20),
                onPressed: onDismiss,
                tooltip: 'Ocultar',
              ),
            ],
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _styleFor(BuildContext context, AlertSeverity severity) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (severity) {
      case AlertSeverity.critical:
        return (
          isDark ? Colors.red.shade900.withValues(alpha: 0.5) : Colors.red.shade50,
          isDark ? Colors.red.shade300 : Colors.red.shade800,
          Icons.error_rounded,
        );
      case AlertSeverity.warning:
        return (
          isDark ? Colors.amber.shade900.withValues(alpha: 0.4) : Colors.amber.shade50,
          isDark ? Colors.amber.shade200 : Colors.amber.shade900,
          Icons.warning_amber_rounded,
        );
      case AlertSeverity.info:
        return (
          isDark ? Colors.blue.shade900.withValues(alpha: 0.4) : Colors.blue.shade50,
          isDark ? Colors.blue.shade200 : Colors.blue.shade800,
          Icons.info_outline,
        );
      case AlertSeverity.unknown:
        return (
          isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          isDark ? Colors.grey.shade300 : Colors.grey.shade800,
          Icons.help_outline,
        );
    }
  }

  String _severityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return 'ALERTA CRÍTICA';
      case AlertSeverity.warning:
        return 'ADVERTENCIA';
      case AlertSeverity.info:
        return 'INFORMACIÓN';
      case AlertSeverity.unknown:
        return 'ALERTA';
    }
  }
}

/// Panel lateral con historial completo de alertas (incluye info).
class AlertsPanel extends StatelessWidget {
  const AlertsPanel({super.key, required this.alerts});

  final List<Alert> alerts;

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor;

    if (alerts.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Sin alertas activas')),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.notifications_active_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  'Alertas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final (bgColor, fgColor, icon) = _itemStyle(alert.severity);
              final timeFormat = DateFormat('dd/MM HH:mm', 'es');

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: bgColor,
                  child: Icon(icon, size: 18, color: fgColor),
                ),
                title: Text(
                  alert.message,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  timeFormat.format(alert.alertDate),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _itemStyle(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return (Colors.red.shade100, Colors.red.shade800, Icons.error_outline);
      case AlertSeverity.warning:
        return (Colors.amber.shade100, Colors.amber.shade900, Icons.warning_amber);
      case AlertSeverity.info:
        return (Colors.blue.shade100, Colors.blue.shade800, Icons.info_outline);
      case AlertSeverity.unknown:
        return (Colors.grey.shade200, Colors.grey.shade700, Icons.help_outline);
    }
  }
}
