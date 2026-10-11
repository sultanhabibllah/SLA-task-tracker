import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../models/task.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../state/app_state.dart';
import 'member_avatar.dart';

// Icon shown in the rounded square beside a task, picked by project.
IconData projectIcon(String project) {
  switch (project) {
    case 'Mobile App':
      return Icons.phone_iphone_rounded;
    case 'Web Dashboard':
      return Icons.dashboard_outlined;
    case 'Backend API':
      return Icons.storage_rounded;
    case 'Documentation':
      return Icons.description_outlined;
    default:
      return Icons.task_alt_rounded;
  }
}

// One task in a list: project icon, title, project and assignee name, the
// assignee's avatar and a trailing widget such as a due label or SLA chip.
// Tapping it opens the task detail screen unless onTap is given.
class TaskSummaryRow extends StatelessWidget {
  const TaskSummaryRow({
    super.key,
    required this.task,
    this.trailing,
    this.onTap,
  });

  final Task task;
  final Widget? trailing;
  final VoidCallback? onTap;

  void _openTask(BuildContext context) {
    debugPrint('[TaskSummaryRow] opening task ${task.id}');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: task.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignee = context.select<AppState, String?>(
      (state) => state.memberById(task.assigneeId)?.name,
    );
    final member = context.read<AppState>().memberById(task.assigneeId);
    final subtitle = [
      if (task.project.isNotEmpty) task.project,
      ?assignee,
    ].join(' - ');

    return InkWell(
      key: ValueKey('task-row-${task.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap ?? () => _openTask(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                projectIcon(task.project),
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (member != null) ...[
              const SizedBox(width: 8),
              MemberAvatar(member: member, radius: 14),
            ],
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        ),
      ),
    );
  }
}
