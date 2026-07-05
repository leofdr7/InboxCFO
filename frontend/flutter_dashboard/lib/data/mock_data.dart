import '../models/account_balance.dart';
import '../models/alert.dart';
import '../models/cash_projection.dart';
import '../models/invoice.dart';

/// Datos locales para desarrollo sin depender del pipeline (horas 3-6).
class MockData {
  static AccountBalance get accountBalance => AccountBalance(
        id: 'mock-balance',
        currentBalance: 48250.75,
        updatedAt: DateTime.now(),
      );

  static List<CashProjection> get cashProjections {
    final today = DateTime.now();
    final startBalance = 48250.75;
    return List.generate(30, (index) {
      final date = today.add(Duration(days: index));
      final income = index % 7 == 0 ? 8500.0 : (index % 5 == 0 ? 3200.0 : 0.0);
      final expenses = index % 4 == 0 ? 4200.0 : (index % 6 == 0 ? 1800.0 : 650.0);
      final balance = startBalance +
          (index * 120) -
          (index * 85) +
          (income > 0 ? income * 0.3 : 0);
      return CashProjection(
        id: 'mock-proj-$index',
        projectionDate: date,
        projectedIncome: income,
        projectedExpenses: expenses,
        projectedBalance: balance,
        riskLevel: balance < 0 ? 'high' : (balance < 5000 ? 'medium' : 'low'),
      );
    });
  }

  static List<Invoice> get invoices => [
        Invoice(
          id: 'inv-1',
          vendorName: 'AWS Cloud Services',
          amount: 1240.50,
          currency: 'USD',
          type: InvoiceType.expense,
          category: 'Infraestructura',
          dueDate: DateTime.now().add(const Duration(days: 5)),
          status: InvoiceStatus.pending,
        ),
        Invoice(
          id: 'inv-2',
          vendorName: 'Cliente Acme Corp',
          amount: 15000.00,
          currency: 'USD',
          type: InvoiceType.income,
          category: 'Ventas',
          dueDate: DateTime.now().add(const Duration(days: 12)),
          status: InvoiceStatus.pending,
        ),
        Invoice(
          id: 'inv-3',
          vendorName: 'Google Workspace',
          amount: 72.00,
          currency: 'USD',
          type: InvoiceType.expense,
          category: 'SaaS',
          dueDate: DateTime.now().subtract(const Duration(days: 2)),
          status: InvoiceStatus.overdue,
        ),
        Invoice(
          id: 'inv-4',
          vendorName: 'Freelancer Design',
          amount: 2800.00,
          currency: 'USD',
          type: InvoiceType.expense,
          category: 'Servicios',
          dueDate: DateTime.now().add(const Duration(days: 8)),
          status: InvoiceStatus.pending,
        ),
        Invoice(
          id: 'inv-5',
          vendorName: 'Cliente Beta Inc',
          amount: 5200.00,
          currency: 'USD',
          type: InvoiceType.income,
          category: 'Ventas',
          dueDate: DateTime.now().add(const Duration(days: 3)),
          status: InvoiceStatus.paid,
        ),
      ];

  static List<Alert> get alerts => [
        Alert(
          id: 'alert-1',
          alertDate: DateTime.now().subtract(const Duration(hours: 2)),
          severity: AlertSeverity.warning,
          message:
              'El balance proyectado caerá bajo \$5,000 en los próximos 14 días.',
        ),
        Alert(
          id: 'alert-2',
          alertDate: DateTime.now().subtract(const Duration(days: 1)),
          severity: AlertSeverity.info,
          message: 'Nueva factura de ingreso detectada: Cliente Acme Corp.',
        ),
      ];
}
