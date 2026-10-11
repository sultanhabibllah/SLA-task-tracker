import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

// Sprintly logo mark and name, as used at the top of every screen.
class SprintlyLogo extends StatelessWidget {
  const SprintlyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.midnight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.layers_rounded,
            color: AppColors.lime,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Sprintly',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.midnight,
          ),
        ),
      ],
    );
  }
}

// Top section of a screen: logo row, then the screen title and subtitle.
// Pass onBack for screens opened with Navigator.push, and actions for
// buttons on the right of the logo row.
class SprintlyHeader extends StatelessWidget {
  const SprintlyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: AppColors.textPrimary,
              ),
            // The logo shrinks instead of overflowing on narrow screens.
            const Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SprintlyLogo(),
                ),
              ),
            ),
            ...actions,
          ],
        ),

        const SizedBox(height: 24),

        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
