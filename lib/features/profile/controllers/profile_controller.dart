import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';
import '../services/profile_service.dart';

/// Handles loading and updating the authenticated user's profile.
class ProfileController extends ChangeNotifier {
  ProfileController({
    ProfileService? profileService,
    ProfileModel? initialProfile,
  }) : _profileService = profileService ?? ProfileService(),
       _profile = initialProfile;

  final ProfileService _profileService;

  ProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isUploadingProfilePicture = false;

  ProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;
  bool get isUploadingProfilePicture => _isUploadingProfilePicture;

  String? get currentUserEmail {
    return _profileService.currentUserEmail;
  }

  Future<void> loadCurrentProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final loadedProfile = await _profileService.getCurrentProfile();

      if (loadedProfile == null) {
        _errorMessage = 'Profile not found.';
        return;
      }

      _profile = loadedProfile;
    } catch (error, stackTrace) {
      debugPrint('Profile loading failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'We could not load your profile. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfilePicture({
    required Uint8List bytes,
    required String extension,
  }) async {
    final userId = _profileService.currentUserId;
    if (userId == null) {
      _errorMessage =
          'Your authentication session is unavailable. Please sign in again.';
      notifyListeners();
      return false;
    }

    _isUploadingProfilePicture = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.uploadProfilePicture(
        userId: userId,
        bytes: bytes,
        extension: extension,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Profile picture update failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage =
          'We could not upload your profile picture. Please try again.';
      return false;
    } finally {
      _isUploadingProfilePicture = false;
      notifyListeners();
    }
  }

  Future<bool> saveChanges({
    required DateTime dob,
    String? currentPassword,
    String? newPassword,
  }) async {
    final userId = _profileService.currentUserId;

    if (userId == null) {
      _errorMessage =
          'Your authentication session is unavailable. Please sign in again.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _profileService.updateDob(userId: userId, dob: dob);

      final shouldChangePassword =
          currentPassword != null &&
          currentPassword.isNotEmpty &&
          newPassword != null &&
          newPassword.isNotEmpty;

      if (shouldChangePassword) {
        await _profileService.updatePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
      }

      final refreshedProfile = await _profileService.getProfile(userId);

      if (refreshedProfile == null) {
        throw StateError('Updated profile could not be reloaded.');
      }

      _profile = refreshedProfile;

      return true;
    } on AuthException catch (error) {
      debugPrint(
        'Password/profile authentication update failed: ${error.message}',
      );

      _errorMessage = error.message;
      return false;
    } catch (error, stackTrace) {
      debugPrint('Profile update failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage =
          'We could not save your profile changes. Please try again.';

      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
