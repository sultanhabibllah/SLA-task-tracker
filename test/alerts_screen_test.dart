import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/sla/task_insights.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/alerts/alerts_screen.dart';
import 'package:sprintly/screens/tasks/task_detail_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
          home: const AlertsScreen(),
        ),
      ),
    );
    return appState;
  }

  String tileCount(WidgetTester tester, String key) {
    final texts = tester.widgetList<Text>(
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text)),
    );
    return texts.first.data!;
  }

  Task extraTask(String id, int dueInDays) {
    final now = DateTime.now();
    return Task(
      id: id,
      title: 'Extra $id',
      description: '',
      assigneeId: 'm1',
      dueDate: DateTime(now.year, now.month, now.day + dueInDays),
      createdAt: now,
      project: 'Mobile App',
    );
  }

  testWidgets('shows the title and summary tiles from live data', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    final groups = groupAlerts(appState.tasks);

    expect(find.text('Alerts & Attention'), findsOneWidget);
    expect(
      tileCount(tester, 'alert-tile-overdue'),
      '${groups.overdue.length}',
    );
    expect(tileCount(tester, 'alert-tile-at-risk'), '${groups.atRisk.length}');
    expect(
      tileCount(tester, 'alert-tile-on-track'),
      '${groups.onTrackCount}',
    );
  });

  testWidgets('the seeded overdue task is listed under Overdue', (
    tester,
  ) async {
    await pumpScreen(tester);

    final overdue = find.byKey(const ValueKey('alerts-overdue'));
    expect(
      find.descendant(of: overdue, matching: find.text('Set up project API routes')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: overdue, matching: find.text('2 days ago')),
      findsOneWidget,
    );
  });

  testWidgets('completing an overdue task removes it from the screen', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    expect(find.text('Set up project API routes'), findsOneWidget);

    final task = appState.taskById('t2')!;
    await appState.updateTask(task.copyWith(status: TaskStatus.done));
    await tester.pumpAndSettle();

    expect(find.text('Set up project API routes'), findsNothing);
    expect(find.text('Nothing is overdue. Nice work.'), findsOneWidget);
  });

  testWidgets('View all reveals the hidden tasks and Show less hides them', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    // Three more overdue tasks so the section has more than it shows.
    for (final id in ['x1', 'x2', 'x3']) {
      await appState.addTask(extraTask(id, -5));
    }
    await tester.pumpAndSettle();

    final overdue = find.byKey(const ValueKey('alerts-overdue'));
    final rows = find.descendant(
      of: overdue,
      matching: find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('task-row-'),
      ),
    );
    expect(rows, findsNWidgets(2));

    await tester.tap(find.descendant(of: overdue, matching: find.text('View all')));
    await tester.pumpAndSettle();
    expect(rows, findsNWidgets(4));

    await tester.tap(find.descendant(of: overdue, matching: find.text('Show less')));
    await tester.pumpAndSettle();
    expect(rows, findsNWidgets(2));
  });

  testWidgets('tapping a task opens its detail screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('task-row-t2')));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
  });

  testWidgets('shows a back button only when opened on top of another screen', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byTooltip('Back'), findsNothing);
  });
}
