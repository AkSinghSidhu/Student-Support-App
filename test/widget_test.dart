// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:student_support_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StudentSupportApp(isLoggedIn: false));

    // Verify the app launches with the login page
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
