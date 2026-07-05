import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class GmailConnectService {
  GmailConnectService._();
  static final GmailConnectService instance = GmailConnectService._();

  bool _listening = false;

  void startListening() {
    if (_listening || AuthService.instance.isDemoMode || !SupabaseService.instance.isSupabaseConfigured) {
      return;
    }

    _listening = true;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        await persistFromSession(data.session);
      }
    });
  }

  Future<GmailConnectResult> connectGmail() async {
    if (AuthService.instance.isDemoMode || !SupabaseService.instance.isSupabaseConfigured) {
      return const GmailConnectResult(
        success: false,
        message: 'Supabase no está configurado.',
      );
    }

    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _redirectUrl,
      queryParams: const {
        'access_type': 'offline',
        'prompt': 'consent',
      },
      scopes: 'https://www.googleapis.com/auth/gmail.readonly',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    return const GmailConnectResult(
      success: true,
      message: 'Completa el consentimiento de Google en el navegador.',
    );
  }

  Future<GmailConnectResult> persistFromSession(Session? session) async {
    if (session == null) {
      return const GmailConnectResult(success: false, message: 'Sin sesión activa.');
    }

    final providerToken = session.providerToken;
    final refreshToken = session.providerRefreshToken;
    final user = session.user;

    if (providerToken == null) {
      return const GmailConnectResult(
        success: false,
        message: 'Google no devolvió access token. Usa el botón Conectar Gmail.',
      );
    }

    if (refreshToken == null) {
      return const GmailConnectResult(
        success: false,
        message: 'Google no devolvió refresh_token. Repite con prompt=consent.',
      );
    }

    final expiresAt = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000).toUtc().toIso8601String()
        : DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String();

    try {
      await Supabase.instance.client.from('gmail_connections').upsert(
        {
          'user_id': user.id,
          'email_address': user.email,
          'access_token': providerToken,
          'refresh_token': refreshToken,
          'token_expires_at': expiresAt,
          'is_active': true,
        },
        onConflict: 'user_id,email_address',
      );

      return GmailConnectResult(
        success: true,
        message: 'Gmail conectado: ${user.email ?? user.id}',
      );
    } catch (e) {
      return GmailConnectResult(
        success: false,
        message: 'No se pudo guardar gmail_connections: $e',
      );
    }
  }

  Future<bool> hasActiveConnection() async {
    if (AuthService.instance.isDemoMode || !SupabaseService.instance.isSupabaseConfigured) {
      return false;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final row = await Supabase.instance.client
        .from('gmail_connections')
        .select('id')
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();

    return row != null;
  }

  String get _redirectUrl {
    if (kIsWeb) {
      final base = Uri.base;
      final path = base.path.endsWith('/') ? base.path : '${base.path}/';
      return '${base.origin}$path';
    }
    return AppConfig.authRedirectUrl;
  }
}

class GmailConnectResult {
  const GmailConnectResult({required this.success, required this.message});

  final bool success;
  final String message;
}
