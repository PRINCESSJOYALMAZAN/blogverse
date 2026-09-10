import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';

enum AuthMode {
  login,
  register,
}

class AuthStateProvider extends ChangeNotifier {
  User? user;
  bool loading = true;
  StreamSubscription<AuthState>? _subscription;

  bool get isLoggedIn => user != null;

  void bootstrap() {
    user = SupabaseService.client.auth.currentUser;
    loading = false;
    _subscription =
        SupabaseService.client.auth.onAuthStateChange.listen((data) {
      user = data.session?.user;
      notifyListeners();
    });
    notifyListeners();
  }

  /// Direct Login with email and password
  Future<void> login(String email, String password) async {
    try {
      final result = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      user = result.user ?? SupabaseService.client.auth.currentUser;
      await SupabaseService.ensureCurrentProfile();
      notifyListeners();
    } on AuthException catch (error) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        throw const InvalidCredentialsException();
      }
      rethrow;
    }
  }

  /// Direct Register: creates account and immediately logs in
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final trimmedEmail = email.trim();
    final displayName = (name?.trim().isNotEmpty == true)
        ? name!.trim()
        : trimmedEmail.split('@').first;

    try {
      final res = await SupabaseService.client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'name': displayName},
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );

      if (res.user != null) {
        user = res.user;
      }
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('already exists') ||
          msg.contains('user_already_exists')) {
        // User already exists, log in directly with their password
        await login(trimmedEmail, password);
        return;
      }
      rethrow;
    }

    // Try signing in immediately to establish active session
    if (user == null || SupabaseService.client.auth.currentSession == null) {
      try {
        final loginRes = await SupabaseService.client.auth.signInWithPassword(
          email: trimmedEmail,
          password: password,
        );
        user = loginRes.user ?? SupabaseService.client.auth.currentUser;
      } catch (_) {
        user = SupabaseService.client.auth.currentUser;
      }
    }

    await SupabaseService.ensureCurrentProfile(name: displayName);
    notifyListeners();
  }

  /// Signs in using Google OAuth provider
  Future<void> signInWithGoogle() async {
    try {
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await SupabaseService.client.auth.signOut();
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
}

typedef AssessmentLoginException = InvalidCredentialsException;

class AccountAlreadyExistsException implements Exception {
  const AccountAlreadyExistsException();
}
