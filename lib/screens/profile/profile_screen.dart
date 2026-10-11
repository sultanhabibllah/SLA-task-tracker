import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../state/app_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';
import 'edit_field_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Opens the edit dialog for one field and saves the result.
  // buildUpdated turns the new text into the updated member.
  Future<void> _editField(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String? Function(String value) validator,
    required Member Function(String value) buildUpdated,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.words,
  }) async {
    final appState = context.read<AppState>();

    final value = await showDialog<String>(
      context: context,
      builder: (_) => EditFieldDialog(
        title: title,
        initialValue: initialValue,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
      ),
    );

    if (value == null) return;
    await appState.updateMember(buildUpdated(value));
  }

  String? _validateEmail(AppState appState, Member member, String value) {
    if (value.isEmpty) return 'Please enter an email';

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    // Another member cannot already use this email.
    final taken = appState.members.any(
      (other) =>
          other.id != member.id &&
          other.email.toLowerCase() == value.toLowerCase(),
    );

    if (taken) return 'A member with this email already exists';
    return null;
  }

  Future<void> _changePresence(BuildContext context, Member member) async {
    final appState = context.read<AppState>();

    final presence = await showDialog<MemberPresence>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: const Text('Set your status'),
          children: [
            for (final option in MemberPresence.values)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, option),
                child: Row(
                  children: [
                    PresenceChip(presence: option),
                    const Spacer(),
                    if (option == member.presence)
                      const Icon(Icons.check, color: AppColors.textPrimary),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (presence == null) return;
    await appState.updateMember(member.copyWith(presence: presence));
  }

  void _showSlaRules(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('How SLA status works'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _slaRule(SlaStatus.completed, 'The task is marked as Done.'),
              _slaRule(
                SlaStatus.overdue,
                'The due date has passed and the task is not done.',
              ),
              _slaRule(
                SlaStatus.atRisk,
                'Due within ${atRiskWindow.inHours} hours, or '
                '${highPriorityAtRiskWindow.inHours} hours for High priority tasks.',
              ),
              _slaRule(SlaStatus.onTrack, 'Every other open task.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  Widget _slaRule(SlaStatus status, String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlaChip(status: status),
          const SizedBox(height: 6),
          Text(
            rule,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final appState = context.read<AppState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will need to choose a profile again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.overdue,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // The auth gate in main.dart swaps back to the sign-in screen.
    await appState.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final member = appState.currentUser;

    // Nobody is signed in for the instant between sign out and the
    // sign-in screen appearing.
    if (member == null) return const SizedBox.shrink();

    final myTasks = appState.tasksFor(member.id);
    final slaCounts = appState.slaCounts(subset: myTasks);
    final memberSince = DateFormat('MMM yyyy').format(member.joinedAt);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const SprintlyHeader(
          title: 'Profile',
          subtitle: 'View and manage your account settings.',
        ),

        const SizedBox(height: 20),

        // Header card
        _card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MemberAvatar(member: member, radius: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member.role == MemberRole.admin
                            ? '${member.jobTitle} · Admin'
                            : member.jobTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PresenceChip(presence: member.presence),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Member since $memberSince',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Editable details
        _card(
          child: Column(
            children: [
              _row(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: member.name,
                onTap: () => _editField(
                  context,
                  title: 'Full name',
                  initialValue: member.name,
                  validator: (value) {
                    if (value.isEmpty) return 'Please enter a name';
                    if (value.length < 2) {
                      return 'Name must contain at least 2 characters';
                    }
                    return null;
                  },
                  buildUpdated: (value) => member.copyWith(name: value),
                ),
              ),
              _divider,
              _row(
                icon: Icons.mail_outline,
                label: 'Work Email',
                value: member.email,
                onTap: () => _editField(
                  context,
                  title: 'Work email',
                  initialValue: member.email,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  validator: (value) => _validateEmail(appState, member, value),
                  buildUpdated: (value) =>
                      member.copyWith(email: value.toLowerCase()),
                ),
              ),
              _divider,
              _row(
                icon: Icons.work_outline,
                label: 'Role',
                value: member.jobTitle,
                onTap: () => _editField(
                  context,
                  title: 'Role',
                  initialValue: member.jobTitle,
                  validator: (value) =>
                      value.isEmpty ? 'Please enter a role' : null,
                  buildUpdated: (value) => member.copyWith(jobTitle: value),
                ),
              ),
              _divider,
              _row(
                icon: Icons.groups_outlined,
                label: 'Team',
                value: member.team,
                onTap: () => _editField(
                  context,
                  title: 'Team',
                  initialValue: member.team,
                  validator: (value) =>
                      value.isEmpty ? 'Please enter a team' : null,
                  buildUpdated: (value) => member.copyWith(team: value),
                ),
              ),
              _divider,
              _row(
                icon: Icons.circle_outlined,
                label: 'Status',
                value: member.presence.label,
                onTap: () => _changePresence(context, member),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Workload
        _card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My workload',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  myTasks.isEmpty
                      ? 'No tasks are assigned to you.'
                      : '${slaCounts[SlaStatus.completed]} of '
                            '${myTasks.length} assigned tasks completed',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final status in SlaStatus.values)
                      Expanded(
                        child: _slaCount(status, slaCounts[status]!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        _card(
          child: _row(
            icon: Icons.help_outline,
            label: 'How SLA status works',
            onTap: () => _showSlaRules(context),
          ),
        ),

        const SizedBox(height: 16),

        _card(
          color: AppColors.softRed,
          child: _row(
            icon: Icons.logout,
            label: 'Sign Out',
            color: AppColors.overdue,
            onTap: () => _signOut(context),
          ),
        ),
      ],
    );
  }

  static const _divider = Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: AppColors.border,
  );

  // Material (rather than a Container) so the rows show a ripple when tapped.
  Widget _card({required Widget child, Color color = AppColors.white}) {
    return Material(
      color: color,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: child,
    );
  }

  // One tappable line: icon, label, an optional value, and a chevron.
  Widget _row({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? value,
    Color color = AppColors.textPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            if (value == null)
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              )
            else ...[
              SizedBox(
                width: 92,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 22, color: color),
          ],
        ),
      ),
    );
  }

  Widget _slaCount(SlaStatus status, int count) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: status.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              key: ValueKey('sla-count-${status.name}'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          status.label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
