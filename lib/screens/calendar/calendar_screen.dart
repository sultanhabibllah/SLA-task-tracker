import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';
import '../../state/app_state.dart';
import '../../widgets/sprintly_header.dart';
import 'day_agenda.dart';
import 'month_grid.dart';

// Calendar tab: a month view with a dot per SLA status on each day that has
// tasks due, and the selected day's tasks listed underneath. Opens on the
// current month with today selected.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.today});

  // Lets tests fix "today". Defaults to the real date.
  final DateTime? today;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _today;
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _today = dayOnly(widget.today ?? DateTime.now());
    _month = DateTime(_today.year, _today.month);
    _selected = _today;
  }

  void _changeMonth(int offset) {
    setState(() => _month = DateTime(_month.year, _month.month + offset));
    debugPrint('[Calendar] showing ${DateFormat('MMMM yyyy').format(_month)}');
  }

  void _goToToday() {
    setState(() {
      _month = DateTime(_today.year, _today.month);
      _selected = _today;
    });
    debugPrint('[Calendar] jumped to today');
  }

  // Picking a day from a neighbouring month also moves to that month.
  void _select(DateTime day) {
    setState(() {
      _selected = day;
      _month = DateTime(day.year, day.month);
    });
    debugPrint('[Calendar] selected ${DateFormat('yyyy-MM-dd').format(day)}');
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<AppState>().tasks;
    final byDay = tasksByDay(tasks);
    final dayTasks = sortedByDueDate(byDay[_selected] ?? const []);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const SprintlyHeader(
          title: 'Calendar',
          subtitle: "View your team's schedule and upcoming deadlines.",
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _monthBar(),
              const SizedBox(height: 8),
              MonthGrid(
                month: _month,
                selected: _selected,
                today: _today,
                tasksByDay: byDay,
                onSelect: _select,
              ),
              const Divider(height: 24, color: AppColors.border),
              const SlaLegend(),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DayAgenda(day: _selected, tasks: dayTasks),
      ],
    );
  }

  Widget _monthBar() {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('calendar-previous'),
          tooltip: 'Previous month',
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_month),
            key: const ValueKey('calendar-month'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('calendar-next'),
          tooltip: 'Next month',
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        TextButton(
          key: const ValueKey('calendar-today'),
          onPressed: _goToToday,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
          ),
          child: const Text('Today'),
        ),
      ],
    );
  }
}
