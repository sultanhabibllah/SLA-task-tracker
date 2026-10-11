import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sprintly/core/theme/app_colors.dart';
import 'package:sprintly/core/theme/app_theme.dart';
import 'package:sprintly/screens/tasks/task_detail_screen.dart';
import 'package:sprintly/services/storage_service.dart';
import 'package:sprintly/state/app_state.dart';
import 'package:sprintly/widgets/count_tile.dart';
import 'package:sprintly/widgets/member_avatar.dart';
import 'package:sprintly/widgets/task_summary_row.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<AppState> pump(WidgetTester tester, Widget child) async {
    final appState = AppState(StorageService());
    await appState.load();
    await appState.signIn('m1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      ),
    );
    return appState;
  }

  group('CountTile', () {
    testWidgets('shows the count and the label', (tester) async {
      await pump(
        tester,
        const CountTile(
          icon: Icons.error_outline,
          color: AppColors.overdue,
          background: AppColors.softRed,
          count: 7,
          label: 'Overdue',
        ),
      );

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
    });
  });

  group('TaskSummaryRow', () {
    testWidgets('shows the title, project, assignee and trailing widget', (
      tester,
    ) async {
      final appState = AppState(StorageService());
      await appState.load();
      final task = appState.taskById('t1')!;

      await pump(
        tester,
        TaskSummaryRow(task: task, trailing: const Text('Due tomorrow')),
      );

      expect(find.text('Design Login Screen'), findsOneWidget);
      expect(find.text('Mobile App - Priya Sharma'), findsOneWidget);
      expect(find.byType(MemberAvatar), findsOneWidget);
      expect(find.text('Due tomorrow'), findsOneWidget);
    });

    testWidgets('tapping opens the task detail screen', (tester) async {
      final appState = AppState(StorageService());
      await appState.load();
      final task = appState.taskById('t1')!;

      await pump(tester, TaskSummaryRow(task: task));
      await tester.tap(find.byKey(const ValueKey('task-row-t1')));
      await tester.pumpAndSettle();

      expect(find.byType(TaskDetailScreen), findsOneWidget);
    });

    testWidgets('a custom onTap replaces the default navigation', (
      tester,
    ) async {
      final appState = AppState(StorageService());
      await appState.load();
      var tapped = false;

      await pump(
        tester,
        TaskSummaryRow(
          task: appState.taskById('t1')!,
          onTap: () => tapped = true,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('task-row-t1')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(TaskDetailScreen), findsNothing);
    });

    test('projectIcon falls back for unknown projects', () {
      expect(projectIcon('Mobile App'), Icons.phone_iphone_rounded);
      expect(projectIcon('Something new'), Icons.task_alt_rounded);
    });
  });
}
