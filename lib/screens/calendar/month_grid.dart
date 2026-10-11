import 'package:flutter/material.dart';

import '../../core/sla/sla_status.dart';
import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';

// Weekday labels and the day cells for one month. Each day shows one dot per
// SLA status among the tasks due that day. Days of the neighbouring months
// are greyed out but can still be tapped.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.selected,
    required this.today,
    required this.tasksByDay,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final Map<DateTime, List<Task>> tasksByDay;
  final ValueChanged<DateTime> onSelect;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final days = monthGrid(month);

    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var week = 0; week < days.length; week += 7)
          Row(
            children: [
              for (final day in days.sublist(week, week + 7))
                Expanded(child: _dayCell(day)),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(DateTime day) {
    final inMonth = day.month == month.month;
    final isSelected = isSameDay(day, selected);
    final isToday = isSameDay(day, today);
    final statuses = statusesForDay(tasksByDay[day] ?? const []);

    final Color textColor;
    if (isSelected) {
      textColor = AppColors.white;
    } else if (inMonth) {
      textColor = AppColors.textPrimary;
    } else {
      textColor = AppColors.completed;
    }

    return InkWell(
      key: ValueKey(
        'day-${day.year}-${day.month}-${day.day}',
      ),
      customBorder: const CircleBorder(),
      onTap: () => onSelect(day),
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.midnight : null,
                shape: BoxShape.circle,
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.midnight)
                    : null,
              ),
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final status in statuses)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Colour key under the grid, one entry per SLA status.
class SlaLegend extends StatelessWidget {
  const SlaLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final status in SlaStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                status.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
