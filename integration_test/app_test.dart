import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/main.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/profile/profile_screen.dart';
import 'package:sprintly/screens/tasks/edit_task_screen.dart';
import 'package:sprintly/screens/team/team_members_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

// End-to-end run on a real device or emulator:
//   flutter test integration_test/app_test.dart -d <device id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Reads what is saved on the device, as a fresh launch of the app would.
  Future<AppState> reloadFromDevice() async {
    final state = AppState(StorageService());
    await state.load();
    return state;
  }

  Finder scrollableIn(Type screen) {
    return find
        .descendant(of: find.byType(screen), matching: find.byType(Scrollable))
        .first;
  }

  // Scrolls a screen until the widget is built, then centres it so it is not
  // hidden behind the navigation bar or a snackbar when tapped.
  Future<void> reveal(WidgetTester tester, Finder target, Type screen) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: scrollableIn(screen),
    );
    await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
    await tester.pumpAndSettle();
  }

  Finder navTab(String label) {
    return find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );
  }

  testWidgets('sign in, complete an overdue task, restart, sign out', (
    tester,
  ) async {
    // Start from a clean install.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    final appState = await reloadFromDevice();
    await tester.pumpWidget(SprintlyApp(appState: appState));
    await tester.pumpAndSettle();

    // Sign in as Alex Carter.
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
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);

    // Team tab: David Liu has one overdue task.
    await tester.tap(navTab('Team'));
    await tester.pumpAndSettle();

    final davidMenu = find.byTooltip('Options for David Liu');
    await reveal(tester, davidMenu, TeamMembersScreen);
    expect(find.text('1 open task · 1 overdue'), findsOneWidget);

    await tester.tap(davidMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Overdue'), findsOneWidget);

    // Open the task and mark it done.
    await tester.tap(find.text('Set up project API routes'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Task'), findsOneWidget);

    final statusDropdown = find.text('In Progress');
    await reveal(tester, statusDropdown, EditTaskScreen);
    await tester.tap(statusDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done').last);
    await tester.pumpAndSettle();

    final saveButton = find.text('Save Changes');
    await reveal(tester, saveButton, EditTaskScreen);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Back on the Team tab, David's card no longer shows open work.
    expect(find.text('Edit Task'), findsNothing);
    expect(find.text('Task updated.'), findsOneWidget);
    expect(find.text('1 open task · 1 overdue'), findsNothing);

    // Wait for the snackbar to go, then check the task's new SLA status.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await reveal(tester, davidMenu, TeamMembersScreen);
    await tester.tap(davidMenu);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Overdue'), findsNothing);

    await tester.tapAt(const Offset(20, 80));
    await tester.pumpAndSettle();

    // The change and the session survive an app restart.
    final restarted = await reloadFromDevice();
    expect(restarted.taskById('t2')!.status, TaskStatus.done);
    expect(restarted.currentUser!.name, 'Alex Carter');

    // Profile tab: sign out returns to the sign-in screen.
    await tester.tap(navTab('Profile'));
    await tester.pumpAndSettle();

    final signOut = find.text('Sign Out');
    await reveal(tester, signOut, ProfileScreen);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back.'), findsOneWidget);
    expect((await reloadFromDevice()).currentUser, isNull);
  });
}
