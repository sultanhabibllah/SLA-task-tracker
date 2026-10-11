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
import 'edit_task_screen.dart';

// read-only view of 1 task with quick actions: change its status, mark it
// complete or open the edit form. It reads the task by id so it refreshes
// after an edit, and closes itself if the task is deleted
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final task = appState.taskById(taskId);

    if (task == null) {
      // the task was deleted from the edit form; leave this screen too
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final assignee = appState.memberById(task.assigneeId);
    final sla = appState.slaOf(task);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _topBar(context),
                  const SizedBox(height: 16),
                  _TitleBlock(task: task, sla: sla),
                  const SizedBox(height: 20),
                  _InfoCard(task: task, assignee: assignee),
                  const SizedBox(height: 16),
                  _SlaCard(task: task, sla: sla),
                  const SizedBox(height: 24),
                  _OverviewCard(task: task),
                  const SizedBox(height: 24),
                  _AttachmentsSection(attachments: task.attachments),
                ],
              ),
            ),
            _ActionBar(task: task),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          color: AppColors.textPrimary,
        ),
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(fit: BoxFit.scaleDown, child: SprintlyLogo()),
          ),
        ),
        IconButton(
          onPressed: () => _openEdit(context),
          tooltip: 'Edit task',
          icon: const Icon(Icons.more_vert),
          color: AppColors.textPrimary,
        ),
      ],
    );
  }

  void _openEdit(BuildContext context) {
    final task = context.read<AppState>().taskById(taskId);
    if (task == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => EditTaskScreen(task: task)));
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.task, required this.sla});

  final Task task;
  final SlaStatus sla;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (task.project.isNotEmpty) task.project,
      if (task.tags.isNotEmpty) task.tags.first,
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
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
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            task.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// assignee, due date, priority and a status dropdown in 1 bordered card
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.task, required this.assignee});

  final Task task;
  final Member? assignee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _assigneeCell()),
              Container(width: 1, height: 44, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(
                child: _labelledCell(
                  icon: Icons.event_outlined,
                  label: 'Due Date',
                  value: DateFormat('d MMM yyyy').format(task.dueDate),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          Row(
            children: [
              Expanded(child: _priorityCell()),
              Container(width: 1, height: 44, color: AppColors.border),
              const SizedBox(width: 16),
              Expanded(child: _StatusDropdown(task: task)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assigneeCell() {
    return Row(
      children: [
        if (assignee != null)
          MemberAvatar(member: assignee!, radius: 22)
        else
          const CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.background,
            child: Icon(Icons.person_outline, color: AppColors.textSecondary),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: _cellText('Assigned to', assignee?.name ?? 'Unassigned'),
        ),
      ],
    );
  }

  Widget _priorityCell() {
    final color = switch (task.priority) {
      TaskPriority.high => AppColors.overdue,
      TaskPriority.medium => AppColors.atRisk,
      TaskPriority.low => AppColors.onTrack,
    };

    return Row(
      children: [
        Icon(Icons.flag_rounded, size: 30, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: _cellText('Priority', task.priority.label, valueColor: color),
        ),
      ],
    );
  }

  Widget _labelledCell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 26, color: AppColors.textPrimary),
        const SizedBox(width: 12),
        Expanded(child: _cellText(label, value)),
      ],
    );
  }
}

Widget _cellText(String label, String value, {Color? valueColor}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: valueColor ?? AppColors.textPrimary,
        ),
      ),
    ],
  );
}

// changing the status here saves straight away through AppState
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.format_list_bulleted,
          size: 26,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TaskStatus>(
                    key: const ValueKey('task-status-dropdown'),
                    value: task.status,
                    isExpanded: true,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    items: [
                      for (final status in TaskStatus.values)
                        DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                    ],
                    onChanged: (status) {
                      if (status == null || status == task.status) return;
                      context.read<AppState>().updateTask(
                        task.copyWith(status: status),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// shows the SLA status in words and how many days are left to the deadline
class _SlaCard extends StatelessWidget {
  const _SlaCard({required this.task, required this.sla});

  final Task task;
  final SlaStatus sla;

  String get _explanation {
    switch (sla) {
      case SlaStatus.onTrack:
        return 'The task is progressing as expected.';
      case SlaStatus.atRisk:
        return 'The deadline is close. Needs attention.';
      case SlaStatus.overdue:
        return 'The deadline has passed.';
      case SlaStatus.completed:
        return 'This task has been completed.';
    }
  }

  // whole calendar days between today and the due day.
  int get _daysLeft {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      task.dueDate.year,
      task.dueDate.month,
      task.dueDate.day,
    );
    return due.difference(today).inDays;
  }

  String get _countdown {
    if (sla == SlaStatus.completed) return 'Done';
    final days = _daysLeft;
    if (days < 0) {
      return '${-days} ${-days == 1 ? 'day' : 'days'} late';
    }
    if (days == 0) return 'Due today';
    return '$days ${days == 1 ? 'day' : 'days'} left';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sla.softColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sla.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SLA Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 22,
                      color: sla.color,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sla.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        key: const ValueKey('task-sla-label'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: sla.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _explanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: sla.color.withValues(alpha: 0.25),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _countdown,
                        key: const ValueKey('task-countdown'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
        ],
      ),
    );
  }
}

// description and the task's tags as key notes
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                task.description.isEmpty
                    ? 'No description yet.'
                    : task.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              if (task.tags.isNotEmpty) ...[
                const Divider(height: 28, color: AppColors.border),
                const Text(
                  'Key notes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                for (final tag in task.tags)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.onTrack,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.attachments});

  final List<TaskAttachment> attachments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attachments (${attachments.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (attachments.isEmpty)
          const Text(
            'No files attached.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          )
        else
          for (final attachment in attachments)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration,
              child: Row(
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 28,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (attachment.size.isNotEmpty)
                          Text(
                            attachment.size,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

// fixed bar at the bottom with the 2 main actions
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const ValueKey('edit-task-button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditTaskScreen(task: task),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Edit Task'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              key: const ValueKey('mark-complete-button'),
              // Nothing left to do once the task is already done.
              onPressed: task.isDone
                  ? null
                  : () {
                      context.read<AppState>().updateTask(
                        task.copyWith(status: TaskStatus.done),
                      );
                    },
              icon: const Icon(Icons.check, size: 20),
              label: Text(task.isDone ? 'Completed' : 'Mark as Complete'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.midnight,
                foregroundColor: AppColors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.border),
);
