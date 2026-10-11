import 'package:flutter/material.dart';
import '../core/sla/sla_status.dart';
import '../core/theme/app_colors.dart';
import '../models/member.dart';

// Small rounded label with a coloured dot, used for presence and SLA status.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          // The dot carries the status colour; the text stays dark so it
          // remains readable on the light backgrounds.
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

extension MemberPresenceStyle on MemberPresence {
  String get label {
    switch (this) {
      case MemberPresence.online:
        return 'Online';
      case MemberPresence.away:
        return 'Away';
      case MemberPresence.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case MemberPresence.online:
        return AppColors.onTrack;
      case MemberPresence.away:
        return AppColors.atRisk;
      case MemberPresence.offline:
        return AppColors.completed;
    }
  }

  Color get softColor {
    switch (this) {
      case MemberPresence.online:
        return AppColors.softGreen;
      case MemberPresence.away:
        return AppColors.softYellow;
      case MemberPresence.offline:
        return AppColors.background;
    }
  }
}

class PresenceChip extends StatelessWidget {
  const PresenceChip({super.key, required this.presence});

  final MemberPresence presence;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: presence.label,
      color: presence.color,
      background: presence.softColor,
    );
  }
}

class SlaChip extends StatelessWidget {
  const SlaChip({super.key, required this.status});

  final SlaStatus status;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: status.label,
      color: status.color,
      background: status.softColor,
    );
  }
}
