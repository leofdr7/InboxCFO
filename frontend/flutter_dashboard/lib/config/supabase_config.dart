/// Credenciales de Supabase — reemplaza con los valores del proyecto (Integrante 3).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mekiggiufacrkwjgyfjq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1la2lnZ2l1ZmFjcmt3amd5ZmpxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxNDQ1MDMsImV4cCI6MjA5MjcyMDUwM30.p0wo2ePyjX8Q9vVJ3LzjJb77B1PZg8-hAy-oZ5FFJ80',
  );

  static bool get isConfigured =>
      !url.contains('TU_PROYECTO') && !anonKey.contains('TU_ANON_KEY');
}
