import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/status_chip.dart';
import '../tasks/edit_task_screen.dart';

// Bottom sheet listing the tasks assigned to one member, soonest due first.
// Tapping a task opens it for editing.
class MemberTasksSheet extends StatelessWidget {
  const MemberTasksSheet({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = appState.tasksFor(member.id)
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${member.name}\'s tasks',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No tasks assigned yet.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              // Flexible lets a long list scroll inside the sheet.
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 24, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _taskRow(context, appState, task);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _taskRow(BuildContext context, AppState appState, Task task) {
    final dueDate = DateFormat('d MMM yyyy').format(task.dueDate);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due $dueDate · ${task.priority.label} priority',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SlaChip(status: appState.slaOf(task)),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
