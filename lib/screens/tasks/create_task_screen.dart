import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/task.dart';
import '../../state/app_state.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedAssigneeId;
  String? _selectedProject;

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  DateTime? _deadline;
  bool _isSaving = false;

  static const List<String> _projects = ['Mobile App', 'Backend', 'UI/UX'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline ?? today,
      firstDate: today,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.midnight,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _deadline = selected;
    });
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _createTask() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a deadline')));
      return;
    }

    final state = context.read<AppState>();

    if (_selectedAssigneeId == null ||
        state.memberById(_selectedAssigneeId!) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid team member')),
      );
      return;
    }

    if (_selectedProject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final task = Task(
      id: state.newId(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assigneeId: _selectedAssigneeId!,
      dueDate: _deadline!,
      priority: _priority,
      status: _status,
      project: _selectedProject!,
      createdAt: DateTime.now(),
    );

    try {
      await state.addTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: AppColors.midnight,
        ),
      );

      // Return the newly created task to the previous screen.
      Navigator.of(context).pop(task);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save task. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _priorityOption(TaskPriority priority, String label) {
    final selected = _priority == priority;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          onTap: () {
            setState(() {
              _priority = priority;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.softGreen : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? AppColors.onTrack : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = context.watch<AppState>().members;

    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        title: const Text(
          'Create Task',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSaving ? null : () => Navigator.maybePop(context),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  children: [
                    const Text(
                      'New task',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Keep your team moving forward.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _sectionLabel('Task name *'),

                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        hintText: 'Enter task name',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Task name is required';
                        }

                        if (value.trim().length < 3) {
                          return 'Enter at least 3 characters';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _sectionLabel('Description'),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Describe the task...',
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionLabel('Assign to *'),

                    DropdownButtonFormField<String>(
                      key: const ValueKey('task_assignee'),
                      isExpanded: true,
                      initialValue: _selectedAssigneeId,
                      decoration: const InputDecoration(
                        hintText: 'Select team member',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: members.map((member) {
                        return DropdownMenuItem<String>(
                          value: member.id,
                          child: Text(
                            member.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAssigneeId = value;
                        });
                      },
                      validator: (value) {
                        return value == null ? 'Select an assignee' : null;
                      },
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel('Deadline *'),

                    FormField<DateTime>(
                      validator: (_) =>
                          _deadline == null ? 'Select a deadline' : null,
                      builder: (field) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () async {
                                await _selectDeadline();
                                field.didChange(_deadline);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: field.hasError
                                        ? AppColors.overdue
                                        : AppColors.border,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _deadline == null
                                            ? 'Select due date'
                                            : _formatDate(_deadline!),
                                        style: TextStyle(
                                          color: _deadline == null
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down),
                                  ],
                                ),
                              ),
                            ),
                            if (field.hasError)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  left: 12,
                                ),
                                child: Text(
                                  field.errorText!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel('Priority'),

                    Row(
                      children: [
                        _priorityOption(TaskPriority.low, 'Low'),
                        _priorityOption(TaskPriority.medium, 'Medium'),
                        _priorityOption(TaskPriority.high, 'High'),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel('Task status'),

                    DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pending_actions_outlined),
                      ),
                      items: TaskStatus.values.map((status) {
                        return DropdownMenuItem<TaskStatus>(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel('Project *'),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedProject,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select project',
                        prefixIcon: Icon(Icons.folder_outlined),
                      ),
                      items: _projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project,
                          child: Text(project),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProject = value;
                        });
                      },
                      validator: (value) {
                        return value == null ? 'Select a project' : null;
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Fixed bottom action button
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _createTask,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isSaving ? 'Creating...' : 'Create Task',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
}
