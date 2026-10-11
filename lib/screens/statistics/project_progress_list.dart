import 'package:flutter/material.dart';

import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';

// Bar colours for the project rows, reused in order if there are more
// projects than colours.
const _barColors = [
  AppColors.onTrack,
  Color(0xFF3B6FD8),
  AppColors.atRisk,
  AppColors.completed,
];

// Tasks by Project card body: one row per project with a progress bar of
// done tasks, the done/total count and the percentage.
class ProjectProgressList extends StatelessWidget {
  const ProjectProgressList({super.key, required this.projects});

  final List<ProjectProgress> projects;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No tasks in this period yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < projects.length; i++)
          _row(projects[i], _barColors[i % _barColors.length]),
      ],
    );
  }

  Widget _row(ProjectProgress project, Color color) {
    return Padding(
      key: ValueKey('stats-project-${project.name}'),
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: project.share,
                minHeight: 8,
                color: color,
                backgroundColor: AppColors.background,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${project.done}/${project.total}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${percentOf(project.done, project.total)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
