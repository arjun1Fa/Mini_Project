import 'package:supabase_flutter/supabase_flutter.dart';

/// Wrapper around Supabase Auth for email/password authentication.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Current session, or null if not authenticated.
  Session? get currentSession => _client.auth.currentSession;

  /// Current user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => currentSession != null;

  /// Stream of auth state changes.
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Sign up with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    return response;
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign out and clear session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get the current JWT access token, or null.
  String? get accessToken => currentSession?.accessToken;
}
