import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/tasks/edit_task_screen.dart';
import 'package:sprintly/screens/tasks/task_detail_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // opens Task Detail for the given seed task on a tall screen
  Future<AppState> pumpScreen(WidgetTester tester, String taskId) async {
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
          home: TaskDetailScreen(taskId: taskId),
        ),
      ),
    );
    return appState;
  }

  testWidgets('shows the task, its SLA status and attachment', (tester) async {
    await pumpScreen(tester, 't1');

    expect(find.text('Design Login Screen'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('login-design.fig'), findsOneWidget);
    expect(find.text('Attachments (1)'), findsOneWidget);
    // t1 is high priority and due tomorrow, so it is At Risk.
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('task-sla-label'))).data,
      'At Risk',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('task-countdown'))).data,
      '1 day left',
    );
  });

  testWidgets('shows how late an overdue task is', (tester) async {
    await pumpScreen(tester, 't2');

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('task-sla-label'))).data,
      'Overdue',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('task-countdown'))).data,
      '2 days late',
    );
  });

  testWidgets('Mark as Complete saves the task as done', (tester) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.tap(find.byKey(const ValueKey('mark-complete-button')));
    await tester.pumpAndSettle();

    expect(appState.taskById('t1')!.status, TaskStatus.done);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('task-sla-label'))).data,
      'Completed',
    );
    expect(find.text('Completed'), findsWidgets);

    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('mark-complete-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('changing the status dropdown updates the task', (tester) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.tap(find.byKey(const ValueKey('task-status-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To Do').last);
    await tester.pumpAndSettle();

    expect(appState.taskById('t1')!.status, TaskStatus.todo);
  });

  testWidgets('Edit Task opens the edit form', (tester) async {
    await pumpScreen(tester, 't1');

    await tester.tap(find.byKey(const ValueKey('edit-task-button')));
    await tester.pumpAndSettle();

    expect(find.byType(EditTaskScreen), findsOneWidget);
  });

  testWidgets('closes itself when the task is deleted', (tester) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final appState = AppState(StorageService());
    await appState.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TaskDetailScreen(taskId: 't1'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailScreen), findsOneWidget);

    await appState.deleteTask('t1');
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsNothing);
  });
}
