import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/member.dart';
import 'package:sprintly/screens/team/team_members_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Opens the Team Members screen signed in as Alex Carter (m1), on a tall
  // screen so every member card is laid out.
  Future<AppState> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appState = AppState(StorageService());
    await appState.load();
    await appState.signIn('m1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: SafeArea(child: TeamMembersScreen())),
        ),
      ),
    );
    return appState;
  }

  Future<void> openMenu(WidgetTester tester, String name, String item) async {
    await tester.tap(find.byTooltip('Options for $name'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  testWidgets('lists every member with their role and workload', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('All  6'), findsOneWidget);
    expect(find.text('Admins  2'), findsOneWidget);
    expect(find.text('Members  4'), findsOneWidget);

    expect(find.text('Alex Carter'), findsOneWidget);
    expect(find.text('Product Manager · Admin'), findsOneWidget);
    expect(find.text('QA Engineer'), findsOneWidget);
    expect(find.text('david@sprintly.app'), findsOneWidget);

    // David's only task is overdue; Marcus's only task is done.
    expect(find.text('1 open task · 1 overdue'), findsOneWidget);
    expect(find.text('No open tasks'), findsOneWidget);
  });

  testWidgets('the filter tabs show only admins or only members', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Admins  2'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Carter'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('Marcus Lee'), findsNothing);

    await tester.tap(find.text('Members  4'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Carter'), findsNothing);
    expect(find.text('Marcus Lee'), findsOneWidget);
  });

  testWidgets('search narrows the list and shows an empty state', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Search members'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'designer');
    await tester.pumpAndSettle();

    expect(find.text('Emily Wong'), findsOneWidget);
    expect(find.text('Alex Carter'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No members found'), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();

    expect(find.text('Alex Carter'), findsOneWidget);
  });

  testWidgets('add member rejects an empty form and a duplicate email', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add member'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name'), findsOneWidget);
    expect(find.text('Please enter a job title'), findsOneWidget);
    expect(find.text('Please enter an email'), findsOneWidget);
    expect(find.text('Please enter a team'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(2),
      'ALEX@sprintly.app',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(
      find.text('A member with this email already exists'),
      findsOneWidget,
    );
    expect(appState.members.length, 6);
  });

  testWidgets('a valid new member is saved and appears in the list', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);

    await tester.tap(find.byTooltip('Add member'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Jordan Blake');
    await tester.enterText(find.byType(TextFormField).at(1), 'Intern');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'jordan@sprintly.app',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'Engineering');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add member'));
    await tester.pumpAndSettle();

    expect(find.text('Jordan Blake'), findsOneWidget);
    expect(find.text('All  7'), findsOneWidget);
    expect(find.text('Jordan Blake was added to the team.'), findsOneWidget);

    final saved = appState.members.last;
    expect(saved.email, 'jordan@sprintly.app');
    expect(saved.role, MemberRole.member);
  });

  testWidgets('view tasks lists the member tasks with their SLA status', (
    tester,
  ) async {
    await pumpScreen(tester);

    await openMenu(tester, 'David Liu', 'View tasks');

    expect(find.text('David Liu\'s tasks'), findsOneWidget);
    expect(find.text('Set up project API routes'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
  });

  testWidgets('the role can be changed but the last admin is kept', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);

    await openMenu(tester, 'Marcus Lee', 'Make admin');

    expect(appState.memberById('m3')!.role, MemberRole.admin);
    expect(find.text('Admins  3'), findsOneWidget);

    await openMenu(tester, 'Marcus Lee', 'Make member');
    await openMenu(tester, 'Priya Sharma', 'Make member');
    await openMenu(tester, 'Alex Carter', 'Make member');

    expect(appState.memberById('m1')!.role, MemberRole.admin);
    expect(find.text('The team needs at least one admin.'), findsOneWidget);
  });

  testWidgets('a member is only removed when it is safe to', (tester) async {
    final appState = await pumpScreen(tester);

    await openMenu(tester, 'Alex Carter', 'Remove from team');
    expect(
      find.text('You cannot remove yourself while signed in.'),
      findsOneWidget,
    );

    await openMenu(tester, 'David Liu', 'Remove from team');
    expect(
      find.text('Reassign David Liu\'s tasks before removing them.'),
      findsOneWidget,
    );
    expect(appState.members.length, 6);

    // Free David of his task, then removing him asks for confirmation.
    await appState.deleteTask('t2');
    await tester.pumpAndSettle();

    await openMenu(tester, 'David Liu', 'Remove from team');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(appState.memberById('m5'), isNotNull);

    await openMenu(tester, 'David Liu', 'Remove from team');
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();

    expect(appState.memberById('m5'), isNull);
    expect(find.text('David Liu'), findsNothing);
    expect(find.text('All  5'), findsOneWidget);
  });
}
