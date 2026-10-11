
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/task_model.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _members = [
    'Alex Carter',
    'Priya Sharma',
    'James Wilson',
  ];

  final List<String> _projects = [
    'Mobile App',
    'Backend',
    'UI/UX',
  ];

  String? _selectedAssignee;
  String? _selectedProject;

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;

  DateTime? _deadline;

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

    if (selected != null) {
      setState(() {
        _deadline = DateTime(
          selected.year,
          selected.month,
          selected.day,
          23,
          59,
          59,
        );
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _createTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a deadline'),
        ),
      );
      return;
    }

    final now = DateTime.now();

    final task = TaskModel(
      id: now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      assignee: _selectedAssignee!,
      project: _selectedProject!,
      priority: _priority,
      status: _status,
      deadline: _deadline!,
      createdAt: now,
    );

    // Return the task to the previous screen.
    Navigator.pop(context, task);
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

  Widget _buildPriorityOption(
    TaskPriority priority,
    String label,
  ) {
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
              color: selected
                  ? AppColors.softGreen
                  : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.onTrack
                    : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
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
    return Scaffold(
      backgroundColor: AppColors.white,

      appBar: AppBar(
        title: const Text(
          'Create Task',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
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
                      textCapitalization:
                          TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      decoration: const InputDecoration(
                        hintText: 'Enter task name',
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
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
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _sectionLabel('Assign to *'),

                    DropdownButtonFormField<String>(
                      initialValue: _selectedAssignee,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select team member',
                        prefixIcon:
                            Icon(Icons.person_outline),
                      ),
                      items: _members.map((member) {
                        return DropdownMenuItem(
                          value: member,
                          child: Text(member),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedAssignee = value;
                        });
                      },
                      validator: (value) {
                        return value == null
                            ? 'Select an assignee'
                            : null;
                      },
                    ),

                    const SizedBox(height: 24),

                    _sectionLabel('Deadline *'),

                    FormField<DateTime>(
                      validator: (_) {
                        return _deadline == null
                            ? 'Select a deadline'
                            : null;
                      },
                      builder: (field) {
                        return Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () async {
                                await _selectDeadline();
                                field.didChange(_deadline);
                              },
                              borderRadius:
                                  BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: field.hasError
                                        ? AppColors.overdue
                                        : AppColors.border,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(14),
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
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                    ),
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
                                    color: Theme.of(context)
                                        .colorScheme.error,
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
                        _buildPriorityOption(
                          TaskPriority.low,
                          'Low',
                        ),
                        _buildPriorityOption(
                          TaskPriority.medium,
                          'Medium',
                        ),
                        _buildPriorityOption(
                          TaskPriority.high,
                          'High',
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    _sectionLabel('Task status'),

                    DropdownButtonFormField<TaskStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        prefixIcon:
                            Icon(Icons.pending_actions_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TaskStatus.todo,
                          child: Text('To Do'),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.inProgress,
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: TaskStatus.done,
                          child: Text('Done'),
                        ),
                      ],
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
                        prefixIcon:
                            Icon(Icons.folder_outlined),
                      ),
                      items: _projects.map((project) {
                        return DropdownMenuItem(
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
                        return value == null
                            ? 'Select a project'
                            : null;
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Fixed bottom action
              Container(
                padding: const EdgeInsets.fromLTRB(
                  24, 12, 24, 16,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Create Task',
                      style: TextStyle(
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
