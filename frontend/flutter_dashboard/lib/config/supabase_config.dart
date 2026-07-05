/// Credenciales de Supabase — reemplaza con los valores del proyecto (Integrante 3).
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://TU_PROYECTO.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'TU_ANON_KEY_AQUI',
  );

  static bool get isConfigured =>
      !url.contains('TU_PROYECTO') && !anonKey.contains('TU_ANON_KEY');
}
