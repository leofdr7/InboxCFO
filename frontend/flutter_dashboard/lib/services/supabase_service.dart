import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';
import '../data/mock_data.dart';
import '../models/account_balance.dart';
import '../models/alert.dart';
import '../models/cash_projection.dart';
import '../models/invoice.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  RealtimeChannel? _alertsChannel;
  final _alertsController = StreamController<List<Alert>>.broadcast();

  /// Estado mutable solo en modo mock (simula Realtime localmente).
  AccountBalance? _mockBalance;
  List<CashProjection> _mockProjections = [];
  List<Alert> _mockAlerts = [];
  List<Invoice> _mockInvoices = [];

  Stream<List<Alert>> get alertsStream => _alertsController.stream;

  bool get useMock => AppConfig.useMockData || !SupabaseConfig.isConfigured;

  Future<void> initialize() async {
    if (useMock) {
      _mockBalance = MockData.accountBalance;
      _mockProjections = List.from(MockData.cashProjections);
      _mockAlerts = List.from(MockData.alerts);
      _mockInvoices = List.from(MockData.invoices);
      return;
    }

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  SupabaseClient get _client => Supabase.instance.client;

  Future<AccountBalance?> fetchAccountBalance() async {
    if (useMock) return _mockBalance ?? MockData.accountBalance;

    final response = await _client
        .from('account_balance')
        .select()
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return AccountBalance.fromJson(response);
  }

  Future<List<CashProjection>> fetchCashProjections() async {
    if (useMock) return List.from(_mockProjections);

    final today = DateTime.now();
    final endDate = today.add(const Duration(days: AppConfig.projectionDays));

    final response = await _client
        .from('cash_projections')
        .select()
        .gte('projection_date', _dateOnly(today))
        .lte('projection_date', _dateOnly(endDate))
        .order('projection_date', ascending: true);

    return (response as List)
        .map((row) => CashProjection.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Invoice>> fetchRecentInvoices() async {
    if (useMock) return List.from(_mockInvoices);

    final response = await _client
        .from('invoices')
        .select()
        .order('due_date', ascending: false)
        .limit(AppConfig.recentInvoicesLimit);

    return (response as List)
        .map((row) => Invoice.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<Alert>> fetchAlerts() async {
    if (useMock) return List.from(_mockAlerts);

    final response = await _client
        .from('alerts')
        .select()
        .order('alert_date', ascending: false)
        .limit(20);

    return (response as List)
        .map((row) => Alert.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> subscribeToAlerts() async {
    final initial = await fetchAlerts();
    _alertsController.add(initial);

    if (useMock) return;

    _alertsChannel?.unsubscribe();

    _alertsChannel = _client
        .channel('inboxcfo-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerts',
          callback: (payload) async {
            final refreshed = await fetchAlerts();
            _alertsController.add(refreshed);
          },
        )
        .subscribe();
  }

  void dispose() {
    _alertsChannel?.unsubscribe();
    _alertsController.close();
  }

  /// Simula el flujo completo de ingesta en modo demo.
  /// La factura detectada actualiza KPIs, gráfico, lista y alertas.
  Future<void> simulateMockIngestion() async {
    if (!useMock) return;

    await Future.delayed(const Duration(milliseconds: 900));

    final detectedEmailNumber = _mockInvoices.length + 1;
    final isIncome = detectedEmailNumber.isEven;
    final amount = isIncome ? 4200.00 : 1890.00;
    final vendorName = isIncome ? 'Cliente Nuevo LLC' : 'Proveedor Detectado S.A.';
    final dueDate = DateTime.now().add(Duration(days: isIncome ? 7 : 15));

    final newInvoice = Invoice(
      id: 'inv-mock-${DateTime.now().millisecondsSinceEpoch}',
      vendorName: vendorName,
      amount: amount,
      currency: 'USD',
      type: isIncome ? InvoiceType.income : InvoiceType.expense,
      category: isIncome ? 'Ventas' : 'Servicios',
      dueDate: dueDate,
      status: InvoiceStatus.pending,
    );

    _applyInvoiceToMockFinancials(newInvoice);

    final newAlert = Alert(
      id: 'alert-mock-${DateTime.now().millisecondsSinceEpoch}',
      alertDate: DateTime.now(),
      severity: isIncome ? AlertSeverity.info : AlertSeverity.warning,
      message:
          'Nueva factura de ${isIncome ? 'ingreso' : 'gasto'} detectada: '
          '${newInvoice.vendorName} (${isIncome ? '+' : '-'}\$${amount.toStringAsFixed(2)})',
    );

    _mockInvoices = [newInvoice, ..._mockInvoices];
    _mockAlerts = [newAlert, ..._mockAlerts];
    _alertsController.add(List.from(_mockAlerts));
  }

  void _applyInvoiceToMockFinancials(Invoice invoice) {
    final currentBalance = _mockBalance ?? MockData.accountBalance;
    final balanceDelta =
        invoice.type == InvoiceType.income ? invoice.amount : -invoice.amount;

    // En modo demo el correo detectado impacta el balance para que los KPIs
    // respondan visualmente durante la presentación.
    _mockBalance = AccountBalance(
      id: currentBalance.id,
      currentBalance: currentBalance.currentBalance + balanceDelta,
      updatedAt: DateTime.now(),
    );

    _mockProjections = _mockProjections.map((projection) {
      final appliesFromDueDate =
          !projection.projectionDate.isBefore(_dateOnlyAsDate(invoice.dueDate));
      final appliesOnDueDate =
          _isSameDate(projection.projectionDate, invoice.dueDate);

      return CashProjection(
        id: projection.id,
        projectionDate: projection.projectionDate,
        projectedIncome: projection.projectedIncome +
            (invoice.type == InvoiceType.income && appliesOnDueDate
                ? invoice.amount
                : 0),
        projectedExpenses: projection.projectedExpenses +
            (invoice.type == InvoiceType.expense && appliesOnDueDate
                ? invoice.amount
                : 0),
        projectedBalance: projection.projectedBalance +
            (appliesFromDueDate ? balanceDelta : 0),
        riskLevel: _riskLevelFor(
          projection.projectedBalance + (appliesFromDueDate ? balanceDelta : 0),
        ),
      );
    }).toList();
  }

  String _riskLevelFor(double balance) {
    if (balance < AppConfig.riskThreshold) return 'high';
    if (balance < 5000) return 'medium';
    return 'low';
  }

  String _dateOnly(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _dateOnlyAsDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
