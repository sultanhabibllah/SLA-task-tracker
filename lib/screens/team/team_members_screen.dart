import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../state/app_state.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';
import 'add_member_sheet.dart';
import 'member_tasks_sheet.dart';

enum _MemberFilter { all, admins, members }

enum _MemberAction { viewTasks, changeRole, remove }

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  _MemberFilter _filter = _MemberFilter.all;

  final _searchController = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Applies the selected filter tab, then the search text.
  List<Member> _visibleMembers(List<Member> members) {
    final query = _query.trim().toLowerCase();

    return members.where((member) {
      if (_filter == _MemberFilter.admins && member.role != MemberRole.admin) {
        return false;
      }
      if (_filter == _MemberFilter.members &&
          member.role != MemberRole.member) {
        return false;
      }
      if (query.isEmpty) return true;

      return member.name.toLowerCase().contains(query) ||
          member.jobTitle.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: AppColors.midnight,
          content: Text(
            message,
            style: const TextStyle(color: AppColors.white),
          ),
        ),
      );
  }

  Future<void> _openAddMember() async {
    final added = await showModalBottomSheet<Member>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      builder: (_) => const AddMemberSheet(),
    );

    if (added == null || !mounted) return;
    _showMessage('${added.name} was added to the team.');
  }

  void _openTasks(Member member) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      builder: (_) => MemberTasksSheet(member: member),
    );
  }

  // The team must always keep one admin.
  bool _isLastAdmin(Member member) {
    if (member.role != MemberRole.admin) return false;

    final admins = context
        .read<AppState>()
        .members
        .where((m) => m.role == MemberRole.admin);
    return admins.length == 1;
  }

  void _changeRole(Member member) {
    if (_isLastAdmin(member)) {
      _showMessage('The team needs at least one admin.');
      return;
    }

    final newRole = member.role == MemberRole.admin
        ? MemberRole.member
        : MemberRole.admin;

    context.read<AppState>().updateMember(member.copyWith(role: newRole));
    _showMessage(
      newRole == MemberRole.admin
          ? '${member.name} is now an admin.'
          : '${member.name} is now a member.',
    );
  }

  Future<void> _removeMember(Member member) async {
    final appState = context.read<AppState>();

    if (member.id == appState.currentUser?.id) {
      _showMessage('You cannot remove yourself while signed in.');
      return;
    }
    if (appState.tasksFor(member.id).isNotEmpty) {
      _showMessage('Reassign ${member.name}\'s tasks before removing them.');
      return;
    }
    if (_isLastAdmin(member)) {
      _showMessage('The team needs at least one admin.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove member?'),
          content: Text('${member.name} will be removed from the team.'),
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
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final removed = await appState.removeMember(member.id);
    if (!removed || !mounted) return;
    _showMessage('${member.name} was removed from the team.');
  }

  // "2 open tasks · 1 overdue", shown on each member card.
  String _workloadSummary(AppState appState, Member member) {
    final tasks = appState.tasksFor(member.id);
    final open = tasks.where((task) => !task.isDone).length;
    final overdue = appState.slaCounts(subset: tasks)[SlaStatus.overdue]!;

    if (open == 0) return 'No open tasks';

    final openText = open == 1 ? '1 open task' : '$open open tasks';
    return overdue == 0 ? openText : '$openText · $overdue overdue';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final members = appState.members;
    final visibleMembers = _visibleMembers(members);

    final adminCount =
        members.where((member) => member.role == MemberRole.admin).length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        SprintlyHeader(
          title: 'Team Members',
          subtitle: 'Manage your team, assign tasks and collaborate on projects.',
          actions: [
            IconButton(
              onPressed: _toggleSearch,
              tooltip: _searching ? 'Close search' : 'Search members',
              icon: Icon(_searching ? Icons.close : Icons.search),
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _openAddMember,
              tooltip: 'Add member',
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.midnight,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (_searching) ...[
          TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search by name, role or email',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Filter tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              _filterTab(_MemberFilter.all, 'All', members.length),
              _filterTab(_MemberFilter.admins, 'Admins', adminCount),
              _filterTab(
                _MemberFilter.members,
                'Members',
                members.length - adminCount,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        if (visibleMembers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.group_off_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 12),
                Text(
                  'No members found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Try a different search or filter.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

        for (final member in visibleMembers)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MemberCard(
              member: member,
              workload: _workloadSummary(appState, member),
              onAction: (action) {
                switch (action) {
                  case _MemberAction.viewTasks:
                    _openTasks(member);
                  case _MemberAction.changeRole:
                    _changeRole(member);
                  case _MemberAction.remove:
                    _removeMember(member);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _filterTab(_MemberFilter filter, String label, int count) {
    final isSelected = _filter == filter;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _filter = filter;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$label  $count',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.workload,
    required this.onAction,
  });

  final Member member;
  final String workload;
  final ValueChanged<_MemberAction> onAction;

  @override
  Widget build(BuildContext context) {
    final isAdmin = member.role == MemberRole.admin;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 2, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MemberAvatar(member: member, radius: 26),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PresenceChip(presence: member.presence),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  isAdmin ? '${member.jobTitle} · Admin' : member.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        member.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  workload,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          PopupMenuButton<_MemberAction>(
            tooltip: 'Options for ${member.name}',
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: onAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _MemberAction.viewTasks,
                child: Text('View tasks'),
              ),
              PopupMenuItem(
                value: _MemberAction.changeRole,
                child: Text(isAdmin ? 'Make member' : 'Make admin'),
              ),
              const PopupMenuItem(
                value: _MemberAction.remove,
                child: Text('Remove from team'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
