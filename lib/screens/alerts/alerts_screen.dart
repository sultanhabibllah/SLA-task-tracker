import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/count_tile.dart';
import '../../widgets/sprintly_header.dart';
import 'alert_section.dart';

// Everything that needs attention: overdue tasks, tasks at risk, and the
// on-track deadlines coming up in the next week. Built from the live task
// list, so it updates as soon as a task changes.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<AppState>().tasks;
    final groups = groupAlerts(tasks);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SprintlyHeader(
              title: 'Alerts & Attention',
              subtitle: 'Stay on top of important updates and upcoming '
                  'deadlines.',
              onBack: canPop ? () => Navigator.of(context).pop() : null,
            ),
            const SizedBox(height: 20),
            _summary(groups),
            const SizedBox(height: 20),
            AlertSection(
              key: const ValueKey('alerts-overdue'),
              title: 'Overdue Tasks',
              icon: Icons.error_outline,
              color: AppColors.overdue,
              background: AppColors.softRed,
              tasks: groups.overdue,
              trailingFor: (task) => _dueText(task, AppColors.overdue),
              emptyMessage: 'Nothing is overdue. Nice work.',
            ),
            const SizedBox(height: 16),
            AlertSection(
              key: const ValueKey('alerts-at-risk'),
              title: 'At Risk Tasks',
              icon: Icons.warning_amber_rounded,
              color: AppColors.atRisk,
              background: AppColors.softYellow,
              tasks: groups.atRisk,
              trailingFor: (task) => _dueText(task, AppColors.atRisk),
              emptyMessage: 'No task is close to its deadline.',
            ),
            const SizedBox(height: 16),
            AlertSection(
              key: const ValueKey('alerts-upcoming'),
              title: 'Upcoming Deadlines',
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF3B6FD8),
              background: AppColors.softBlue,
              tasks: groups.upcoming,
              trailingFor: _dateText,
              emptyMessage: 'No other deadlines in the next 7 days.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(AlertGroups groups) {
    return Row(
      children: [
        Expanded(
          child: CountTile(
            key: const ValueKey('alert-tile-overdue'),
            icon: Icons.error_outline,
            color: AppColors.overdue,
            background: AppColors.softRed,
            count: groups.overdue.length,
            label: 'Overdue',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CountTile(
            key: const ValueKey('alert-tile-at-risk'),
            icon: Icons.warning_amber_rounded,
            color: AppColors.atRisk,
            background: AppColors.softYellow,
            count: groups.atRisk.length,
            label: 'At Risk',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CountTile(
            key: const ValueKey('alert-tile-upcoming'),
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF3B6FD8),
            background: AppColors.softBlue,
            count: groups.upcoming.length,
            label: 'Upcoming',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CountTile(
            key: const ValueKey('alert-tile-on-track'),
            icon: Icons.check_circle_outline,
            color: AppColors.onTrack,
            background: AppColors.softGreen,
            count: groups.onTrackCount,
            label: 'On Track',
          ),
        ),
      ],
    );
  }

  Widget _dueText(Task task, Color color) {
    return Text(
      dueLabel(task),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  // Date on top and days left underneath, as in the design.
  Widget _dateText(Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat('d MMM yyyy').format(task.dueDate),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          dueLabel(task),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
