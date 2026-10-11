import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/calendar/calendar_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';
import 'package:sprintly/widgets/status_chip.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  Future<AppState> pumpScreen(WidgetTester tester, {DateTime? fixedToday}) async {
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
          home: Scaffold(body: CalendarScreen(today: fixedToday)),
        ),
      ),
    );
    return appState;
  }

  String monthTitle(WidgetTester tester) {
    return tester
        .widget<Text>(find.byKey(const ValueKey('calendar-month')))
        .data!;
  }

  Finder dayCell(DateTime day) {
    return find.byKey(ValueKey('day-${day.year}-${day.month}-${day.day}'));
  }

  testWidgets('opens on the current month with today selected', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(monthTitle(tester), DateFormat('MMMM yyyy').format(today));
    final agenda = tester
        .widget<Text>(find.byKey(const ValueKey('agenda-title')))
        .data!;
    expect(agenda, DateFormat('EEE, d MMMM yyyy').format(today));
  });

  testWidgets('previous, next and Today change the month shown', (
    tester,
  ) async {
    // 15 March so the month bar math is easy to read.
    await pumpScreen(tester, fixedToday: DateTime(2026, 3, 15));
    expect(monthTitle(tester), 'March 2026');

    await tester.tap(find.byKey(const ValueKey('calendar-next')));
    await tester.pump();
    expect(monthTitle(tester), 'April 2026');

    await tester.tap(find.byKey(const ValueKey('calendar-previous')));
    await tester.tap(find.byKey(const ValueKey('calendar-previous')));
    await tester.pump();
    expect(monthTitle(tester), 'February 2026');

    await tester.tap(find.byKey(const ValueKey('calendar-today')));
    await tester.pump();
    expect(monthTitle(tester), 'March 2026');
  });

  testWidgets('selecting a day lists the tasks due that day', (tester) async {
    await pumpScreen(tester);
    // The seeded "Write onboarding guide" is due 10 days from today.
    final due = DateTime(today.year, today.month, today.day + 10);

    if (due.month != today.month) {
      await tester.tap(find.byKey(const ValueKey('calendar-next')));
      await tester.pump();
    }
    await tester.tap(dayCell(due));
    await tester.pump();

    expect(find.text('Write onboarding guide'), findsOneWidget);
    expect(find.text('1 task'), findsOneWidget);
    expect(find.byType(SlaChip), findsOneWidget);
  });

  testWidgets('a day with no tasks shows the empty message', (tester) async {
    await pumpScreen(tester, fixedToday: DateTime(2030, 6, 12));

    expect(find.text('No tasks due on this day.'), findsOneWidget);
    expect(find.text('0 tasks'), findsOneWidget);
  });

  testWidgets('Mark as done from the menu completes the task', (tester) async {
    final appState = await pumpScreen(tester);
    // The seeded overdue task is due two days ago.
    final due = DateTime(today.year, today.month, today.day - 2);
    if (due.month != today.month) {
      await tester.tap(find.byKey(const ValueKey('calendar-previous')));
      await tester.pump();
    }
    await tester.tap(dayCell(due));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('agenda-menu-t2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark as done'));
    await tester.pumpAndSettle();

    expect(appState.taskById('t2')!.status, TaskStatus.done);
    expect(find.text('Completed'), findsWidgets);
  });

  testWidgets('days with tasks show a coloured dot', (tester) async {
    await pumpScreen(tester);
    final cell = dayCell(today.add(const Duration(days: 1)));
    if (tester.any(cell)) {
      // Design Login Screen is due tomorrow, so tomorrow has a dot.
      final dots = find.descendant(
        of: cell,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              w.constraints?.maxWidth == 5,
        ),
      );
      expect(dots, findsWidgets);
    }
  });
}
