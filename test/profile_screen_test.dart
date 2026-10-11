import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/member.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/profile/profile_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Opens the Profile screen signed in as Priya Sharma (m2), on a tall
  // screen so every row is laid out.
  Future<AppState> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appState = AppState(StorageService());
    await appState.load();
    await appState.signIn('m2');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SafeArea(child: ProfileScreen())),
        ),
      ),
    );
    return appState;
  }

  String slaCount(WidgetTester tester, String status) {
    return tester.widget<Text>(find.byKey(ValueKey('sla-count-$status'))).data!;
  }

  Future<void> editField(
    WidgetTester tester,
    String rowLabel,
    String newValue,
  ) async {
    await tester.tap(find.text(rowLabel));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), newValue);
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the signed-in member and their workload', (tester) async {
    final appState = await pumpScreen(tester);

    expect(find.text('Priya Sharma'), findsNWidgets(2));
    expect(find.text('Mobile Developer · Admin'), findsOneWidget);
    expect(find.text('priya@sprintly.app'), findsOneWidget);
    expect(find.text('Engineering'), findsOneWidget);
    expect(find.text('Member since Dec 2024'), findsOneWidget);

    // Priya's only task is high priority and due tomorrow.
    expect(find.text('0 of 1 assigned tasks completed'), findsOneWidget);
    expect(slaCount(tester, 'atRisk'), '1');
    expect(slaCount(tester, 'completed'), '0');

    await appState.updateTask(
      appState.taskById('t1')!.copyWith(status: TaskStatus.done),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 of 1 assigned tasks completed'), findsOneWidget);
    expect(slaCount(tester, 'atRisk'), '0');
    expect(slaCount(tester, 'completed'), '1');
  });

  testWidgets('the name is validated, then saved', (tester) async {
    final appState = await pumpScreen(tester);

    await editField(tester, 'Full Name', ' ');
    expect(find.text('Please enter a name'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'P');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Name must contain at least 2 characters'),
      findsOneWidget,
    );
    expect(appState.currentUser!.name, 'Priya Sharma');

    await tester.enterText(find.byType(TextFormField), '  Priya Patel ');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(appState.currentUser!.name, 'Priya Patel');
    expect(find.text('Priya Patel'), findsNWidgets(2));
  });

  testWidgets('cancelling an edit changes nothing', (tester) async {
    final appState = await pumpScreen(tester);

    await tester.tap(find.text('Team'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Design');
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(appState.currentUser!.team, 'Engineering');
  });

  testWidgets('the email must be valid and not used by someone else', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);

    await editField(tester, 'Work Email', 'priya-at-sprintly');
    expect(find.text('Please enter a valid email address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Alex@sprintly.app');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('A member with this email already exists'),
      findsOneWidget,
    );
    expect(appState.currentUser!.email, 'priya@sprintly.app');

    await tester.enterText(find.byType(TextFormField), 'Priya.S@sprintly.app');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(appState.currentUser!.email, 'priya.s@sprintly.app');
  });

  testWidgets('role and team can be edited', (tester) async {
    final appState = await pumpScreen(tester);

    await editField(tester, 'Role', 'Lead Developer');
    await editField(tester, 'Team', 'Platform');

    expect(appState.currentUser!.jobTitle, 'Lead Developer');
    expect(appState.currentUser!.team, 'Platform');
    expect(find.text('Lead Developer · Admin'), findsOneWidget);
  });

  testWidgets('the status can be changed', (tester) async {
    final appState = await pumpScreen(tester);

    await tester.tap(find.text('Status'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Away'));
    await tester.pumpAndSettle();

    expect(appState.currentUser!.presence, MemberPresence.away);
    expect(find.text('Away'), findsNWidgets(2));
  });

  testWidgets('the SLA rules are explained', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('How SLA status works'));
    await tester.pumpAndSettle();

    expect(
      find.text('Due within 48 hours, or 72 hours for High priority tasks.'),
      findsOneWidget,
    );
    expect(
      find.text('The due date has passed and the task is not done.'),
      findsOneWidget,
    );
  });

  testWidgets('sign out asks first, then signs the member out', (tester) async {
    final appState = await pumpScreen(tester);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(appState.currentUser, isNotNull);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(appState.currentUser, isNull);
    expect(find.text('Priya Sharma'), findsNothing);
  });
}
