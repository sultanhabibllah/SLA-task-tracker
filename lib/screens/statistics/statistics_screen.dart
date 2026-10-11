import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/sla_status.dart';
import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/count_tile.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/task_summary_row.dart';
import 'project_progress_list.dart';
import 'status_breakdown.dart';

// Task Statistics: totals per SLA status, a status donut, progress per
// project and the next deadlines, for this month or for all time.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  // How many deadlines are listed at the bottom.
  static const upcomingCount = 3;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsRange _range = StatsRange.thisMonth;

  void _setRange(StatsRange range) {
    setState(() => _range = range);
    debugPrint('[Statistics] range set to ${range.label}');
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final tasks = tasksInRange(appState.tasks, _range);
    final counts = appState.slaCounts(subset: tasks);
    final upcoming = sortedByDueDate(tasks.where((t) => !t.isDone))
        .take(StatisticsScreen.upcomingCount)
        .toList();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SprintlyHeader(
              title: 'Task Statistics',
              subtitle: 'Track your progress and get insights on your tasks '
                  'and team performance.',
              onBack: canPop ? () => Navigator.of(context).pop() : null,
            ),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: _rangeMenu()),
            const SizedBox(height: 12),
            _tiles(tasks.length, counts),
            const SizedBox(height: 16),
            _card('Task Status', StatusBreakdown(counts: counts)),
            const SizedBox(height: 16),
            _card(
              'Tasks by Project',
              ProjectProgressList(projects: projectProgress(tasks)),
            ),
            const SizedBox(height: 16),
            _card('Upcoming Deadlines', _upcomingList(appState, upcoming)),
          ],
        ),
      ),
    );
  }

  Widget _rangeMenu() {
    return PopupMenuButton<StatsRange>(
      key: const ValueKey('stats-range'),
      tooltip: 'Choose period',
      initialValue: _range,
      onSelected: _setRange,
      itemBuilder: (_) => [
        for (final range in StatsRange.values)
          PopupMenuItem(value: range, child: Text(range.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16),
            const SizedBox(width: 6),
            Text(_range.label),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _tiles(int total, Map<SlaStatus, int> counts) {
    Widget tile(String key, IconData icon, Color color, Color bg, int n, String label) {
      return Expanded(
        child: CountTile(
          key: ValueKey(key),
          icon: icon,
          color: color,
          background: bg,
          count: n,
          label: label,
        ),
      );
    }

    return Row(
      children: [
        tile('stats-tile-total', Icons.check_circle, const Color(0xFF3B6FD8),
            AppColors.softBlue, total, 'Total Tasks'),
        const SizedBox(width: 8),
        tile('stats-tile-on-track', Icons.radio_button_checked, AppColors.onTrack,
            AppColors.softGreen, counts[SlaStatus.onTrack]!, 'On Track'),
        const SizedBox(width: 8),
        tile('stats-tile-at-risk', Icons.warning_amber_rounded, AppColors.atRisk,
            AppColors.softYellow, counts[SlaStatus.atRisk]!, 'At Risk'),
        const SizedBox(width: 8),
        tile('stats-tile-overdue', Icons.error_outline, AppColors.overdue,
            AppColors.softRed, counts[SlaStatus.overdue]!, 'Overdue'),
      ],
    );
  }

  Widget _card(String title, Widget body) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _upcomingList(AppState appState, List<Task> upcoming) {
    if (upcoming.isEmpty) {
      return const Text(
        'No open tasks in this period.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Column(
      children: [
        for (final task in upcoming)
          TaskSummaryRow(
            task: task,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(task.dueDate),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                SlaChip(status: appState.slaOf(task)),
              ],
            ),
          ),
      ],
    );
  }
}
