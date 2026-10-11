import 'package:flutter_test/flutter_test.dart';
import 'package:sprintly/core/sla/sla_status.dart';
import 'package:sprintly/models/task.dart';

void main() {
  // Fixed "now" so the tests do not depend on the day they run.
  final now = DateTime(2026, 10, 10, 9);

  Task taskDue(
    DateTime dueDate, {
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
  }) {
    return Task(
      id: 't',
      title: 'Task',
      description: 'Description',
      assigneeId: 'm1',
      dueDate: dueDate,
      status: status,
      priority: priority,
      createdAt: DateTime(2026, 10, 1),
    );
  }

  test('a done task is Completed even when its deadline has passed', () {
    final task = taskDue(DateTime(2026, 10, 1), status: TaskStatus.done);

    expect(classifySla(task, now: now), SlaStatus.completed);
  });

  test('an unfinished task past its deadline is Overdue', () {
    final task = taskDue(DateTime(2026, 10, 9));

    expect(classifySla(task, now: now), SlaStatus.overdue);
  });

  test('a task due today is At Risk, not Overdue, until the day ends', () {
    final task = taskDue(DateTime(2026, 10, 10));

    expect(classifySla(task, now: now), SlaStatus.atRisk);
  });

  test('a task due within 48 hours is At Risk', () {
    final task = taskDue(DateTime(2026, 10, 11));

    expect(classifySla(task, now: now), SlaStatus.atRisk);
  });

  test('a task due in more than 48 hours is On Track', () {
    final task = taskDue(DateTime(2026, 10, 12));

    expect(classifySla(task, now: now), SlaStatus.onTrack);
  });

  test('a high priority task becomes At Risk a day earlier', () {
    final dueDate = DateTime(2026, 10, 12);

    expect(
      classifySla(taskDue(dueDate, priority: TaskPriority.high), now: now),
      SlaStatus.atRisk,
    );
    expect(
      classifySla(taskDue(dueDate, priority: TaskPriority.medium), now: now),
      SlaStatus.onTrack,
    );
  });
}
