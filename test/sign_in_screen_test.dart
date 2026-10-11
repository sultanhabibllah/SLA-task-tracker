
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:sprintly/models/member.dart';
import 'package:sprintly/screens/auth/sign_in_screen.dart';
import 'package:sprintly/state/app_state.dart';
import 'package:sprintly/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sign In Screen', () {
    late AppState appState;

    setUp(() {
      appState = AppState(StorageService());
    });

    Widget buildTestApp() {
      return ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: const MaterialApp(
          home: SignInScreen(),
        ),
      );
    }

    testWidgets('displays the sign-in heading', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Choose your profile'), findsOneWidget);
    });

    testWidgets('shows empty state when no members are loaded',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(
        find.text('No team members available.'),
        findsOneWidget,
      );
    });

    testWidgets('disables Continue when there are no members',
        (tester) async {
      await tester.pumpWidget(buildTestApp());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue'),
      );

      expect(button.onPressed, isNull);
    });
  });
}
