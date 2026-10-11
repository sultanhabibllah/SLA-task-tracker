import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/screens/alerts/alerts_screen.dart';
import 'package:sprintly/screens/calendar/calendar_screen.dart';
import 'package:sprintly/screens/home/dashboard_screen.dart';
import 'package:sprintly/screens/shell/app_shell.dart';
import 'package:sprintly/screens/statistics/statistics_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

// Checks the Calendar, Alerts and Statistics screens can be reached from the
// running app shell, and that back returns to the dashboard.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appState = AppState(StorageService());
    await appState.load();
    await appState.signIn('m1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Calendar tab shows the calendar, not a placeholder', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();

    expect(find.byType(CalendarScreen), findsOneWidget);
    expect(find.text('This screen is not built yet.'), findsNothing);
  });

  testWidgets('the dashboard bell opens Alerts, and back returns home', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard-bell')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertsScreen), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertsScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('the dashboard chart button opens Statistics', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byKey(const ValueKey('dashboard-stats')));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsNothing);
  });
}
