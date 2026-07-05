/// Configuración general de la app.
class AppConfig {
  /// `true` por defecto: desarrollo frontend sin depender de Supabase.
  /// Pasa `--dart-define=USE_MOCK_DATA=false` para conectar al esquema
  /// Supabase incluido en `database/schema/schema.sql`.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
  /// Endpoint para ejecutar ingesta/proyección (n8n o project-cashflow).
  /// Pásalo con --dart-define=INGESTION_ENDPOINT=https://...
  static const String ingestionEndpoint = String.fromEnvironment(
    'INGESTION_ENDPOINT',
    defaultValue: '',
  );

  static const double riskThreshold = 0.0;
  static const int projectionDays = 30;
  static const int recentInvoicesLimit = 10;
}
