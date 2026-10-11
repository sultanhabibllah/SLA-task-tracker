import '../../models/task.dart';
import 'sla_status.dart';

// Helpers that turn the task list into the groups, days and counts shown on
// the Alerts, Calendar and Statistics screens. They are plain functions so
// the screens stay simple and the rules can be unit tested.

// How far ahead the Alerts screen looks for upcoming on-track deadlines.
const upcomingWindow = Duration(days: 7);

// Midnight at the start of the given day.
DateTime dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Whole days from one date to another, ignoring the time of day. UTC is used
// so a daylight saving change cannot turn a day into 23 hours.
int daysBetween(DateTime from, DateTime to) {
  final start = DateTime.utc(from.year, from.month, from.day);
  final end = DateTime.utc(to.year, to.month, to.day);
  return end.difference(start).inDays;
}

// Copy of the tasks sorted by due date, soonest first.
List<Task> sortedByDueDate(Iterable<Task> tasks) {
  return tasks.toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}

// Short due label such as "3 days ago", "Due today" or "Due in 2 days".
String dueLabel(Task task, {DateTime? now}) {
  final days = daysBetween(now ?? DateTime.now(), task.dueDate);
  if (days < -1) return '${-days} days ago';
  if (days == -1) return '1 day ago';
  if (days == 0) return 'Due today';
  if (days == 1) return 'Due tomorrow';
  return 'Due in $days days';
}

// Alerts

class AlertGroups {
  const AlertGroups({
    required this.overdue,
    required this.atRisk,
    required this.upcoming,
    required this.onTrackCount,
  });

  final List<Task> overdue;
  final List<Task> atRisk;
  // On-track tasks that are due inside the upcoming window.
  final List<Task> upcoming;
  final int onTrackCount;
}

// Splits the tasks into the sections of the Alerts screen. Each list is
// sorted by due date so the most urgent task comes first.
AlertGroups groupAlerts(Iterable<Task> tasks, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final limit = current.add(upcomingWindow);

  final overdue = <Task>[];
  final atRisk = <Task>[];
  final upcoming = <Task>[];
  var onTrackCount = 0;

  for (final task in tasks) {
    switch (classifySla(task, now: current)) {
      case SlaStatus.overdue:
        overdue.add(task);
      case SlaStatus.atRisk:
        atRisk.add(task);
      case SlaStatus.onTrack:
        onTrackCount++;
        if (task.deadline.isBefore(limit)) upcoming.add(task);
      case SlaStatus.completed:
        break;
    }
  }

  return AlertGroups(
    overdue: sortedByDueDate(overdue),
    atRisk: sortedByDueDate(atRisk),
    upcoming: sortedByDueDate(upcoming),
    onTrackCount: onTrackCount,
  );
}

// Calendar

// Every day shown for a month, Monday first, padded with the days of the
// previous and next month so the grid is made of whole weeks.
List<DateTime> monthGrid(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final last = DateTime(month.year, month.month + 1, 0);
  final leading = first.weekday - DateTime.monday;
  final trailing = DateTime.sunday - last.weekday;
  final count = leading + last.day + trailing;

  // Building each day from its parts avoids daylight saving surprises that
  // adding Duration(days: 1) can cause.
  return [
    for (var i = 0; i < count; i++)
      DateTime(month.year, month.month, 1 - leading + i),
  ];
}

// Tasks grouped by the day they are due, keyed by midnight of that day.
Map<DateTime, List<Task>> tasksByDay(Iterable<Task> tasks) {
  final byDay = <DateTime, List<Task>>{};
  for (final task in tasks) {
    byDay.putIfAbsent(dayOnly(task.dueDate), () => []).add(task);
  }
  return byDay;
}

// Order the calendar dots are drawn in, most urgent first.
const _dotOrder = [
  SlaStatus.overdue,
  SlaStatus.atRisk,
  SlaStatus.onTrack,
  SlaStatus.completed,
];

// The distinct SLA statuses among a day's tasks, most urgent first.
List<SlaStatus> statusesForDay(Iterable<Task> tasks, {DateTime? now}) {
  final found = {for (final task in tasks) classifySla(task, now: now)};
  return [for (final status in _dotOrder) if (found.contains(status)) status];
}

// Statistics

enum StatsRange { thisMonth, allTime }

extension StatsRangeLabel on StatsRange {
  String get label {
    switch (this) {
      case StatsRange.thisMonth:
        return 'This Month';
      case StatsRange.allTime:
        return 'All Time';
    }
  }
}

// "This Month" keeps the tasks due in the current calendar month.
List<Task> tasksInRange(
  Iterable<Task> tasks,
  StatsRange range, {
  DateTime? now,
}) {
  if (range == StatsRange.allTime) return tasks.toList();
  final current = now ?? DateTime.now();
  return tasks
      .where(
        (task) =>
            task.dueDate.year == current.year &&
            task.dueDate.month == current.month,
      )
      .toList();
}

// Whole-number percentage, 0 when there is nothing to divide by.
int percentOf(int part, int total) {
  if (total == 0) return 0;
  return (part * 100 / total).round();
}

class ProjectProgress {
  const ProjectProgress({
    required this.name,
    required this.done,
    required this.total,
  });

  final String name;
  final int done;
  final int total;

  double get share => total == 0 ? 0 : done / total;
}

// Done and total task counts per project, largest project first.
List<ProjectProgress> projectProgress(Iterable<Task> tasks) {
  final done = <String, int>{};
  final total = <String, int>{};
  for (final task in tasks) {
    final name = task.project.isEmpty ? 'No project' : task.project;
    total[name] = (total[name] ?? 0) + 1;
    if (task.isDone) done[name] = (done[name] ?? 0) + 1;
  }

  final list = [
    for (final name in total.keys)
      ProjectProgress(name: name, done: done[name] ?? 0, total: total[name]!),
  ];
  list.sort((a, b) {
    final bySize = b.total.compareTo(a.total);
    return bySize != 0 ? bySize : a.name.compareTo(b.name);
  });
  return list;
}
