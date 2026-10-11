import 'package:flutter_test/flutter_test.dart';
import 'package:sprintly/core/sla/task_insights.dart';
import 'package:sprintly/models/task.dart';

// Rough performance guard for the helpers the Alerts, Calendar and
// Statistics screens call on every rebuild. The budgets are generous so the
// test only fails on a real slowdown, such as an accidental nested loop.
void main() {
  const taskCount = 20000;
  final now = DateTime(2025, 12, 10, 12);

  final tasks = [
    for (var i = 0; i < taskCount; i++)
      Task(
        id: 't$i',
        title: 'Task $i',
        description: '',
        assigneeId: 'm${i % 6}',
        dueDate: DateTime(2025, 12, 10 + (i % 120) - 60),
        createdAt: DateTime(2025, 1, 1),
        status: i % 5 == 0 ? TaskStatus.done : TaskStatus.todo,
        priority: TaskPriority.values[i % 3],
        project: 'Project ${i % 8}',
      ),
  ];

  // Runs the action once to warm up, then times a second run.
  Duration time(void Function() action) {
    action();
    final watch = Stopwatch()..start();
    action();
    return watch.elapsed;
  }

  const budget = Duration(milliseconds: 500);

  test('groupAlerts handles $taskCount tasks within budget', () {
    final elapsed = time(() => groupAlerts(tasks, now: now));
    expect(elapsed, lessThan(budget), reason: 'took $elapsed');
  });

  test('tasksByDay and a month of dots handle $taskCount tasks', () {
    final elapsed = time(() {
      final byDay = tasksByDay(tasks);
      for (final day in monthGrid(DateTime(2025, 12))) {
        statusesForDay(byDay[day] ?? const [], now: now);
      }
    });
    expect(elapsed, lessThan(budget), reason: 'took $elapsed');
  });

  test('statistics helpers handle $taskCount tasks within budget', () {
    final elapsed = time(() {
      tasksInRange(tasks, StatsRange.thisMonth, now: now);
      projectProgress(tasks);
      sortedByDueDate(tasks);
    });
    expect(elapsed, lessThan(budget), reason: 'took $elapsed');
  });
}
