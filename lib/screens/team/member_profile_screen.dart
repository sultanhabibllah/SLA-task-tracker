import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';
import '../tasks/task_detail_screen.dart';
import 'member_tasks_sheet.dart';

// a teammate's profile as seen by other members: who they are, their
// workload by SLA status and their open tasks. Alao reads the member by id so it
// stays current if their details change
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.memberId});

  final String memberId;

  // how many open tasks are listed before "View All"
  static const _previewCount = 3;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final member = appState.memberById(memberId);

    if (member == null) {
      // the member was removed while this screen was open
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final tasks = appState.tasksFor(member.id);
    final counts = appState.slaCounts(subset: tasks);
    final openTasks = tasks.where((task) => !task.isDone).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SprintlyHeader(
              title: member.name,
              subtitle: member.jobTitle,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 8),
            Text(
              '${member.team} team'
              '${member.role == MemberRole.admin ? ' · Admin' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            _ProfileCard(member: member, activeTasks: openTasks.length),
            const SizedBox(height: 14),
            _statTiles(tasks.length, counts),
            const SizedBox(height: 14),
            _currentTasks(context, member, openTasks, appState),
            const SizedBox(height: 14),
            _EmailRow(email: member.email),
            const SizedBox(height: 20),
            _assignButton(context, member),
          ],
        ),
      ),
    );
  }

  Widget _statTiles(int assigned, Map<SlaStatus, int> counts) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            key: const ValueKey('profile-assigned'),
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF3B6FD8),
            background: AppColors.softBlue,
            label: 'Assigned',
            value: assigned,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            key: const ValueKey('profile-completed'),
            icon: Icons.verified_outlined,
            iconColor: AppColors.onTrack,
            background: AppColors.softGreen,
            label: 'Completed',
            value: counts[SlaStatus.completed]!,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            key: const ValueKey('profile-at-risk'),
            icon: Icons.error_outline,
            iconColor: AppColors.atRisk,
            background: AppColors.softYellow,
            label: 'At Risk',
            value: counts[SlaStatus.atRisk]!,
          ),
        ),
      ],
    );
  }

  Widget _currentTasks(
    BuildContext context,
    Member member,
    List<Task> openTasks,
    AppState appState,
  ) {
    final preview = openTasks.take(_previewCount).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: AppColors.white,
                    builder: (_) => MemberTasksSheet(member: member),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          if (preview.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No open tasks right now.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          else
            for (var i = 0; i < preview.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.border),
              _TaskRow(
                task: preview[i],
                sla: appState.slaOf(preview[i]),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailScreen(taskId: preview[i].id),
                    ),
                  );
                },
              ),
            ],
        ],
      ),
    );
  }

  Widget _assignButton(BuildContext context, Member member) {
    return FilledButton.icon(
      key: const ValueKey('assign-task-button'),
      onPressed: () {
        // The Create Task screen is built by another team member; until it
        // is merged, tell the user instead of doing nothing.
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: AppColors.midnight,
              content: Text(
                'Task creation for ${member.name} is coming soon.',
                style: const TextStyle(color: AppColors.white),
              ),
            ),
          );
      },
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Assign New Task'),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.midnight,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.member, required this.activeTasks});

  final Member member;
  final int activeTasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          MemberAvatar(member: member, radius: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.jobTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PresenceChip(presence: member.presence),
                    StatusChip(
                      label:
                          '$activeTasks active '
                          '${activeTasks == 1 ? 'task' : 'tasks'}',
                      color: AppColors.textSecondary,
                      background: AppColors.background,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.sla, required this.onTap});

  final Task task;
  final SlaStatus sla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              size: 22,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due ${DateFormat('d MMM yyyy').format(task.dueDate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: sla.label,
            color: sla.color,
            background: sla.softColor,
          ),
        ],
      ),
    );
  }
}

class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.mail_outline,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Work Email',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);
