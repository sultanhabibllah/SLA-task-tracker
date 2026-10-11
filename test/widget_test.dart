import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/main.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pumpApp(WidgetTester tester) async {
    final appState = AppState(StorageService());
    await appState.load();
    await tester.pumpWidget(SprintlyApp(appState: appState));
    return appState;
  }

  testWidgets('Sprintly opens on the sign-in screen', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Alex Carter'), findsOneWidget);
  });

  testWidgets('signing in opens the app with the bottom navigation', (
    tester,
  ) async {
    final appState = await pumpApp(tester);

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.scrollUntilVisible(
      continueButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@sprintly.app',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(appState.currentUser!.name, 'Alex Carter');
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Welcome back.'), findsNothing);
  });

  testWidgets('sign-in is blocked when the form is invalid', (tester) async {
    final appState = await pumpApp(tester);

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.scrollUntilVisible(
      continueButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(appState.currentUser, isNull);
    expect(find.text('Please enter your email'), findsOneWidget);
  });
}
