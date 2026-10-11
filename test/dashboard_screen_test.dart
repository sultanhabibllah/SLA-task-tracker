import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/home/dashboard_screen.dart';
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
          home: const Scaffold(body: SafeArea(child: DashboardScreen())),
        ),
      ),
    );
    return appState;
  }

  String tileValue(WidgetTester tester, String key) {
    final tile = find.byKey(ValueKey(key));
    return tester
        .widgetList<Text>(
          find.descendant(of: tile, matching: find.byType(Text)),
        )
        .first
        .data!;
  }

  testWidgets('greets the signed-in member by first name', (tester) async {
    await pumpScreen(tester);

    final greeting = tester
        .widget<Text>(find.byKey(const ValueKey('dashboard-greeting')))
        .data!;
    expect(greeting, endsWith(', Alex 👋'));
  });

  testWidgets('summary tiles match the SLA counts', (tester) async {
    final appState = await pumpScreen(tester);
    final counts = appState.slaCounts();

    expect(tileValue(tester, 'tile-total'), '${appState.tasks.length}');
    expect(tileValue(tester, 'tile-on-track'), '${counts[SlaStatus.onTrack]}');
    expect(tileValue(tester, 'tile-at-risk'), '${counts[SlaStatus.atRisk]}');
    expect(tileValue(tester, 'tile-overdue'), '${counts[SlaStatus.overdue]}');
  });

  testWidgets('tiles update when a task changes', (tester) async {
    final appState = await pumpScreen(tester);
    final overdueBefore = appState.slaCounts()[SlaStatus.overdue]!;

    // t2 is the overdue seed task; finishing it clears the overdue count.
    await appState.updateTask(
      appState.taskById('t2')!.copyWith(status: TaskStatus.done),
    );
    await tester.pump();

    expect(tileValue(tester, 'tile-overdue'), '${overdueBefore - 1}');
  });

  testWidgets('SLA health shows the share of healthy tasks', (tester) async {
    final appState = await pumpScreen(tester);

    // Switch to All Time so every task is counted.
    await tester.tap(find.byKey(const ValueKey('health-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All Time').last);
    await tester.pumpAndSettle();

    final counts = appState.slaCounts();
    final healthy = counts[SlaStatus.onTrack]! + counts[SlaStatus.completed]!;
    final percent = (healthy / appState.tasks.length * 100).round();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('health-percent'))).data,
      '$percent% on track',
    );
  });

  testWidgets('lists the soonest open deadlines and opens a task', (
    tester,
  ) async {
    final appState = await pumpScreen(tester);
    final soonest =
        (appState.tasks.where((t) => !t.isDone).toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate)))
            .first;

    await tester.tap(find.text(soonest.title));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
  });
}
