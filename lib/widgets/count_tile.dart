import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// Small coloured tile with an icon, a big number and a label, used for the
// summary rows at the top of the Alerts and Statistics screens.
class CountTile extends StatelessWidget {
  const CountTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          // Labels shrink rather than wrap when four tiles share a row.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
