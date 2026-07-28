import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import '../services/auth_service.dart';

/// Holds the authentication and role state used by CampusGO screens.
class AuthController extends ChangeNotifier {
  AuthController({AuthService? authService})
    : _authService = authService ?? AuthService() {
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthStateChange,
      onError: _handleAuthStreamError,
    );
    unawaited(initialize());
  }

  final AuthService _authService;
  StreamSubscription<AuthState>? _authSubscription;

  UserRole _role = UserRole.guest;
  bool _isLoading = true;
  String? _errorMessage;

  UserRole get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSession => _authService.currentSession != null;

  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _loadRoleFromCurrentSession();
    } catch (_) {
      _role = UserRole.guest;
      _errorMessage = 'We could not load your account. Please sign in again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      await _authService.signIn(email: email, password: password);
      await _loadRoleFromCurrentSession();
      return _role != UserRole.guest;
    } on AuthException catch (error) {
      _role = UserRole.guest;
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _role = UserRole.guest;
      _errorMessage =
          'Something went wrong while signing in. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _errorMessage = null;
    _setLoading(true);

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on AuthException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'We could not send the reset email. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _errorMessage = null;
    _setLoading(true);

    try {
      await _authService.signOut();
      _role = UserRole.guest;
    } on AuthException catch (error) {
      _errorMessage = error.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _handleAuthStateChange(AuthState state) async {
    if (state.session == null) {
      _role = UserRole.guest;
      _errorMessage = null;
      _setLoading(false);
      return;
    }

    try {
      await _loadRoleFromCurrentSession();
      notifyListeners();
    } catch (_) {
      _role = UserRole.guest;
      _errorMessage =
          'Your account role could not be loaded from the profile table.';
      notifyListeners();
    }
  }

  void _handleAuthStreamError(Object error, StackTrace stackTrace) {
    _errorMessage =
        'The authentication connection was interrupted. Please try again.';
    _setLoading(false);
  }

  Future<void> _loadRoleFromCurrentSession() async {
    if (_authService.currentSession == null) {
      _role = UserRole.guest;
      return;
    }

    final profileRole = (await _authService.loadCurrentProfileRole())
        ?.trim()
        .toLowerCase();

    _role = switch (profileRole) {
      'admin' => UserRole.admin,
      'student' || 'lecturer' || 'user' => UserRole.user,
      _ => throw StateError('Unknown or missing CampusGO profile role.'),
    };
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
