import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/core/sla/task_insights.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/statistics/statistics_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 2600);
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
          home: const StatisticsScreen(),
        ),
      ),
    );
    return appState;
  }

  String firstText(WidgetTester tester, String key) {
    return tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(Text),
          ),
        )
        .first
        .data!;
  }

  // Far-future task so it is never in "This Month".
  Task futureTask(String id) {
    return Task(
      id: id,
      title: 'Future $id',
      description: '',
      assigneeId: 'm1',
      dueDate: DateTime(2099, 1, 15),
      createdAt: DateTime.now(),
      project: 'Documentation',
    );
  }

  testWidgets('tiles and donut match the tasks due this month', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    final month = tasksInRange(appState.tasks, StatsRange.thisMonth);
    final counts = appState.slaCounts(subset: month);

    expect(find.text('Task Statistics'), findsOneWidget);
    expect(firstText(tester, 'stats-tile-total'), '${month.length}');
    expect(
      firstText(tester, 'stats-tile-overdue'),
      '${counts[SlaStatus.overdue]}',
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('stats-donut-total')))
          .data,
      '${month.length}',
    );
  });

  testWidgets('the legend shows a count and percentage per status', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    final month = tasksInRange(appState.tasks, StatsRange.thisMonth);
    final counts = appState.slaCounts(subset: month);
    final overdue = counts[SlaStatus.overdue]!;

    final row = find.byKey(const ValueKey('stats-legend-overdue'));
    expect(
      find.descendant(of: row, matching: find.text('$overdue')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: row,
        matching: find.text('${percentOf(overdue, month.length)}%'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('switching to All Time includes tasks outside this month', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    await appState.addTask(futureTask('f1'));
    await tester.pumpAndSettle();

    final monthTotal = tasksInRange(
      appState.tasks,
      StatsRange.thisMonth,
    ).length;
    expect(firstText(tester, 'stats-tile-total'), '$monthTotal');

    await tester.tap(find.byKey(const ValueKey('stats-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time').last);
    await tester.pumpAndSettle();

    expect(
      firstText(tester, 'stats-tile-total'),
      '${appState.tasks.length}',
    );
    expect(find.text('All Time'), findsOneWidget);
  });

  testWidgets('projects show done over total', (tester) async {
    final appState = await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('stats-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time').last);
    await tester.pumpAndSettle();

    final mobile = projectProgress(
      appState.tasks,
    ).firstWhere((p) => p.name == 'Mobile App');
    final row = find.byKey(const ValueKey('stats-project-Mobile App'));
    expect(
      find.descendant(
        of: row,
        matching: find.text('${mobile.done}/${mobile.total}'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('upcoming deadlines list at most three open tasks', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('stats-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time').last);
    await tester.pumpAndSettle();

    final rows = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('task-row-'),
    );
    expect(rows, findsNWidgets(StatisticsScreen.upcomingCount));
    // The completed seed task never appears as a deadline.
    expect(find.byKey(const ValueKey('task-row-t4')), findsNothing);
  });

  testWidgets('an empty period shows the empty messages', (tester) async {
    SharedPreferences.setMockInitialValues({'sprintly.tasks': '[]'});
    await pumpScreen(tester);

    expect(find.text('No tasks in this period yet.'), findsOneWidget);
    expect(find.text('No open tasks in this period.'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('stats-donut-total')))
          .data,
      '0',
    );
  });
}
