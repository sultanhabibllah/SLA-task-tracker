
enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

enum SlaStatus { onTrack, atRisk, overdue, completed }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignee;
  final String project;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime deadline;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.project,
    required this.priority,
    required this.status,
    required this.deadline,
    required this.createdAt,
  });

  SlaStatus get slaStatus {
    if (status == TaskStatus.done) {
      return SlaStatus.completed;
    }

    final remaining = deadline.difference(DateTime.now());

    if (remaining.isNegative) {
      return SlaStatus.overdue;
    }

    if (remaining <= const Duration(hours: 48)) {
      return SlaStatus.atRisk;
    }

    return SlaStatus.onTrack;
  }
}
