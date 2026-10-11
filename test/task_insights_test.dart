import 'package:flutter_test/flutter_test.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/core/sla/task_insights.dart';
import 'package:sprintly/models/task.dart';

void main() {
  // Fixed "now" so every expectation is stable: Wednesday 10 Dec 2025, noon.
  final now = DateTime(2025, 12, 10, 12);

  Task task(
    String id,
    DateTime due, {
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String project = 'Mobile App',
  }) {
    return Task(
      id: id,
      title: 'Task $id',
      description: '',
      assigneeId: 'm1',
      dueDate: due,
      createdAt: DateTime(2025, 12, 1),
      status: status,
      priority: priority,
      project: project,
    );
  }

  DateTime inDays(int days) => DateTime(2025, 12, 10 + days);

  group('dueLabel', () {
    test('describes past, current and future due days', () {
      expect(dueLabel(task('a', inDays(-3)), now: now), '3 days ago');
      expect(dueLabel(task('b', inDays(-1)), now: now), '1 day ago');
      expect(dueLabel(task('c', inDays(0)), now: now), 'Due today');
      expect(dueLabel(task('d', inDays(1)), now: now), 'Due tomorrow');
      expect(dueLabel(task('e', inDays(5)), now: now), 'Due in 5 days');
    });
  });

  group('groupAlerts', () {
    final tasks = [
      task('late-2', inDays(-1)),
      task('late-1', inDays(-4)),
      task('risk', inDays(1)),
      task('soon', inDays(5)),
      task('later', inDays(20)),
      task('done', inDays(-2), status: TaskStatus.done),
    ];

    test('puts each task in the right section', () {
      final groups = groupAlerts(tasks, now: now);

      expect(groups.overdue.map((t) => t.id), ['late-1', 'late-2']);
      expect(groups.atRisk.map((t) => t.id), ['risk']);
      expect(groups.upcoming.map((t) => t.id), ['soon']);
      expect(groups.onTrackCount, 2);
    });

    test('ignores completed tasks', () {
      final groups = groupAlerts(tasks, now: now);
      final ids = [
        ...groups.overdue,
        ...groups.atRisk,
        ...groups.upcoming,
      ].map((t) => t.id);
      expect(ids, isNot(contains('done')));
    });

    test('an empty list gives empty groups', () {
      final groups = groupAlerts([], now: now);
      expect(groups.overdue, isEmpty);
      expect(groups.onTrackCount, 0);
    });
  });

  group('monthGrid', () {
    test('December 2025 starts on Monday 1 Dec and fills whole weeks', () {
      final days = monthGrid(DateTime(2025, 12));
      expect(days.first, DateTime(2025, 12, 1));
      expect(days.length % 7, 0);
      expect(days.last.weekday, DateTime.sunday);
      expect(days.last, DateTime(2026, 1, 4));
    });

    test('pads the first week with the previous month', () {
      // 1 October 2025 is a Wednesday, so Mon 29 and Tue 30 Sep lead in.
      final days = monthGrid(DateTime(2025, 10));
      expect(days.first, DateTime(2025, 9, 29));
      expect(days[2], DateTime(2025, 10, 1));
    });

    test('February in a leap year has 29 days in the grid', () {
      final days = monthGrid(DateTime(2028, 2));
      final february = days.where((d) => d.month == 2);
      expect(february.length, 29);
    });
  });

  group('calendar grouping', () {
    test('tasksByDay keys tasks by midnight of their due day', () {
      final byDay = tasksByDay([
        task('a', DateTime(2025, 12, 12, 9)),
        task('b', DateTime(2025, 12, 12, 17)),
        task('c', DateTime(2025, 12, 13)),
      ]);
      expect(byDay[DateTime(2025, 12, 12)]!.length, 2);
      expect(byDay[DateTime(2025, 12, 13)]!.length, 1);
    });

    test('statusesForDay lists distinct statuses, most urgent first', () {
      final statuses = statusesForDay([
        task('ok', inDays(10)),
        task('late', inDays(-1)),
        task('ok-2', inDays(10)),
      ], now: now);
      expect(statuses, [SlaStatus.overdue, SlaStatus.onTrack]);
    });
  });

  group('statistics', () {
    test('This Month keeps only tasks due in the current month', () {
      final tasks = [
        task('dec', DateTime(2025, 12, 28)),
        task('nov', DateTime(2025, 11, 28)),
        task('jan', DateTime(2026, 1, 2)),
      ];
      final month = tasksInRange(tasks, StatsRange.thisMonth, now: now);
      expect(month.map((t) => t.id), ['dec']);
      expect(tasksInRange(tasks, StatsRange.allTime, now: now).length, 3);
    });

    test('percentOf rounds and never divides by zero', () {
      expect(percentOf(2, 3), 67);
      expect(percentOf(1, 0), 0);
    });

    test('projectProgress counts done and total per project', () {
      final progress = projectProgress([
        task('1', inDays(1), status: TaskStatus.done),
        task('2', inDays(1)),
        task('3', inDays(1), project: 'Docs', status: TaskStatus.done),
        task('4', inDays(1), project: ''),
      ]);

      expect(progress.first.name, 'Mobile App');
      expect(progress.first.done, 1);
      expect(progress.first.total, 2);
      expect(progress.first.share, 0.5);
      expect(progress.map((p) => p.name), contains('No project'));
    });
  });
}
