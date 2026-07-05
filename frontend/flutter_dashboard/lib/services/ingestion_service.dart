import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'supabase_service.dart';

class IngestionService {
  IngestionService._();
  static final IngestionService instance = IngestionService._();

  bool get isConfigured => AppConfig.ingestionEndpoint.isNotEmpty;

  Future<IngestionResult> simulateEmailIngestion() async {
    // Modo frontend: simula ingesta localmente sin endpoint ni Supabase.
    if (AppConfig.useMockData) {
      await SupabaseService.instance.simulateMockIngestion();
      return const IngestionResult(
        success: true,
        message: 'Ingesta simulada (modo demo local)',
      );
    }

    if (!isConfigured) {
      return const IngestionResult(
        success: false,
        message:
            'Configura INGESTION_ENDPOINT para ejecutar project-cashflow con Supabase.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(AppConfig.ingestionEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: '{}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return IngestionResult(
          success: true,
          message: 'Ingesta simulada correctamente (${response.statusCode})',
        );
      }

      return IngestionResult(
        success: false,
        message: 'Error ${response.statusCode}: ${response.body}',
      );
    } catch (e) {
      return IngestionResult(success: false, message: 'Error de red: $e');
    }
  }
}

class IngestionResult {
  const IngestionResult({required this.success, required this.message});

  final bool success;
  final String message;
}
