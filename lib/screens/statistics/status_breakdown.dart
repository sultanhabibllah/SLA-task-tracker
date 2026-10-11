import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/sla/sla_status.dart';
import '../../core/sla/task_insights.dart';
import '../../core/theme/app_colors.dart';

// Task Status card body: a donut with the total in the middle, and a legend
// row per SLA status with its count and share of all tasks.
class StatusBreakdown extends StatelessWidget {
  const StatusBreakdown({super.key, required this.counts});

  final Map<SlaStatus, int> counts;

  int get _total => counts.values.fold(0, (sum, n) => sum + n);

  @override
  Widget build(BuildContext context) {
    final total = _total;

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DonutPainter(counts: counts, total: total),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    key: const ValueKey('stats-donut-total'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (final status in SlaStatus.values)
                _legendRow(status, counts[status] ?? 0, total),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendRow(SlaStatus status, int count, int total) {
    return Padding(
      key: ValueKey('stats-legend-${status.name}'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status.label,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              '${percentOf(count, total)}%',
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// Draws one arc per SLA status, sized by its share of the total. With no
// tasks a plain grey ring is drawn instead.
class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.counts, required this.total});

  final Map<SlaStatus, int> counts;
  final int total;

  static const _stroke = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = AppColors.border);
      return;
    }

    var start = -math.pi / 2;
    for (final status in SlaStatus.values) {
      final count = counts[status] ?? 0;
      if (count == 0) continue;
      final sweep = math.pi * 2 * count / total;
      canvas.drawArc(rect, start, sweep, false, paint..color = status.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) {
    return old.total != total || old.counts.toString() != counts.toString();
  }
}
