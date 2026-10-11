import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/models/task.dart';
import 'package:sprintly/screens/tasks/task_detail_screen.dart';
import 'package:sprintly/screens/team/member_profile_screen.dart';
import 'package:sprintly/screens/team/member_tasks_sheet.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // opens the profile of Priya Sharma (m2) while signed in as Alex (m1).
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
          home: const MemberProfileScreen(memberId: 'm2'),
        ),
      ),
    );
    return appState;
  }

  String statValue(WidgetTester tester, String key) {
    final tile = find.byKey(ValueKey(key));
    return tester
        .widgetList<Text>(
          find.descendant(of: tile, matching: find.byType(Text)),
        )
        .last
        .data!;
  }

  testWidgets('shows the member and their details', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Priya Sharma'), findsWidgets);
    expect(find.text('Mobile Developer'), findsWidgets);
    expect(find.text('priya@sprintly.app'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('stat tiles match the member\'s tasks', (tester) async {
    final appState = await pumpScreen(tester);
    final tasks = appState.tasksFor('m2');

    expect(statValue(tester, 'profile-assigned'), '${tasks.length}');
    expect(
      statValue(tester, 'profile-completed'),
      '${tasks.where((t) => t.isDone).length}',
    );
    final active = tasks.where((t) => !t.isDone).length;
    expect(
      find.text('$active active ${active == 1 ? 'task' : 'tasks'}'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a current task opens its detail', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Design Login Screen'));
    await tester.pumpAndSettle();

    expect(find.byType(TaskDetailScreen), findsOneWidget);
  });

  testWidgets('View All opens the member\'s task list', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    expect(find.byType(MemberTasksSheet), findsOneWidget);
  });

  testWidgets('Assign New Task tells the user it is coming soon', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('assign-task-button')));
    await tester.pump();

    expect(find.textContaining('coming soon'), findsOneWidget);
  });

  testWidgets('stat tiles update when a task is completed', (tester) async {
    final appState = await pumpScreen(tester);
    final before = int.parse(statValue(tester, 'profile-completed'));

    final task = appState.tasksFor('m2').firstWhere((t) => !t.isDone);
    await appState.updateTask(task.copyWith(status: TaskStatus.done));
    await tester.pump();

    expect(statValue(tester, 'profile-completed'), '${before + 1}');
  });
}
