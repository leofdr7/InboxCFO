import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'supabase_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool get isDemoMode => SupabaseService.instance.useMock;
  bool get isConfigured => SupabaseService.instance.isSupabaseConfigured;

  SupabaseClient get _client => Supabase.instance.client;

  Stream<AuthState> get authStateChanges {
    if (isDemoMode) return const Stream.empty();
    return _client.auth.onAuthStateChange;
  }

  Session? get currentSession {
    if (isDemoMode) return null;
    return _client.auth.currentSession;
  }

  User? get currentUser {
    if (isDemoMode) return null;
    return _client.auth.currentUser;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: AppConfig.authRedirectUrl,
    );
  }

  Future<void> signOut() {
    return _client.auth.signOut();
  }
}
