import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account_balance.dart';
import '../models/alert.dart';
import '../models/cash_projection.dart';
import '../models/invoice.dart';
import '../services/ingestion_service.dart';
import '../services/supabase_service.dart';
import '../widgets/alert_banner.dart';
import '../widgets/cashflow_chart.dart';
import '../widgets/invoice_list_tile.dart';
import '../theme/theme_controller.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = SupabaseService.instance;
  final _ingestion = IngestionService.instance;

  AccountBalance? _balance;
  List<CashProjection> _projections = [];
  List<Invoice> _invoices = [];
  List<Alert> _alerts = [];
  bool _loading = true;
  bool _ingesting = false;
  String? _error;
  bool _bannerDismissed = false;

  StreamSubscription<List<Alert>>? _alertsSub;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _alertsSub = _service.alertsStream.listen((alerts) {
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _bannerDismissed = false;
        });
      }
    });
    _service.subscribeToAlerts();
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.fetchAccountBalance(),
        _service.fetchCashProjections(),
        _service.fetchRecentInvoices(),
        _service.fetchAlerts(),
      ]);

      if (!mounted) return;

      setState(() {
        _balance = results[0] as AccountBalance?;
        _projections = results[1] as List<CashProjection>;
        _invoices = results[2] as List<Invoice>;
        _alerts = results[3] as List<Alert>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _simulateIngestion() async {
    setState(() => _ingesting = true);

    final result = await _ingestion.simulateEmailIngestion();

    if (!mounted) return;

    setState(() => _ingesting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
      ),
    );

    if (result.success) {
      await _loadDashboard();
    }
  }

  double get _projectedIncome {
    return _projections.fold(0.0, (sum, p) => sum + p.projectedIncome);
  }

  double get _projectedExpenses {
    return _projections.fold(0.0, (sum, p) => sum + p.projectedExpenses);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('InboxCFO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Dashboard financiero', style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
              ],
            ),
          ],
        ),
        actions: [
          if (_service.useMock)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('DEMO LOCAL', style: TextStyle(fontSize: 11)),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.orange.shade900.withValues(alpha: 0.4)
                    : Colors.orange.shade100,
              ),
            ),
          IconButton(
            icon: Icon(
              ThemeController.instance.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: ThemeController.instance.isDark
                ? 'Modo claro'
                : 'Modo oscuro',
            onPressed: ThemeController.instance.toggle,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadDashboard,
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _ingesting ? null : _simulateIngestion,
            icon: _ingesting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.mail_outline, size: 18),
            label: const Text('Simular ingesta de correo'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_bannerDismissed)
                              AlertBanner(
                                alerts: _alerts,
                                onDismiss: () => setState(() => _bannerDismissed = true),
                              ),
                            if (!_bannerDismissed) const SizedBox(height: 20),
                            _buildKpiRow(currencyFormat, isWide),
                            const SizedBox(height: 24),
                            isWide
                                ? Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: CashflowChart(projections: _projections)),
                                      const SizedBox(width: 20),
                                      Expanded(flex: 1, child: AlertsPanel(alerts: _alerts)),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      CashflowChart(projections: _projections),
                                      const SizedBox(height: 20),
                                      AlertsPanel(alerts: _alerts),
                                    ],
                                  ),
                            const SizedBox(height: 24),
                            _buildInvoicesSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiRow(NumberFormat currencyFormat, bool isWide) {
    final children = [
      KpiCard(
        title: 'Balance actual',
        value: currencyFormat.format(_balance?.currentBalance ?? 0),
        subtitle: _balance != null
            ? 'Actualizado ${DateFormat('dd/MM HH:mm').format(_balance!.updatedAt)}'
            : null,
        icon: Icons.account_balance_rounded,
        accentColor: Theme.of(context).colorScheme.primary,
      ),
      KpiCard(
        title: 'Ingreso proyectado (30 días)',
        value: currencyFormat.format(_projectedIncome),
        icon: Icons.trending_up_rounded,
        accentColor: Colors.green.shade600,
      ),
      KpiCard(
        title: 'Gasto proyectado (30 días)',
        value: currencyFormat.format(_projectedExpenses),
        icon: Icons.trending_down_rounded,
        accentColor: Colors.red.shade400,
      ),
    ];

    if (isWide) {
      return Row(
        children: children
            .map((c) => Expanded(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                )))
            .toList(),
      );
    }

    return Column(
      children: children.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: c,
          )).toList(),
    );
  }

  Widget _buildInvoicesSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                const SizedBox(width: 8),
                Text(
                  'Facturas recientes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          if (_invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: Text('No hay facturas recientes')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _invoices.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Theme.of(context).dividerColor),
              itemBuilder: (_, index) => InvoiceListTile(invoice: _invoices[index]),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Error al cargar datos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
