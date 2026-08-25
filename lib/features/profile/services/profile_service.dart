import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

/// Handles Supabase operations for the authenticated CampusGO profile.
class ProfileService {
  ProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  String? get currentUserEmail {
    return _client.auth.currentUser?.email;
  }

  Future<ProfileModel?> getCurrentProfile() async {
    final userId = currentUserId;

    if (userId == null) {
      return null;
    }

    return getProfile(userId);
  }

  Future<ProfileModel?> getProfile(String userId) async {
    final data = await _client
        .from('profile')
        .select('id, full_name, unimy_id, dob, prof_pic, role, created_at')
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return ProfileModel.fromMap(data);
  }

  /// DOB is the editable profile-table field in the current CampusGO design.
  Future<void> updateDob({
    required String userId,
    required DateTime dob,
  }) async {
    await _client
        .from('profile')
        .update({'dob': dob.toIso8601String().split('T').first})
        .eq('id', userId);
  }

  /// Changes the authenticated user's password.
  ///
  /// Full Name and Email are intentionally not editable from this screen.
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _client.auth.currentUser;
    final email = user?.email;

    if (user == null || email == null || email.trim().isEmpty) {
      throw StateError(
        'No authenticated user is available for password update.',
      );
    }

    // Verify that the current password entered by the user is correct.
    await _client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    // Current password is correct, so update to the new password.
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
