import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/member.dart';

// Round avatar showing a member's initials.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 23});

  final Member member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.midnight,
      child: Text(
        member.initials,
        style: TextStyle(
          color: AppColors.lime,
          fontWeight: FontWeight.bold,
          // Keeps the initials in proportion when the avatar is larger.
          fontSize: radius * 0.7,
        ),
      ),
    );
  }
}
