import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/tasks/task_list_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    appState = AppState(StorageService());
    await appState.load();

    // Use a controlled task dataset for predictable tests.
    for (final task in List<Task>.from(appState.tasks)) {
      await appState.deleteTask(task.id);
    }

    final now = DateTime.now();
    final memberId = appState.members.first.id;

    await appState.addTask(
      Task(
        id: 'task-001',
        title: 'Design Login Screen',
        description: 'Design the sign-in interface',
        assigneeId: memberId,
        dueDate: now.add(const Duration(days: 7)),
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        project: 'Mobile App',
        createdAt: now,
      ),
    );

    await appState.addTask(
      Task(
        id: 'task-002',
        title: 'Implement Local Storage',
        description: 'Save application data locally',
        assigneeId: memberId,
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        project: 'Backend',
        createdAt: now,
      ),
    );

    await appState.addTask(
      Task(
        id: 'task-003',
        title: 'Complete Design Review',
        description: 'Review final interface designs',
        assigneeId: memberId,
        dueDate: now.subtract(const Duration(days: 2)),
        priority: TaskPriority.low,
        status: TaskStatus.done,
        project: 'UI/UX',
        createdAt: now,
      ),
    );
  });

  tearDown(() {
    appState.dispose();
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(home: TaskListScreen()),
    );
  }

  group('Task List Screen', () {
    testWidgets('Displays tasks from AppState', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Tasks'), findsOneWidget);

      expect(find.text('3 tasks in your workspace'), findsOneWidget);

      expect(find.text('Design Login Screen'), findsOneWidget);
    });

    testWidgets('Search filters tasks by title', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(find.byType(TextField).first, 'Login');

      await tester.pumpAndSettle();

      expect(find.text('Design Login Screen'), findsOneWidget);

      expect(find.text('Implement Local Storage'), findsNothing);

      expect(find.text('1 results'), findsOneWidget);
    });

    testWidgets('Shows empty state for unknown tasks', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(
        find.byType(TextField).first,
        'Nonexistent Sprintly Task',
      );

      await tester.pumpAndSettle();

      expect(find.text('No tasks found'), findsOneWidget);

      expect(find.text('0 results'), findsOneWidget);

      // Verify that clearing the filter restores the list.
      await tester.ensureVisible(find.text('Clear filters'));

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.text('3 results'), findsOneWidget);
    });

    testWidgets('Completed filter shows only completed tasks', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final completedFilter = find.widgetWithText(ChoiceChip, 'Completed');

      // Scroll the horizontal filter row if needed.
      await tester.scrollUntilVisible(
        completedFilter,
        100,
        scrollable: find.byType(Scrollable).at(1),
        scrollDirection: AxisDirection.right,
      );

      await tester.tap(completedFilter);
      await tester.pumpAndSettle();

      expect(find.text('Complete Design Review'), findsOneWidget);

      expect(find.text('Design Login Screen'), findsNothing);

      expect(find.text('Implement Local Storage'), findsNothing);

      expect(find.text('1 results'), findsOneWidget);
    });
  });
}
