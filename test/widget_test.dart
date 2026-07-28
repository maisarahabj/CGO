import 'package:campus_go/app/campus_go_app.dart';
import 'package:campus_go/features/home/views/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CampusGO starts successfully', (tester) async {
    await tester.pumpWidget(const CampusGoApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
