import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../theme/app_colors.dart';

enum SlaStatus { onTrack, atRisk, overdue, completed }

// How close to the deadline a task has to be before it counts as at risk.
// High priority tasks get flagged a day earlier.
const atRiskWindow = Duration(hours: 48);
const highPriorityAtRiskWindow = Duration(hours: 72);

// SLA rules, checked in this order:
// 1. Completed - the task status is Done, whatever the deadline.
// 2. Overdue   - not done and the deadline has passed.
// 3. At Risk   - not done and the deadline is inside the at-risk window.
// 4. On Track  - everything else.
SlaStatus classifySla(Task task, {DateTime? now}) {
  if (task.isDone) return SlaStatus.completed;

  final current = now ?? DateTime.now();
  final timeLeft = task.deadline.difference(current);

  if (timeLeft.isNegative) return SlaStatus.overdue;

  final window = task.priority == TaskPriority.high
      ? highPriorityAtRiskWindow
      : atRiskWindow;

  if (timeLeft <= window) return SlaStatus.atRisk;

  return SlaStatus.onTrack;
}

extension SlaStatusStyle on SlaStatus {
  String get label {
    switch (this) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case SlaStatus.onTrack:
        return AppColors.onTrack;
      case SlaStatus.atRisk:
        return AppColors.atRisk;
      case SlaStatus.overdue:
        return AppColors.overdue;
      case SlaStatus.completed:
        return AppColors.completed;
    }
  }

  Color get softColor {
    switch (this) {
      case SlaStatus.onTrack:
        return AppColors.softGreen;
      case SlaStatus.atRisk:
        return AppColors.softYellow;
      case SlaStatus.overdue:
        return AppColors.softRed;
      case SlaStatus.completed:
        return AppColors.background;
    }
  }
}
