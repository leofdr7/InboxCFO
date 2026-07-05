/// Configuración general de la app.
class AppConfig {
  /// `false` por defecto: si hay credenciales válidas usa Supabase/Auth.
  /// Pasa `--dart-define=USE_MOCK_DATA=true` para forzar demo local.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: false,
  );
  /// Endpoint para ejecutar ingesta/proyección (n8n o project-cashflow).
  /// Pásalo con --dart-define=INGESTION_ENDPOINT=https://...
  static const String ingestionEndpoint = String.fromEnvironment(
    'INGESTION_ENDPOINT',
    defaultValue: '',
  );

  /// URL a la que Supabase redirige después de confirmar el correo.
  /// En Supabase Dashboard debe estar agregada en Authentication > URL Configuration.
  static const String authRedirectUrl = String.fromEnvironment(
    'AUTH_REDIRECT_URL',
    defaultValue: 'http://localhost:8080/',
  );

  static const double riskThreshold = 0.0;
  static const int projectionDays = 30;
  static const int recentInvoicesLimit = 10;
}
