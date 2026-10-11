
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum TaskSlaStatus {
  onTrack,
  atRisk,
  overdue,
  completed,
}

class SprintlyTask {
  final String title;
  final String project;
  final String assignee;
  final String initials;
  final String priority;
  final DateTime deadline;
  final bool completed;

  const SprintlyTask({
    required this.title,
    required this.project,
    required this.assignee,
    required this.initials,
    required this.priority,
    required this.deadline,
    this.completed = false,
  });

  TaskSlaStatus get slaStatus {
    if (completed) return TaskSlaStatus.completed;

    final timeLeft = deadline.difference(DateTime.now());

    if (timeLeft.isNegative) {
      return TaskSlaStatus.overdue;
    }

    if (timeLeft <= const Duration(hours: 48)) {
      return TaskSlaStatus.atRisk;
    }

    return TaskSlaStatus.onTrack;
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String selectedFilter = 'All';

  final List<String> filters = [
    'All',
    'On Track',
    'At Risk',
    'Overdue',
    'Completed',
  ];

  late final List<SprintlyTask> tasks = [
    SprintlyTask(
      title: 'Design Login Screen',
      project: 'Mobile App',
      assignee: 'Priya Sharma',
      initials: 'PS',
      priority: 'High',
      deadline: DateTime.now().add(const Duration(days: 5)),
    ),
    SprintlyTask(
      title: 'Implement Local Storage',
      project: 'Mobile App',
      assignee: 'James Wilson',
      initials: 'JW',
      priority: 'High',
      deadline: DateTime.now().add(const Duration(hours: 24)),
    ),
    SprintlyTask(
      title: 'Write API Documentation',
      project: 'Backend',
      assignee: 'Alex Carter',
      initials: 'AC',
      priority: 'Medium',
      deadline: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SprintlyTask(
      title: 'Update Design System',
      project: 'UI/UX',
      assignee: 'Priya Sharma',
      initials: 'PS',
      priority: 'Low',
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      completed: true,
    ),
    SprintlyTask(
      title: 'Test Authentication Flow',
      project: 'Mobile App',
      assignee: 'James Wilson',
      initials: 'JW',
      priority: 'Medium',
      deadline: DateTime.now().add(const Duration(days: 7)),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String getStatusLabel(TaskSlaStatus status) {
    switch (status) {
      case TaskSlaStatus.onTrack:
        return 'On Track';
      case TaskSlaStatus.atRisk:
        return 'At Risk';
      case TaskSlaStatus.overdue:
        return 'Overdue';
      case TaskSlaStatus.completed:
        return 'Completed';
    }
  }

  Color getStatusColor(TaskSlaStatus status) {
    switch (status) {
      case TaskSlaStatus.onTrack:
        return AppColors.onTrack;
      case TaskSlaStatus.atRisk:
        return AppColors.atRisk;
      case TaskSlaStatus.overdue:
        return AppColors.overdue;
      case TaskSlaStatus.completed:
        return AppColors.completed;
    }
  }

  Color getStatusBackground(TaskSlaStatus status) {
    switch (status) {
      case TaskSlaStatus.onTrack:
        return AppColors.softGreen;
      case TaskSlaStatus.atRisk:
        return AppColors.softYellow;
      case TaskSlaStatus.overdue:
        return AppColors.softRed;
      case TaskSlaStatus.completed:
        return AppColors.softBlue;
    }
  }

  List<SprintlyTask> get filteredTasks {
    final search = _searchController.text.toLowerCase().trim();

    return tasks.where((task) {
      final matchesSearch =
          task.title.toLowerCase().contains(search) ||
          task.project.toLowerCase().contains(search) ||
          task.assignee.toLowerCase().contains(search);

      final matchesFilter =
          selectedFilter == 'All' ||
          getStatusLabel(task.slaStatus) == selectedFilter;

      return matchesSearch && matchesFilter;
    }).toList();
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget buildTaskCard(SprintlyTask task) {
    final status = task.slaStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                ),
                onSelected: (value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$value: ${task.title}'),
                    ),
                  );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'View task',
                    child: Text('View task'),
                  ),
                  const PopupMenuItem(
                    value: 'Edit task',
                    child: Text('Edit task'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            task.project,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getStatusBackground(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(status),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.priority} Priority',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            color: AppColors.border,
            height: 1,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.midnight,
                child: Text(
                  task.initials,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  task.assignee,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 6),

              Text(
                formatDate(task.deadline),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = filteredTasks;

    return Scaffold(
      backgroundColor: AppColors.background,

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.lime,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Create Task screen coming next'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          children: [
            // Branding
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.midnight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: AppColors.lime,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Sprintly',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.midnight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            const Text(
              'Tasks',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              '${tasks.length} tasks in your workspace',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            // Search field
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 20),

            // SLA filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filters.map((filter) {
                  final selected = selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      showCheckmark: false,
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.lime,
                      side: BorderSide(
                        color: selected
                            ? AppColors.lime
                            : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: AppColors.midnight,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      onSelected: (_) {
                        setState(() {
                          selectedFilter = filter;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${visibleTasks.length} results',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Task cards or empty state
            if (visibleTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 64),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No tasks found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Try another search or filter.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          selectedFilter = 'All';
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              )
            else
              ...visibleTasks.map(buildTaskCard),

            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
