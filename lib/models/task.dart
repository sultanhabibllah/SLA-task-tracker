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

// a file that could be attached to a task
class TaskAttachment {
  final String name;
  final String size;

  const TaskAttachment({required this.name, required this.size});

  Map<String, dynamic> toJson() => {'name': name, 'size': size};

  factory TaskAttachment.fromJson(Map<String, dynamic> json) {
    return TaskAttachment(
      name: json['name'] as String,
      size: json['size'] as String? ?? '',
    );
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
  final List<TaskAttachment> attachments;
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
    this.attachments = const [],
  });

  bool get isDone => status == TaskStatus.done;

  // task is due by the end(23:59) of its due day (not midnight to avoid confusion)
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
    List<TaskAttachment>? attachments,
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
      attachments: attachments ?? this.attachments,
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
      'attachments': [for (final a in attachments) a.toJson()],
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
      attachments: [
        for (final a in json['attachments'] as List? ?? [])
          TaskAttachment.fromJson(a as Map<String, dynamic>),
      ],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
