import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/tasks/edit_task_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';
import 'package:sprintly/widgets/status_chip.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Opens Edit Task for a starter task from a host screen, the way the app
  // pushes it, on a tall screen so the whole form is laid out.
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EditTaskScreen(task: appState.taskById(taskId)!),
                    ),
                  ),
                  child: const Text('Open task'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open task'));
    await tester.pumpAndSettle();
    return appState;
  }

  String previewSla(WidgetTester tester) {
    return tester.widget<StatusChip>(find.byType(StatusChip)).label;
  }

  // Picks an option from the dropdown currently showing [current].
  Future<void> choose(WidgetTester tester, String current, String option) async {
    await tester.tap(find.text(current));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
  }

  testWidgets('the form opens filled in with the task', (tester) async {
    await pumpScreen(tester, 't1');

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Design Login Screen'), findsOneWidget);
    expect(find.text('Priya Sharma'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Mobile App'), findsOneWidget);
    expect(find.text('UI/UX'), findsOneWidget);
    expect(find.text('Frontend'), findsOneWidget);
    expect(previewSla(tester), 'At Risk');
  });

  testWidgets('required fields are validated and nothing is saved', (
    tester,
  ) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.enterText(find.byType(TextFormField).at(0), '  ');
    await tester.enterText(find.byType(TextFormField).at(1), '');
    await save(tester);

    expect(find.text('Please enter a task title'), findsOneWidget);
    expect(find.text('Please enter a description'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await save(tester);

    expect(
      find.text('Title must contain at least 3 characters'),
      findsOneWidget,
    );
    expect(find.text('Edit Task'), findsOneWidget);
    expect(appState.taskById('t1')!.title, 'Design Login Screen');
  });

  testWidgets('changes are saved and the screen closes', (tester) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' Build login screen ',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Email and password with validation.',
    );
    await choose(tester, 'Priya Sharma', 'Marcus Lee');
    await choose(tester, 'Mobile App', 'Web Dashboard');
    await save(tester);

    final saved = appState.taskById('t1')!;
    expect(saved.title, 'Build login screen');
    expect(saved.description, 'Email and password with validation.');
    expect(saved.assigneeId, 'm3');
    expect(saved.project, 'Web Dashboard');
    expect(saved.tags, ['UI/UX', 'Design', 'Frontend']);

    expect(find.text('Edit Task'), findsNothing);
    expect(find.text('Task updated.'), findsOneWidget);
  });

  testWidgets('marking the task done shows Completed before saving', (
    tester,
  ) async {
    final appState = await pumpScreen(tester, 't2');

    expect(previewSla(tester), 'Overdue');

    await choose(tester, 'In Progress', 'Done');

    expect(previewSla(tester), 'Completed');
    expect(appState.taskById('t2')!.status, TaskStatus.inProgress);

    await save(tester);

    expect(appState.taskById('t2')!.status, TaskStatus.done);
  });

  testWidgets('lowering the priority moves the task back to On Track', (
    tester,
  ) async {
    // t5 is due in two days: At Risk only because it is high priority.
    final appState = await pumpScreen(tester, 't5');

    expect(previewSla(tester), 'At Risk');

    await choose(tester, 'High', 'Low');

    expect(previewSla(tester), 'On Track');

    await save(tester);

    expect(appState.taskById('t5')!.priority, TaskPriority.low);
  });

  testWidgets('a new due date is saved and updates the SLA preview', (
    tester,
  ) async {
    // t2 is overdue; next year is always On Track.
    final appState = await pumpScreen(tester, 't2');
    final nextYear = DateTime.now().year + 1;

    await tester.tap(find.byType(TextFormField).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Switch to input'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.byType(TextField),
      ),
      '06/15/$nextYear',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('15 Jun $nextYear'), findsOneWidget);
    expect(previewSla(tester), 'On Track');

    await save(tester);

    expect(appState.taskById('t2')!.dueDate, DateTime(nextYear, 6, 15));
  });

  testWidgets('tags can be added and removed, but not duplicated', (
    tester,
  ) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.tap(find.byTooltip('Remove Design'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add tag'));
    await tester.pumpAndSettle();
    final tagField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(tagField, 'frontend');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('This tag is already on the task'), findsOneWidget);

    await tester.enterText(tagField, 'Auth');
    await tester.tap(find.widgetWithText(TextButton, 'Save'));
    await tester.pumpAndSettle();
    await save(tester);

    expect(appState.taskById('t1')!.tags, ['UI/UX', 'Frontend', 'Auth']);
  });

  testWidgets('delete asks first, then removes the task', (tester) async {
    final appState = await pumpScreen(tester, 't1');

    await tester.tap(find.text('Delete Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(appState.taskById('t1'), isNotNull);
    expect(find.text('Edit Task'), findsOneWidget);

    await tester.tap(find.text('Delete Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(appState.taskById('t1'), isNull);
    expect(find.text('Edit Task'), findsNothing);
    expect(find.text('Task deleted.'), findsOneWidget);
  });

  testWidgets('a task whose assignee was removed must be reassigned', (
    tester,
  ) async {
    final appState = await pumpScreen(tester, 't1');
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Point the task at a member that does not exist, then reopen it.
    await appState.updateTask(
      appState.taskById('t1')!.copyWith(assigneeId: 'gone', project: ''),
    );
    await tester.tap(find.text('Open task'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a team member'), findsOneWidget);
    expect(find.text('Choose a project'), findsOneWidget);

    await save(tester);

    expect(find.text('Please choose an assignee'), findsOneWidget);
    expect(appState.taskById('t1')!.assigneeId, 'gone');

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Emily Wong').last);
    await tester.pumpAndSettle();
    await save(tester);

    expect(appState.taskById('t1')!.assigneeId, 'm4');
  });
}
