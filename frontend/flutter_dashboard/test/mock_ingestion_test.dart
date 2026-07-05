import 'package:flutter_test/flutter_test.dart';

import 'package:inboxcfo_dashboard/config/app_config.dart';
import 'package:inboxcfo_dashboard/models/alert.dart';
import 'package:inboxcfo_dashboard/services/ingestion_service.dart';
import 'package:inboxcfo_dashboard/services/supabase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('demo ingestion updates balance, invoices, alerts, and projections', () async {
    final service = SupabaseService.instance;
    await service.initialize();

    final initialBalance = await service.fetchAccountBalance();
    final initialInvoices = await service.fetchRecentInvoices();
    final initialAlerts = await service.fetchAlerts();
    final initialProjections = await service.fetchCashProjections();

    final result = await IngestionService.instance.simulateEmailIngestion();

    final updatedBalance = await service.fetchAccountBalance();
    final updatedInvoices = await service.fetchRecentInvoices();
    final updatedAlerts = await service.fetchAlerts();
    final updatedProjections = await service.fetchCashProjections();

    expect(result.success, isTrue);
    expect(result.message, 'Ingesta simulada (modo demo local)');
    expect(updatedInvoices, hasLength(initialInvoices.length + 1));
    expect(updatedAlerts, hasLength(initialAlerts.length + 1));
    expect(updatedProjections, hasLength(initialProjections.length));

    final newInvoice = updatedInvoices.first;
    expect(newInvoice.vendorName, 'Cliente Nuevo LLC');
    expect(newInvoice.amount, 4200);

    final newAlert = updatedAlerts.first;
    expect(newAlert.severity, AlertSeverity.info);
    expect(newAlert.message, contains('Nueva factura de ingreso detectada'));

    expect(
      updatedBalance?.currentBalance,
      (initialBalance?.currentBalance ?? 0) + newInvoice.amount,
    );
  }, skip: AppConfig.useMockData ? false : 'Requires --dart-define=USE_MOCK_DATA=true');
}
