import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;

    if (auth.isDemoMode) {
      return const DashboardScreen();
    }

    if (!auth.isConfigured) {
      return const _SupabaseSetupScreen();
    }

    return StreamBuilder<AuthState>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? auth.currentSession;

        if (session != null) {
          return const DashboardScreen();
        }

        return const AuthScreen();
      },
    );
  }
}

class _SupabaseSetupScreen extends StatelessWidget {
  const _SupabaseSetupScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.settings_ethernet_rounded,
                      color: colorScheme.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Supabase no está configurado',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La app ya no entra automáticamente a demo local. Para ver el inicio de sesión, reinicia Flutter con tus credenciales públicas de Supabase.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      'flutter run -d chrome --web-port=8080 '
                      '--dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co '
                      '--dart-define=SUPABASE_ANON_KEY=tu_anon_key '
                      '--dart-define=AUTH_REDIRECT_URL=http://localhost:8080/',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Si quieres volver al dashboard de prueba, agrega --dart-define=USE_MOCK_DATA=true.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
