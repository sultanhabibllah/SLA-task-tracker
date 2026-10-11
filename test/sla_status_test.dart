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
      project: 'Mobile App',
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

  test('the deadline is the last second of the due day', () {
    final task = taskDue(DateTime(2026, 10, 10));

    expect(
      classifySla(task, now: DateTime(2026, 10, 10, 23, 59, 59)),
      SlaStatus.atRisk,
    );
    expect(
      classifySla(task, now: DateTime(2026, 10, 11)),
      SlaStatus.overdue,
    );
  });

  test('exactly 48 hours left is At Risk, one second more is On Track', () {
    final task = taskDue(DateTime(2026, 10, 12));
    final exactly48h = task.deadline.subtract(const Duration(hours: 48));

    expect(classifySla(task, now: exactly48h), SlaStatus.atRisk);
    expect(
      classifySla(
        task,
        now: exactly48h.subtract(const Duration(seconds: 1)),
      ),
      SlaStatus.onTrack,
    );
  });

  test('high priority: exactly 72 hours left is At Risk, more is On Track', () {
    final task = taskDue(DateTime(2026, 10, 14), priority: TaskPriority.high);
    final exactly72h = task.deadline.subtract(const Duration(hours: 72));

    expect(classifySla(task, now: exactly72h), SlaStatus.atRisk);
    expect(
      classifySla(
        task,
        now: exactly72h.subtract(const Duration(seconds: 1)),
      ),
      SlaStatus.onTrack,
    );
  });

  test('low priority uses the same 48 hour window as medium', () {
    final dueDate = DateTime(2026, 10, 12);

    expect(
      classifySla(taskDue(dueDate, priority: TaskPriority.low), now: now),
      SlaStatus.onTrack,
    );
    expect(
      classifySla(
        taskDue(DateTime(2026, 10, 11), priority: TaskPriority.low),
        now: now,
      ),
      SlaStatus.atRisk,
    );
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
