import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/sla/sla_status.dart';
import '../../core/theme/app_colors.dart';
import '../../data/seed_data.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';
import '../../widgets/edit_field_dialog.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/sprintly_header.dart';
import '../../widgets/status_chip.dart';

// Form for changing or deleting an existing task.
class EditTaskScreen extends StatefulWidget {
  const EditTaskScreen({super.key, required this.task});

  final Task task;

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('d MMM yyyy');

  late final _titleController = TextEditingController(text: widget.task.title);
  late final _descriptionController = TextEditingController(
    text: widget.task.description,
  );
  late final _dueDateController = TextEditingController(
    text: _dateFormat.format(widget.task.dueDate),
  );

  // Values the form is editing, starting from the task being edited.
  String? _assigneeId;
  late DateTime _dueDate = widget.task.dueDate;
  late TaskPriority _priority = widget.task.priority;
  late TaskStatus _status = widget.task.status;
  String? _project;
  late List<String> _tags = [...widget.task.tags];

  @override
  void initState() {
    super.initState();

    // Left empty when the saved value is no longer one of the choices, so the
    // user picks again instead of the dropdown failing.
    final assignee = context.read<AppState>().memberById(
      widget.task.assigneeId,
    );
    _assigneeId = assignee?.id;
    _project = widget.task.project.isEmpty ? null : widget.task.project;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  // SLA status the task would have with the values currently on the form.
  SlaStatus get _previewSla {
    return classifySla(
      widget.task.copyWith(
        dueDate: _dueDate,
        priority: _priority,
        status: _status,
      ),
    );
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

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      // Past dates stay available so an overdue task can keep its date.
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
    );

    if (picked == null) return;

    setState(() {
      _dueDate = picked;
      _dueDateController.text = _dateFormat.format(picked);
    });
  }

  Future<void> _addTag() async {
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => EditFieldDialog(
        title: 'Add tag',
        initialValue: '',
        textCapitalization: TextCapitalization.none,
        validator: (value) {
          if (value.isEmpty) return 'Please enter a tag';
          if (value.length > 20) return 'A tag can be at most 20 characters';

          final exists = _tags.any(
            (tag) => tag.toLowerCase() == value.toLowerCase(),
          );
          if (exists) return 'This tag is already on the task';
          return null;
        },
      ),
    );

    if (tag == null) return;

    setState(() {
      _tags = [..._tags, tag];
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updated = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assigneeId: _assigneeId,
      dueDate: _dueDate,
      priority: _priority,
      status: _status,
      project: _project ?? '',
      tags: _tags,
    );

    await context.read<AppState>().updateTask(updated);

    if (!mounted) return;
    _showMessage('Task updated.');
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final appState = context.read<AppState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task?'),
          content: Text(
            '"${widget.task.title}" will be deleted. This cannot be undone.',
          ),
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
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await appState.deleteTask(widget.task.id);

    if (!mounted) return;
    _showMessage('Task deleted.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<AppState>().members;

    // Keeps a project that is not in the standard list selectable.
    final projectOptions = [
      ...projects,
      if (_project != null && !projects.contains(_project)) _project!,
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              SprintlyHeader(
                title: 'Edit Task',
                subtitle: 'Update the task details and make changes as needed.',
                onBack: () => Navigator.maybePop(context),
              ),

              const SizedBox(height: 20),

              // Live SLA preview
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'SLA status with these changes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SlaChip(status: _previewSla),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              _label('Task Title', required: true),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'What needs to be done?',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (value) {
                  final title = (value ?? '').trim();
                  if (title.isEmpty) return 'Please enter a task title';
                  if (title.length < 3) {
                    return 'Title must contain at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _label('Description', required: true),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe the task',
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              _label('Assign To', required: true),
              DropdownButtonFormField<String>(
                initialValue: _assigneeId,
                isExpanded: true,
                hint: const Text('Choose a team member'),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                items: [
                  for (final member in members)
                    DropdownMenuItem(
                      value: member.id,
                      child: Row(
                        children: [
                          MemberAvatar(member: member, radius: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              member.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _assigneeId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please choose an assignee' : null,
              ),

              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Due Date', required: true),
                        TextFormField(
                          controller: _dueDateController,
                          readOnly: true,
                          onTap: _pickDueDate,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Priority', required: true),
                        DropdownButtonFormField<TaskPriority>(
                          initialValue: _priority,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                          items: [
                            for (final priority in TaskPriority.values)
                              DropdownMenuItem(
                                value: priority,
                                child: Text(priority.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _priority = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _label('Status', required: true),
              DropdownButtonFormField<TaskStatus>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.format_list_bulleted),
                ),
                items: [
                  for (final status in TaskStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(status.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _status = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              _label('Related Project'),
              DropdownButtonFormField<String>(
                initialValue: _project,
                isExpanded: true,
                hint: const Text('Choose a project'),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
                items: [
                  for (final project in projectOptions)
                    DropdownMenuItem(
                      value: project,
                      child: Text(project),
                    ),
                ],
                onChanged: (value) {
                  setState(() {
                    _project = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              _label('Tags'),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(tag),
                      backgroundColor: AppColors.background,
                      side: BorderSide.none,
                      deleteButtonTooltipMessage: 'Remove $tag',
                      onDeleted: () {
                        setState(() {
                          _tags = _tags.where((t) => t != tag).toList();
                        });
                      },
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Add tag'),
                    backgroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: _addTag,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(
                        'Delete Task',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.overdue,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size(0, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      label: const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.overdue),
              ),
          ],
        ),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
