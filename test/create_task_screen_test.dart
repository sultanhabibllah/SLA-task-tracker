import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sprintly/core/theme/app_colors.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/tasks/create_task_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    appState = AppState(StorageService());
    await appState.load();
  });

  tearDown(() {
    appState.dispose();
  });

  Widget buildTestApp() {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(home: CreateTaskScreen()),
    );
  }

  Future<void> tapCreateButton(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'Create Task');

    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('Create Task Screen', () {
    testWidgets('Displays the required form fields', (tester) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('New task'), findsOneWidget);
      expect(find.text('Task name *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);

      await tester.ensureVisible(find.text('Assign to *'));
      expect(find.text('Assign to *'), findsOneWidget);

      await tester.ensureVisible(find.text('Deadline *'));
      expect(find.text('Deadline *'), findsOneWidget);

      await tester.ensureVisible(find.text('Priority'));
      expect(find.text('Priority'), findsOneWidget);

      await tester.ensureVisible(find.text('Project *'));
      expect(find.text('Project *'), findsOneWidget);
    });

    testWidgets('Rejects an empty task form', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final initialCount = appState.tasks.length;

      await tapCreateButton(tester);

      expect(find.text('Task name is required'), findsOneWidget);

      await tester.ensureVisible(find.text('Select an assignee'));

      expect(find.text('Select an assignee'), findsOneWidget);

      expect(appState.tasks.length, initialCount);
    });

    testWidgets('Rejects task names shorter than 3 characters', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter task name'),
        'AB',
      );

      await tapCreateButton(tester);

      expect(find.text('Enter at least 3 characters'), findsOneWidget);

      expect(find.text('Task name is required'), findsNothing);
    });

    testWidgets('Shows deadline validation error', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tapCreateButton(tester);

      await tester.ensureVisible(find.text('Select a deadline'));

      expect(find.text('Select a deadline'), findsOneWidget);
    });

    testWidgets('Shows project validation error', (tester) async {
      await tester.pumpWidget(buildTestApp());

      await tapCreateButton(tester);

      await tester.ensureVisible(find.text('Select a project'));

      expect(find.text('Select a project'), findsOneWidget);
    });

    testWidgets('Allows selecting High priority', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final highPriority = find.text('High');

      await tester.ensureVisible(highPriority);
      await tester.tap(highPriority);
      await tester.pumpAndSettle();

      final selectedContainer = find.ancestor(
        of: highPriority,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;

          final decoration = widget.decoration;

          return decoration is BoxDecoration &&
              decoration.color == AppColors.softGreen;
        }),
      );

      expect(selectedContainer, findsWidgets);
    });

    testWidgets('Invalid submission does not create a task', (tester) async {
      await tester.pumpWidget(buildTestApp());

      final initialCount = appState.tasks.length;

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter task name'),
        'Valid Task Name',
      );

      await tapCreateButton(tester);

      expect(appState.tasks.length, initialCount);
    });
  });
}
