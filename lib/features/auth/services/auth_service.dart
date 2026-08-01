import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';

/// The only authentication class that communicates directly with Supabase.
///
/// Screens call [AuthController], and [AuthController] calls this service.
class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  /// Loads the role stored in `public.profile` for the current Auth user.
  ///
  /// CampusGO stores `student`, `lecturer`, or `admin` in this column.
  Future<String?> loadCurrentProfileRole() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final profile = await _client
        .from(DatabaseTables.profile)
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['role'] as String?;
  }
}
