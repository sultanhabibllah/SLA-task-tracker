import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../widgets/task_summary_row.dart';

// One coloured section of the Alerts screen: a header with the count and a
// View all toggle, then the tasks in a white card. Only the first few tasks
// are shown until View all is tapped.
class AlertSection extends StatefulWidget {
  const AlertSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.background,
    required this.tasks,
    required this.trailingFor,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color background;
  final List<Task> tasks;
  // Builds the widget on the right of each task row, such as a due label.
  final Widget Function(Task task) trailingFor;
  final String emptyMessage;

  // How many tasks show before the section is expanded.
  static const collapsedCount = 2;

  @override
  State<AlertSection> createState() => _AlertSectionState();
}

class _AlertSectionState extends State<AlertSection> {
  bool _expanded = false;

  void _toggle() {
    setState(() => _expanded = !_expanded);
    debugPrint(
      '[Alerts] ${widget.title} ${_expanded ? 'expanded' : 'collapsed'}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.tasks;
    final canExpand = tasks.length > AlertSection.collapsedCount;
    final visible = _expanded || !canExpand
        ? tasks
        : tasks.take(AlertSection.collapsedCount).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(canExpand, tasks.length),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: tasks.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      widget.emptyMessage,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Column(
                    children: [
                      for (final task in visible)
                        TaskSummaryRow(
                          task: task,
                          trailing: widget.trailingFor(task),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool canExpand, int count) {
    return Container(
      color: widget.background,
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          Icon(widget.icon, color: widget.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${widget.title} ($count)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (canExpand)
            TextButton(
              onPressed: _toggle,
              style: TextButton.styleFrom(foregroundColor: widget.color),
              child: Text(_expanded ? 'Show less' : 'View all'),
            )
          else
            const SizedBox(height: 40),
        ],
      ),
    );
  }
}
