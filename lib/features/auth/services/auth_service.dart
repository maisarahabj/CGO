import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/database_tables.dart';
import '../../profile/models/profile_model.dart';

/// The only authentication class that communicates directly with Supabase.
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

  /// Loads the signed-in person's complete sidebar profile.
  ///
  /// The drawer uses `full_name`, `unimy_id`, and `prof_pic`. The same query
  /// also returns `role`, so authentication and the UI use one consistent row.
  Future<ProfileModel?> loadCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final data = await _client
        .from(DatabaseTables.profile)
        .select('id, full_name, unimy_id, dob, prof_pic, role, created_at')
        .eq('id', user.id)
        .maybeSingle();

    return data == null ? null : ProfileModel.fromMap(data);
  }

  /// Kept for compatibility with any older code that still requests only role.
  Future<String?> loadCurrentProfileRole() async {
    return (await loadCurrentProfile())?.role;
  }
}
