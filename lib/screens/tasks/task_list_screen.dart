import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';

  static const List<String> _filters = [
    'All',
    'On Track',
    'At Risk',
    'Overdue',
    'Completed',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _slaLabel(Task task, AppState state) {
    switch (state.slaOf(task).name) {
      case 'onTrack':
        return 'On Track';
      case 'atRisk':
        return 'At Risk';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Completed';
      default:
        return 'On Track';
    }
  }

  Color _slaColor(String status) {
    switch (status) {
      case 'On Track':
        return AppColors.onTrack;
      case 'At Risk':
        return AppColors.atRisk;
      case 'Overdue':
        return AppColors.overdue;
      case 'Completed':
        return AppColors.completed;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _slaBackground(String status) {
    switch (status) {
      case 'On Track':
        return AppColors.softGreen;
      case 'At Risk':
        return AppColors.softYellow;
      case 'Overdue':
        return AppColors.softRed;
      case 'Completed':
        return AppColors.softBlue;
      default:
        return AppColors.background;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  List<Task> _filteredTasks(AppState state) {
    final query = _searchController.text.trim().toLowerCase();

    return state.tasks.where((task) {
      final member = state.memberById(task.assigneeId);
      final assignee = member?.name ?? '';

      final matchesSearch =
          task.title.toLowerCase().contains(query) ||
          task.project.toLowerCase().contains(query) ||
          assignee.toLowerCase().contains(query);

      final matchesStatus =
          _selectedFilter == 'All' || _slaLabel(task, state) == _selectedFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildTaskCard(Task task, AppState state) {
    final member = state.memberById(task.assigneeId);
    final status = _slaLabel(task, state);

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
              const SizedBox(width: 8),
              Icon(Icons.more_horiz, color: AppColors.textSecondary),
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

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _slaBackground(status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _slaColor(status),
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${task.priority.label} Priority',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(height: 1, color: AppColors.border),

          const SizedBox(height: 14),

          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.midnight,
                child: Text(
                  member?.initials ?? '?',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lime,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  member?.name ?? 'Unassigned',
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
                _formatDate(task.dueDate),
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
    final state = context.watch<AppState>();
    final visibleTasks = _filteredTasks(state);

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          children: [
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
              '${state.tasks.length} tasks in your workspace',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: Icon(Icons.search),
              ),
            ),

            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final selected = _selectedFilter == filter;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      showCheckmark: false,
                      backgroundColor: AppColors.white,
                      selectedColor: AppColors.lime,
                      side: BorderSide(
                        color: selected ? AppColors.lime : AppColors.border,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
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

            if (visibleTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
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
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedFilter = 'All';
                        });
                      },
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              )
            else
              ...visibleTasks.map((task) => _buildTaskCard(task, state)),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
