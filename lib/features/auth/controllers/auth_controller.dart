import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/models/profile_model.dart';
import '../../profile/services/profile_service.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';

/// Stores the authenticated user's session, profile, and role.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService, ProfileService? profileService})
    : _authService = authService ?? AuthService(),
      _profileService = profileService ?? ProfileService() {
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthStateChange,
      onError: _handleAuthStreamError,
    );

    unawaited(initialize());
  }

  final AuthService _authService;
  final ProfileService _profileService;
  StreamSubscription<AuthState>? _authSubscription;

  UserRole _role = UserRole.guest;
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  UserRole get role => _role;

  /// This is the getter that UserHomeScreen requires.
  ProfileModel? get profile => _profile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get hasSession {
    return _authService.currentSession != null;
  }

  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _loadProfileFromCurrentSession();
    } catch (error, stackTrace) {
      debugPrint('Account initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _clearSessionState();
      _errorMessage = 'We could not load your account. Please sign in again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshProfile() async {
    if (_authService.currentSession == null) {
      return;
    }

    try {
      final refreshedProfile = await _profileService.getCurrentProfile();
      if (refreshedProfile == null) {
        return;
      }

      _profile = refreshedProfile;
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Profile refresh failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      await _authService.signIn(email: email, password: password);

      await _loadProfileFromCurrentSession();

      return _role != UserRole.guest;
    } on AuthException catch (error) {
      _clearSessionState();
      _errorMessage = error.message;
      return false;
    } on PostgrestException catch (error) {
      _clearSessionState();

      debugPrint('Profile query failed: ${error.message}');

      _errorMessage =
          'Your login was accepted, but your CampusGO profile could not be loaded.';

      return false;
    } catch (error, stackTrace) {
      _clearSessionState();

      debugPrint('Sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage =
          'Your login was accepted, but the account role is missing or invalid.';

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;

    try {
      await _authService.sendPasswordResetEmail(email.trim());

      return true;
    } on AuthException catch (error) {
      debugPrint('Password reset error: ${error.message}');

      // Safe fallback for the current CampusGO testing build.
      return true;
    } catch (error, stackTrace) {
      debugPrint('Password reset failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Safe fallback so the app does not expose whether an account exists.
      return true;
    }
  }

  Future<void> signOut() async {
    _errorMessage = null;
    _setLoading(true);

    try {
      await _authService.signOut();
      _clearSessionState();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } catch (error, stackTrace) {
      debugPrint('Sign-out failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'We could not sign you out. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthStateChange(AuthState state) async {
    if (state.session == null) {
      _clearSessionState();
      _errorMessage = null;
      _setLoading(false);
      return;
    }

    try {
      await _loadProfileFromCurrentSession();
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Profile reload failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      _clearSessionState();
      _errorMessage =
          'Your account profile could not be loaded from the profile table.';

      notifyListeners();
    }
  }

  void _handleAuthStreamError(Object error, StackTrace stackTrace) {
    debugPrint('Authentication stream failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    _errorMessage =
        'The authentication connection was interrupted. Please try again.';

    _setLoading(false);
  }

  Future<void> _loadProfileFromCurrentSession() async {
    if (_authService.currentSession == null) {
      _clearSessionState();
      return;
    }

    final loadedProfile = await _authService.loadCurrentProfile();

    if (loadedProfile == null) {
      throw StateError(
        'No public.profile row exists for this authenticated user.',
      );
    }

    final normalizedRole = loadedProfile.role.trim().toLowerCase();

    if (normalizedRole == 'admin') {
      _role = UserRole.admin;
    } else if (normalizedRole == 'student' ||
        normalizedRole == 'lecturer' ||
        normalizedRole == 'user') {
      _role = UserRole.user;
    } else {
      throw StateError('Unknown CampusGO profile role: $normalizedRole');
    }

    _profile = loadedProfile;
  }

  void _clearSessionState() {
    _profile = null;
    _role = UserRole.guest;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
