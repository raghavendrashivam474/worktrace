import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/task.dart';
import 'presentation/task_list_provider.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Completion filter for the task list.
enum TaskFilter { all, active, completed }

/// Sort order for the task list.
enum TaskSort { newestFirst, oldestFirst, titleAZ }

/// Functional task management screen.
///
/// Displays the user's tasks with create, edit, complete, delete,
/// search, filter, and sort interactions. Backed by [taskListProvider].
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.newestFirst;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        tooltip: 'Create task',
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(taskListProvider)),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const WtEmptyState(
              icon: Icons.checklist_rounded,
              title: 'No tasks yet',
              message: 'Tap the + button to create your first task.',
            );
          }

          final query = _searchController.text.trim().toLowerCase();
          final filtered = _applyFilter(tasks, query);
          final sorted = _applySort(filtered);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Filter + Sort row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<TaskFilter>(
                        segments: const [
                          ButtonSegment(
                            value: TaskFilter.all,
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: TaskFilter.active,
                            label: Text('Active'),
                          ),
                          ButtonSegment(
                            value: TaskFilter.completed,
                            label: Text('Done'),
                          ),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (s) =>
                            setState(() => _filter = s.first),
                        showSelectedIcon: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<TaskSort>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort tasks',
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: TaskSort.newestFirst,
                          child: Text('Newest first'),
                        ),
                        PopupMenuItem(
                          value: TaskSort.oldestFirst,
                          child: Text('Oldest first'),
                        ),
                        PopupMenuItem(
                          value: TaskSort.titleAZ,
                          child: Text('Title A-Z'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Task list or no-match state
              Expanded(
                child: sorted.isEmpty
                    ? const WtEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching tasks',
                        message: 'Try adjusting your search or filters.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final task = sorted[index];
                          return _TaskListItem(
                            task: task,
                            onEdit: () => _showEditDialog(context, task),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Filtering & Sorting ──────────────────────────────────────────────

  List<Task> _applyFilter(List<Task> tasks, String query) {
    var result = tasks;
    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        break;
    }
    if (query.isNotEmpty) {
      result = result
          .where((t) => t.title.toLowerCase().contains(query))
          .toList();
    }
    return result;
  }

  List<Task> _applySort(List<Task> tasks) {
    final sorted = List<Task>.of(tasks);
    switch (_sort) {
      case TaskSort.newestFirst:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskSort.titleAZ:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return sorted;
  }

  // ── Create Dialog ────────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) =>
          const _TaskFormDialog(title: 'New Task', actionLabel: 'Create'),
    );

    if (title != null && context.mounted) {
      try {
        await ref.read(taskListProvider.notifier).createTask(title);
      } on ArgumentError {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid task title.')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create task.')),
          );
        }
      }
    }
  }

  // ── Edit Dialog ──────────────────────────────────────────────────────

  Future<void> _showEditDialog(BuildContext context, Task task) async {
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => _TaskFormDialog(
        title: 'Edit Task',
        actionLabel: 'Save',
        initialText: task.title,
      ),
    );

    if (newTitle != null && context.mounted) {
      try {
        await ref.read(taskListProvider.notifier).editTask(task.id, newTitle);
      } on ArgumentError {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Invalid task title.')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update task.')),
          );
        }
      }
    }
  }
}

// ── Reusable Task Form Dialog ──────────────────────────────────────────

/// Self-contained form dialog for creating or editing tasks.
///
/// Manages its own [TextEditingController] lifecycle natively inside State,
/// eliminating delayed disposal workarounds (S1.5 lifecycle hardening).
class _TaskFormDialog extends StatefulWidget {
  const _TaskFormDialog({
    required this.title,
    required this.actionLabel,
    this.initialText = '',
  });

  final String title;
  final String actionLabel;
  final String initialText;

  @override
  State<_TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<_TaskFormDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = 'Title cannot be empty.');
    } else {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Task title',
          errorText: _errorText,
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }
}

// ── Task List Item ─────────────────────────────────────────────────────

/// A single task row with completion toggle, edit, and delete actions.
class _TaskListItem extends ConsumerWidget {
  const _TaskListItem({required this.task, required this.onEdit});

  final Task task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = task.isCompleted;

    return ListTile(
      key: ValueKey(task.id),
      leading: Checkbox(
        value: isCompleted,
        onChanged: (_) async {
          try {
            await ref.read(taskListProvider.notifier).toggleTask(task.id);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update task state.')),
              );
            }
          }
        },
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit task',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
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
      try {
        await ref.read(taskListProvider.notifier).deleteTask(task.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete task.')),
          );
        }
      }
    }
  }
}

// ── Error State ────────────────────────────────────────────────────────

/// Error state with a retry action.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text('Could not load tasks.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
