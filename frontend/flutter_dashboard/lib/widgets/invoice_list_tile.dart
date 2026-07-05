import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/invoice.dart';

class InvoiceListTile extends StatelessWidget {
  const InvoiceListTile({super.key, required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    final isIncome = invoice.type == InvoiceType.income;
    final iconColor = isIncome ? Colors.green.shade600 : Colors.red.shade400;
    final icon = isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
    final amountPrefix = isIncome ? '+' : '-';
    final currencyFormat = NumberFormat.currency(
      symbol: invoice.currency == 'USD' ? '\$' : '${invoice.currency} ',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'es');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.12),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        invoice.vendorName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${_typeLabel(invoice.type)} · Vence ${dateFormat.format(invoice.dueDate)}',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 13),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$amountPrefix${currencyFormat.format(invoice.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 2),
          _StatusChip(status: invoice.status),
        ],
      ),
    );
  }

  String _typeLabel(InvoiceType type) {
    switch (type) {
      case InvoiceType.income:
        return 'Ingreso';
      case InvoiceType.expense:
        return 'Gasto';
      case InvoiceType.unknown:
        return 'Otro';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      InvoiceStatus.pending => ('Pendiente', Colors.orange.shade700),
      InvoiceStatus.paid => ('Pagada', Colors.green.shade700),
      InvoiceStatus.overdue => ('Vencida', Colors.red.shade700),
      InvoiceStatus.unknown => ('—', Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
