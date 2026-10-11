import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/task_summary_row.dart';

// The tasks due on the selected day, each with a coloured bar for its SLA
// status, an SLA chip and a menu to mark it done or reopen it.
class DayAgenda extends StatelessWidget {
  const DayAgenda({super.key, required this.day, required this.tasks});

  final DateTime day;
  final List<Task> tasks;

  Future<void> _toggleDone(BuildContext context, Task task) async {
    final newStatus = task.isDone ? TaskStatus.todo : TaskStatus.done;
    debugPrint('[Calendar] task ${task.id} set to ${newStatus.name}');
    await context.read<AppState>().updateTask(
      task.copyWith(status: newStatus),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('EEE, d MMMM yyyy').format(day),
                key: const ValueKey('agenda-title'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No tasks due on this day.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          for (final task in tasks)
            _agendaRow(context, task, appState.slaOf(task)),
      ],
    );
  }

  Widget _agendaRow(BuildContext context, Task task, SlaStatus sla) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: sla.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TaskSummaryRow(task: task, trailing: SlaChip(status: sla)),
          ),
          PopupMenuButton<String>(
            key: ValueKey('agenda-menu-${task.id}'),
            tooltip: 'Task actions',
            onSelected: (_) => _toggleDone(context, task),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Text(task.isDone ? 'Reopen task' : 'Mark as done'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
