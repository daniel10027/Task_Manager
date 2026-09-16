import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../theme/app_spacing.dart';

class TaskFormResult {
  final String title;
  final String description;
  final TaskStatus status;

  const TaskFormResult({
    required this.title,
    required this.description,
    required this.status,
  });
}

/// Modal bottom sheet, rounded top corners, used for both creating and
/// editing a task. Pass [task] to edit, or leave null to create.
Future<TaskFormResult?> showTaskFormSheet(BuildContext context, {Task? task}) {
  return showModalBottomSheet<TaskFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskFormSheet(task: task),
  );
}

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskStatus _status;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _status = widget.task?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TaskFormResult(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('task_form_title_field'),
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty || v.length > 200) {
                      return 'Le titre doit contenir entre 1 et 200 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('task_form_description_field'),
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Statut',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<TaskStatus>(
                  key: const Key('task_form_status_selector'),
                  segments: const [
                    ButtonSegment(
                      value: TaskStatus.todo,
                      label: Text('À faire'),
                    ),
                    ButtonSegment(
                      value: TaskStatus.inProgress,
                      label: Text('En cours'),
                    ),
                    ButtonSegment(
                      value: TaskStatus.done,
                      label: Text('Terminé'),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (selection) =>
                      setState(() => _status = selection.first),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        key: const Key('task_form_save_button'),
                        onPressed: _save,
                        child: const Text('Enregistrer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
