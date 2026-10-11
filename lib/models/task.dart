enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

extension TaskPriorityLabel on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}

extension TaskStatusLabel on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String assigneeId;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String project;
  final List<String> tags;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.dueDate,
    required this.createdAt,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    required this.project,
    this.tags = const [],
  });

  bool get isDone => status == TaskStatus.done;

  // A task is due by the end of its due day, not at midnight when it starts.
  DateTime get deadline {
    return DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
  }

  Task copyWith({
    String? title,
    String? description,
    String? assigneeId,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    String? project,
    List<String>? tags,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      project: project ?? this.project,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigneeId': assigneeId,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'status': status.name,
      'project': project,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Any field added later must be read with a default here, otherwise tasks
  // saved by an older version of the app can no longer be loaded.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      assigneeId: json['assigneeId'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      priority: TaskPriority.values.byName(json['priority'] as String),
      status: TaskStatus.values.byName(json['status'] as String),
      project: json['project'] as String? ?? '',
      tags: (json['tags'] as List? ?? []).cast<String>(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
