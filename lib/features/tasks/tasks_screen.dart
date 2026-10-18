import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/task.dart';
import 'presentation/task_list_provider.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Functional task management screen.
///
/// Displays the user's tasks with create, complete, and delete
/// interactions. Backed by [taskListProvider] for reactive state.
class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        tooltip: 'Create task',
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(taskListProvider)),
        data: (tasks) => tasks.isEmpty
            ? const WtEmptyState(
                icon: Icons.checklist_rounded,
                title: 'No tasks yet',
                message: 'Tap the + button to create your first task.',
              )
            : _TaskList(tasks: tasks),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Task'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Task title',
                  errorText: errorText,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (controller.text.trim().isEmpty) {
                    setState(() => errorText = 'Title cannot be empty.');
                  } else {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setState(() => errorText = 'Title cannot be empty.');
                    } else {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        await ref.read(taskListProvider.notifier).createTask(controller.text);
      } on ArgumentError {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid task title.')));
        }
      }
    }

    // Dispose after the dialog exit animation completes to avoid
    // "TextEditingController used after being disposed" errors.
    Future.delayed(const Duration(milliseconds: 300), controller.dispose);
  }
}

/// Scrollable list of task items.
class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});

  final List<Task> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskListItem(task: task);
      },
    );
  }
}

/// A single task row with completion toggle and delete action.
class _TaskListItem extends ConsumerWidget {
  const _TaskListItem({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return ListTile(
      key: ValueKey(task.id),
      leading: Checkbox(
        value: isCompleted,
        onChanged: (_) =>
            ref.read(taskListProvider.notifier).toggleTask(task.id),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: isCompleted ? TextDecoration.lineThrough : null,
          color: isCompleted
              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
              : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Delete task',
        onPressed: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(taskListProvider.notifier).deleteTask(task.id);
    }
  }
}

/// Error state with a retry action.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('Could not load tasks.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
