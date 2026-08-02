import 'package:campus_go/app/campus_go_app.dart';
import 'package:campus_go/features/auth/services/auth_service.dart';
import 'package:campus_go/features/auth/views/login_screen.dart';
import 'package:campus_go/features/auth/widgets/guest_access_button.dart';
import 'package:campus_go/features/home/views/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pretends that Supabase has no signed-in user.
///
/// This keeps the shared widget tests independent of:
/// - real Supabase credentials;
/// - internet access;
/// - saved login sessions;
/// - individual team members' accounts.
class _FakeSignedOutAuthService extends AuthService {
  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges {
    return const Stream<AuthState>.empty();
  }
}

/// Starts CampusGO in the same predictable signed-out condition
/// for every widget test.
Future<void> _pumpSignedOutApp(WidgetTester tester) async {
  await tester.pumpWidget(
    CampusGoApp(authService: _FakeSignedOutAuthService()),
  );

  await tester.pumpAndSettle();
}

void main() {
  group('CampusGO shared smoke tests', () {
    testWidgets('signed-out app starts on the login screen', (tester) async {
      await _pumpSignedOutApp(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(GuestAccessButton), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('guest can continue from Login to Home', (tester) async {
      await _pumpSignedOutApp(tester);

      final guestButton = find.byType(GuestAccessButton);

      expect(guestButton, findsOneWidget);

      // Makes the test reliable even when the test device has a short screen
      // and the button is initially lower inside the scrollable login page.
      await tester.ensureVisible(guestButton);
      await tester.pumpAndSettle();

      await tester.tap(guestButton);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
