import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';
import '../alerts/alerts_screen.dart';
import '../statistics/statistics_screen.dart';
import '../tasks/task_detail_screen.dart';

// which tasks the SLA Health card looks at
enum _HealthRange { thisWeek, allTime }

// home tab: a summary of the whole team's tasks by SLA status, how healthy
// the deadlines are, and the next deadlines coming up
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _HealthRange _range = _HealthRange.thisWeek;

  // how many deadlines are listed under Upcoming Deadlines
  static const _upcomingCount = 3;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // pushes a full screen such as Alerts or Statistics on top of the shell
  void _open(BuildContext context, Widget screen) {
    debugPrint('[Dashboard] opening ${screen.runtimeType}');
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // "This Week" covers tasks due within the next 7 days, plus anything that
  // is already past its due date
  List<Task> _tasksInRange(List<Task> tasks) {
    if (_range == _HealthRange.allTime) return tasks;
    final now = DateTime.now();
    final limit = DateTime(now.year, now.month, now.day + 8);
    return tasks.where((task) => task.dueDate.isBefore(limit)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final counts = appState.slaCounts();
    final needsAttention =
        counts[SlaStatus.atRisk]! + counts[SlaStatus.overdue]!;

    final upcoming = appState.tasks.where((task) => !task.isDone).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _topBar(context, needsAttention),
        const SizedBox(height: 20),
        _greetingBlock(user?.name.split(' ').first),
        const SizedBox(height: 20),
        _summaryTiles(appState.tasks.length, counts),
        const SizedBox(height: 16),
        _healthCard(appState),
        const SizedBox(height: 16),
        _upcomingCard(
          context,
          appState,
          upcoming.take(_upcomingCount).toList(),
        ),
      ],
    );
  }

  Widget _topBar(BuildContext context, int needsAttention) {
    final user = context.watch<AppState>().currentUser;

    return Row(
      children: [
        const Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(fit: BoxFit.scaleDown, child: SprintlyLogo()),
          ),
        ),
        IconButton(
          key: const ValueKey('dashboard-stats'),
          tooltip: 'Task statistics',
          onPressed: () => _open(context, const StatisticsScreen()),
          icon: const Icon(Icons.insert_chart_outlined_rounded, size: 26),
          color: AppColors.textPrimary,
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              key: const ValueKey('dashboard-bell'),
              tooltip: 'Alerts',
              // opens the Alerts screen with everything at risk or overdue
              onPressed: () => _open(context, const AlertsScreen()),
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              color: AppColors.textPrimary,
            ),
            // green dot only while something is at risk or overdue
            if (needsAttention > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.onTrack,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        if (user != null) ...[
          const SizedBox(width: 6),
          MemberAvatar(member: user, radius: 22),
        ],
      ],
    );
  }

  Widget _greetingBlock(String? firstName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          firstName == null ? _greeting() : '${_greeting()}, $firstName 👋',
          key: const ValueKey('dashboard-greeting'),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Here’s what’s happening with your projects today.',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _summaryTiles(int total, Map<SlaStatus, int> counts) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                key: const ValueKey('tile-total'),
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF3B6FD8),
                background: AppColors.softBlue,
                label: 'Total Tasks',
                value: total,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                key: const ValueKey('tile-on-track'),
                icon: Icons.check_circle,
                iconColor: AppColors.onTrack,
                background: AppColors.softGreen,
                label: 'On Track',
                value: counts[SlaStatus.onTrack]!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                key: const ValueKey('tile-at-risk'),
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.atRisk,
                background: AppColors.softYellow,
                label: 'At Risk',
                value: counts[SlaStatus.atRisk]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                key: const ValueKey('tile-overdue'),
                icon: Icons.error,
                iconColor: AppColors.overdue,
                background: AppColors.softRed,
                label: 'Overdue',
                value: counts[SlaStatus.overdue]!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SLA Health
  Widget _healthCard(AppState appState) {
    final tasks = _tasksInRange(appState.tasks);
    final counts = appState.slaCounts(subset: tasks);
    final healthy = counts[SlaStatus.onTrack]! + counts[SlaStatus.completed]!;
    final share = tasks.isEmpty ? 0.0 : healthy / tasks.length;
    final percent = (share * 100).round();
    final late = counts[SlaStatus.atRisk]! + counts[SlaStatus.overdue]!;

    final String message;
    if (tasks.isEmpty) {
      message = 'No tasks in this period yet.';
    } else if (late == 0) {
      message = 'Every task is on track. Great work!';
    } else {
      message =
          '$late of ${tasks.length} '
          '${tasks.length == 1 ? 'task is' : 'tasks are'} at risk or overdue.';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SLA Health',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _rangePicker(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HealthDonut(key: const ValueKey('health-donut'), share: share),
              const SizedBox(width: 18),
              Container(width: 1, height: 100, color: AppColors.border),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$percent% on track',
                      key: const ValueKey('health-percent'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onTrack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_HealthRange>(
          key: const ValueKey('health-range'),
          value: _range,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(
              value: _HealthRange.thisWeek,
              child: Text('This Week'),
            ),
            DropdownMenuItem(
              value: _HealthRange.allTime,
              child: Text('All Time'),
            ),
          ],
          onChanged: (range) {
            if (range == null) return;
            setState(() {
              _range = range;
            });
          },
        ),
      ),
    );
  }

  Widget _upcomingCard(
    BuildContext context,
    AppState appState,
    List<Task> tasks,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Deadlines',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No open tasks. Nothing is due.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            )
          else
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _DeadlineRow(
                task: tasks[i],
                sla: appState.slaOf(tasks[i]),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskDetailScreen(taskId: tasks[i].id),
                    ),
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
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

// Ring showing [share] (0.0 to 1.0) in green over a grey track, with the
// percentage in the middle.
class _HealthDonut extends StatelessWidget {
  const _HealthDonut({super.key, required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(110, 110),
            painter: _DonutPainter(share),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(share * 100).round()}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'On Track',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.share);

  final double share;

  static const _strokeWidth = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, 2 * math.pi, false, track);

    if (share <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.onTrack;
    // Starts at 12 o'clock and runs clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * share, false, arc);
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.share != share;
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({
    required this.task,
    required this.sla,
    required this.onTap,
  });

  final Task task;
  final SlaStatus sla;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (task.project.isNotEmpty) task.project,
      if (task.tags.isNotEmpty) task.tags.first,
    ].join(' • ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
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
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('d MMM yyyy').format(task.dueDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(
                  label: sla.label,
                  color: sla.color,
                  background: sla.softColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: AppColors.border),
);
