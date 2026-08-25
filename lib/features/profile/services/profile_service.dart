import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

/// Handles Supabase operations for the authenticated CampusGO profile.
class ProfileService {
  static const String _profilePictureBucket = 'profile-pictures';

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

  Future<ProfileModel> uploadProfilePicture({
    required String userId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final normalizedExtension = extension.trim().toLowerCase();
    final safeExtension = normalizedExtension == 'jpeg'
        ? 'jpg'
        : normalizedExtension;

    if (!{'jpg', 'png', 'webp'}.contains(safeExtension)) {
      throw ArgumentError('Unsupported profile image extension: $extension');
    }

    final contentType = switch (safeExtension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final objectPath = '$userId/avatar.$safeExtension';

    await _client.storage
        .from(_profilePictureBucket)
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            cacheControl: '3600',
            contentType: contentType,
          ),
        );

    final publicUrl = _client.storage
        .from(_profilePictureBucket)
        .getPublicUrl(objectPath);

    final versionedUrl =
        '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await _client
        .from('profile')
        .update({'prof_pic': versionedUrl})
        .eq('id', userId);

    final refreshedProfile = await getProfile(userId);
    if (refreshedProfile == null) {
      throw StateError('Updated profile picture could not be reloaded.');
    }

    return refreshedProfile;
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
