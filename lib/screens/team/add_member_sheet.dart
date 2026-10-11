import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/member.dart';
import '../../state/app_state.dart';

// Bottom sheet with the form for adding a team member.
// Closes with the new Member when it is saved.
class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key});

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _teamController = TextEditingController();

  MemberRole _role = MemberRole.member;

  @override
  void dispose() {
    _nameController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _validateName(String? value) {
    final missing = _required(value, 'Please enter a name');
    if (missing != null) return missing;

    if (value!.trim().length < 2) {
      return 'Name must contain at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final missing = _required(value, 'Please enter an email');
    if (missing != null) return missing;

    final email = value!.trim().toLowerCase();
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Two members cannot share an email.
    final taken = context
        .read<AppState>()
        .members
        .any((member) => member.email.toLowerCase() == email);

    if (taken) return 'A member with this email already exists';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appState = context.read<AppState>();

    final member = Member(
      id: appState.newId(),
      name: _nameController.text.trim(),
      jobTitle: _jobTitleController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      team: _teamController.text.trim(),
      role: _role,
      joinedAt: DateTime.now(),
    );

    await appState.addMember(member);

    if (!mounted) return;
    Navigator.pop(context, member);
  }

  @override
  Widget build(BuildContext context) {
    // Lifts the form above the keyboard.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardHeight),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add team member',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 20),

              _label('Full name'),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Jordan Blake',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _validateName,
              ),

              const SizedBox(height: 16),

              _label('Job title'),
              TextFormField(
                controller: _jobTitleController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Frontend Developer',
                  prefixIcon: Icon(Icons.work_outline),
                ),
                validator: (value) =>
                    _required(value, 'Please enter a job title'),
              ),

              const SizedBox(height: 16),

              _label('Work email'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: 'name@sprintly.app',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _validateEmail,
              ),

              const SizedBox(height: 16),

              _label('Team'),
              TextFormField(
                controller: _teamController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  hintText: 'e.g. Engineering',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (value) => _required(value, 'Please enter a team'),
              ),

              const SizedBox(height: 16),

              _label('Access'),
              DropdownButtonFormField<MemberRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.shield_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MemberRole.member,
                    child: Text('Member'),
                  ),
                  DropdownMenuItem(
                    value: MemberRole.admin,
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _role = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text(
                    'Add member',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
